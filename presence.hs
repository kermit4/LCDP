#!/usr/bin/env stack
{- stack script
   --resolver lts-23.0
   --package network
   --package aeson
   --package random
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
import Data.Aeson
import Data.Aeson.Key            (fromText)
import qualified Data.Aeson.KeyMap   as KM
import qualified Data.ByteString.Lazy as BL
import Data.IORef
import Data.Map.Strict           (Map)
import qualified Data.Map.Strict as Map
import Data.Maybe                (fromMaybe)
import Data.Set                  (Set)
import qualified Data.Set        as Set
import Data.Text                 (Text)
import qualified Data.Text       as T
import Data.Time.Clock.POSIX     (getPOSIXTime)
import Data.Word                 (Word32)
import Network.Socket            hiding (recvFrom, sendTo)
import Network.Socket.ByteString (recvFrom, sendTo)
import Numeric                   (showHex)
import System.Environment        (getArgs, lookupEnv)
import System.IO                 (BufferMode (..), hSetBuffering, stdout)
import System.Random             (randomIO)
import System.Timeout            (timeout)

bootstrap :: [String]
bootstrap = ["148.71.89.128:24254", "159.69.54.127:24254"]

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
    w <- randomIO :: IO Word32
    let token = showHex w ""

    forM_ bootstrap $ \peer ->
        sendStr sock peer
            [ kv "PleaseSendPeers" (Object KM.empty)
            , kv "PleaseAlwaysReturnThisMessage" (toJSON token)
            ]

    _ <- forkIO $ forever $ do
        threadDelay 5000000
        now   <- round <$> getPOSIXTime :: IO Integer
        peers <- readIORef peersRef
        forM_ (Set.toList peers) $ \peer ->
            sendStr sock peer
                [ kv "IAmHere" $ object ["name" .= name, "t" .= now]
                , kv "PleaseAlwaysReturnThisMessage" (toJSON token)
                ]

    _ <- forkIO $ forever $ do
        threadDelay 10000000
        now   <- round <$> getPOSIXTime :: IO Integer
        board <- readIORef presenceRef
        putStrLn $ "\n--- Who is here (" ++ name ++ ") ---"
        forM_ (Map.toAscList board) $ \(n, (t, addr)) ->
            putStrLn $ "  " ++ n ++ "  " ++ addr ++ "  " ++ show (now - t) ++ "s ago"

    let recvLoop = do
            res <- timeout 1000000 (recvFrom sock 65535)
            case res of
                Nothing -> pure ()
                Just (bs, srcAddr) -> do
                    let src = sockAddrStr srcAddr
                    modifyIORef' peersRef (Set.insert src)
                    now <- round <$> getPOSIXTime :: IO Integer
                    case decode (BL.fromStrict bs) :: Maybe [Value] of
                        Nothing   -> pure ()
                        Just msgs -> do
                            outRef <- newIORef ([] :: [Value])
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
                                            modifyIORef' outRef
                                                (kv "Peers" (object ["peers" .= pl]) :)
                                        Nothing -> pure ()
                                    case get "PleaseAlwaysReturnThisMessage" km of
                                        Just tok -> do
                                            out <- readIORef outRef
                                            when (not $ null out) $
                                                modifyIORef' outRef (kv "AlwaysReturned" tok :)
                                        Nothing -> pure ()
                                _ -> pure ()
                            out <- readIORef outRef
                            when (not $ null out) $
                                sendPkt sock srcAddr (reverse out)
            recvLoop
    recvLoop
