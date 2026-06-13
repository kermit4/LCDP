#!/usr/bin/env stack
{- stack script
   --resolver lts-23.0
   --package network
   --package aeson
   --package cryptonite
   --package memory
   --package time
   --package containers
   --package bytestring
   --package text
-}
{-# LANGUAGE LambdaCase        #-}
{-# LANGUAGE OverloadedStrings #-}
module Main where

import Control.Concurrent        (forkIO, threadDelay)
import Control.Monad             (forM_, forever, when)
import Crypto.Hash               (SHA256)
import Crypto.MAC.HMAC           (HMAC, hmac)
import Crypto.Random             (getRandomBytes)
import Data.Aeson
import Data.Aeson.Key            (fromText)
import qualified Data.Aeson.KeyMap   as KM
import qualified Data.ByteString     as BS
import qualified Data.ByteString.Lazy as BL
import Data.ByteArray.Encoding  (convertToBase, Base(Base16))
import Data.IORef
import Data.Map.Strict           (Map)
import qualified Data.Map.Strict as Map
import Data.Maybe                (fromMaybe)
import Data.Set                  (Set)
import qualified Data.Set        as Set
import Data.Text                 (Text)
import qualified Data.Text       as T
import qualified Data.Text.Encoding as TE
import Data.Time.Clock.POSIX     (getPOSIXTime)
import Network.Socket            hiding (recvFrom, sendTo)
import Network.Socket.ByteString (recvFrom, sendTo)
import System.Environment        (getArgs, lookupEnv)
import System.IO                 (BufferMode (..), hSetBuffering, stdout)

bootstrap :: [String]
bootstrap = ["148.71.89.128:24254", "159.69.54.127:24254"]

ipUdpHeader :: Int
ipUdpHeader = 28

splitLast :: String -> (String, String)
splitLast s = (reverse hostR, reverse portR)
  where (portR, _:hostR) = break (== ':') (reverse s)

resolveUDP :: String -> IO SockAddr
resolveUDP s = do
    let (host, port) = splitLast s
    infos <- getAddrInfo
        (Just defaultHints { addrSocketType = Datagram, addrFamily = AF_INET })
        (Just host) (Just port)
    return $ addrAddress (head infos)

sockAddrStr :: SockAddr -> String
sockAddrStr (SockAddrInet p h) =
    let (a, b, c, d) = hostAddressToTuple h
    in show a ++ "." ++ show b ++ "." ++ show c ++ "." ++ show d
       ++ ":" ++ show (fromIntegral p :: Int)
sockAddrStr a = show a

sendPkt :: Socket -> SockAddr -> [Value] -> IO ()
sendPkt sock addr msgs =
    sendTo sock (BL.toStrict $ encode msgs) addr >> return ()

sendStr :: Socket -> String -> [Value] -> IO ()
sendStr sock s msgs = resolveUDP s >>= \addr -> sendPkt sock addr msgs

kv :: Text -> Value -> Value
kv k v = Object $ KM.fromList [(fromText k, v)]

get :: Text -> KM.KeyMap Value -> Maybe Value
get k = KM.lookup (fromText k)

-- HMAC-derived token: no per-peer state to store.
-- See README: "You could use a hash of their address and a secret."
tokenFor :: BS.ByteString -> String -> Text
tokenFor secret addr =
    T.take 32 $ TE.decodeUtf8 $
    convertToBase Base16
        (hmac secret (TE.encodeUtf8 (T.pack addr)) :: HMAC SHA256)

main :: IO ()
main = do
    hSetBuffering stdout LineBuffering
    args <- getArgs
    name <- case args of
        (n:_) -> return n
        []    -> fromMaybe "anon" <$> lookupEnv "NAME"

    sock <- socket AF_INET Datagram defaultProtocol
    setSocketOption sock ReuseAddr 1
    bind sock (SockAddrInet 24254 0)

    peersRef    <- newIORef (Set.fromList bootstrap)
    presenceRef <- newIORef (Map.empty :: Map String (Integer, String))
    secret      <- getRandomBytes 32 :: IO BS.ByteString

    let tok = tokenFor secret

    forM_ bootstrap $ \peer ->
        sendStr sock peer
            [ kv "PleaseSendPeers" (Object KM.empty)
            , kv "PleaseAlwaysReturnThisMessage" (object ["cookie" .= tok peer])
            ]

    _ <- forkIO $ forever $ do
        threadDelay 5000000
        now   <- round <$> getPOSIXTime :: IO Integer
        peers <- readIORef peersRef
        forM_ (Set.toList peers) $ \peer ->
            sendStr sock peer
                [ kv "IAmHere" $ object ["name" .= name, "t" .= now]
                , kv "PleaseAlwaysReturnThisMessage" (object ["cookie" .= tok peer])
                ]

    _ <- forkIO $ forever $ do
        threadDelay 10000000
        now   <- round <$> getPOSIXTime :: IO Integer
        board <- readIORef presenceRef
        putStrLn $ "\n--- Who is here (" ++ name ++ ") ---"
        forM_ (Map.toAscList board) $ \(n, (t, addr)) ->
            putStrLn $ "  " ++ n ++ "  " ++ addr ++ "  " ++ show (now - t) ++ "s ago"

    let recvLoop = do
            (bs, srcAddr) <- recvFrom sock 65535
            let src      = sockAddrStr srcAddr
                reqBytes = BS.length bs + ipUdpHeader
            modifyIORef' peersRef (Set.insert src)
            now <- round <$> getPOSIXTime :: IO Integer
            case decode (BL.fromStrict bs) :: Maybe [Value] of
                Nothing   -> recvLoop
                Just msgs -> do
                    -- Verified if this packet echoes the HMAC token for this address.
                    let isVerified = any
                          (\case Object km | Just (Object ar) <- get "AlwaysReturned" km
                                           -> get "cookie" ar == Just (toJSON (tok src))
                                 _         -> False)
                          msgs

                    outRef      <- newIORef ([] :: [Value])
                    theirTokRef <- newIORef (Nothing :: Maybe Value)
                    peersListRef <- newIORef ([] :: [Text])

                    forM_ msgs $ \case
                        Object km -> do
                            case get "Peers" km of
                                Just (Object p) | Just (Array ps) <- get "peers" p ->
                                    forM_ ps $ \case
                                        String s -> modifyIORef' peersRef (Set.insert (T.unpack s))
                                        _        -> pure ()
                                _ -> pure ()
                            case get "IAmHere" km of
                                Just (Object iah)
                                    | Just (String n) <- get "name" iah
                                    , Just (Number t) <- get "t"    iah ->
                                    modifyIORef' presenceRef
                                        (Map.insert (T.unpack n) (round t, src))
                                _ -> pure ()
                            case get "HereIsWho" km of
                                Just (Object hiw) | Just (Array ns) <- get "nodes" hiw ->
                                    forM_ ns $ \case
                                        Object nm
                                            | Just (String n) <- get "name" nm
                                            , Just (Number t) <- get "t"    nm ->
                                            let a = case get "addr" nm of
                                                        Just (String s) -> T.unpack s
                                                        _               -> src
                                            in modifyIORef' presenceRef
                                                (Map.insert (T.unpack n) (round t, a))
                                        _ -> pure ()
                                _ -> pure ()
                            case get "WhoIsHere" km of
                                Just _ -> do
                                    let cutoff = now - 60
                                    board <- readIORef presenceRef
                                    let nodes = [ object ["name" .= n, "t" .= t, "addr" .= a]
                                                | (n, (t, a)) <- Map.toList board, t >= cutoff ]
                                    modifyIORef' outRef
                                        (kv "HereIsWho" (object ["nodes" .= nodes]) :)
                                Nothing -> pure ()
                            case get "PleaseSendPeers" km of
                                Just _ -> do
                                    peers <- readIORef peersRef
                                    let pl = take 20 (Set.toList peers)
                                    writeIORef peersListRef pl
                                    modifyIORef' outRef
                                        (kv "Peers" (object ["peers" .= pl]) :)
                                Nothing -> pure ()
                            case get "PleaseAlwaysReturnThisMessage" km of
                                Just t  -> writeIORef theirTokRef (Just t)
                                Nothing -> pure ()
                        _ -> pure ()

                    out      <- readIORef outRef
                    theirTok <- readIORef theirTokRef
                    peersList <- readIORef peersListRef

                    when (not $ null out) $ do
                        let withEcho = case theirTok of
                                Just t  -> kv "AlwaysReturned" t : out
                                Nothing -> out
                            -- Include our token in every reply so an unverified peer can
                            -- echo it back and receive full responses next exchange.
                            full = reverse (kv "PleaseAlwaysReturnThisMessage"
                                               (object ["cookie" .= tok src]) : withEcho)
                        finalOut <-
                            if isVerified then return full
                            else do
                                let payload = BL.toStrict $ encode full
                                if BS.length payload > floor (fromIntegral reqBytes * (2.5 :: Double))
                                    then do
                                        -- Minimum: our token + at most 1 peer.
                                        -- AlwaysReturned is dropped — unverified peers need
                                        -- our token to bootstrap, not proof that we are real.
                                        let onePeer = case peersList of
                                                (p:_) -> [kv "Peers" (object ["peers" .= [p]])]
                                                []    -> []
                                        return $ kv "PleaseAlwaysReturnThisMessage"
                                                     (object ["cookie" .= tok src]) : onePeer
                                    else return full
                        sendPkt sock srcAddr finalOut
            recvLoop
    recvLoop
