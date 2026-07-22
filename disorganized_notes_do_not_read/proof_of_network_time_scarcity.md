**Proof-of-Latency-Web (PoLW)**

$$
\begin{aligned}
&\textbf{1. Metric constraint: } \forall i,j,k:\; |R_{ik} - R_{jk}| \le R_{ij} \le R_{ik} + R_{jk} \\
&\textbf{2. Leader election: } h^* = \arg\min_h H(r\,\|\,pk_h\,\|\,\mathrm{median}_j\{R_{hj}\}) \\
&\textbf{3. Sybil bound: } \mathrm{rank}(R_S)\le m \Rightarrow \text{Cost} = \Omega(\text{ASNs})
\end{aligned}
$$

**Translation:** Ping times must obey triangle inequality. A Sybil with $m$ real boxes can only satisfy $O(m^2)$ constraints. To fake $n$ peers you need $\Omega(n)$ boxes globally. Cost = infrastructure, not hash.
