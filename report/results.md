# Results

Collected results for all parts, for use in `report.pdf`. Sources are listed under each section.

## Part A: RTL design and verification

| Check | Result |
|---|---|
| RTL simulation | `PASS: 256 vectors checked, 0 errors` |
| Error test (`sum = a ^ b` in `full_adder.v`) | `FAIL: 256 vectors checked, 95 errors` |

Hand-worked example (A = last digit of a roll number + 5, B = 7). Choose one:

| Roll number | Last digit | A | B | A × B |
|---|---|---|---|---|
| 2024112008 (Allu Joanna Preetika) | 8 | 13 (1101) | 7 (0111) | 91 (01011011) |
| 2024102055 (Sindhuja Babu) | 5 | 10 (1010) | 7 (0111) | 70 (01000110) |

Still to do: waveform screenshot with latency marked, hand-worked example, block diagram.

## Part B: Logic synthesis

Source: `synth/mult_array_stat.rpt`.

| Metric | Value |
|---|---|
| Total number of cells | 68 |
| Number of flip-flops | 16 (`sky130_fd_sc_hd__dfrtp_1`) |
| Total cell area (µm²) | 785.754 |
| Flip-flop area (µm²) | 16 × 25.024 = 400.384 |
| Flip-flop area (% of total) | 50.96 % |
| The 3 most-used cell types and their counts | `dfrtp_1` × 16, `nand2_1` × 8, `and2_0` × 6 and `xnor2_1` × 6 (tied) |
| Netlist simulation result | `PASS: 256 vectors checked, 0 errors` |

Logic cells (total minus flip-flops): 68 − 16 = 52.

## Part C: Static timing analysis

Source: `sta/sta.tcl`, `sta/mult_array_timing.rpt` (T = 2.98 ns run). Typical corner `tt_025C_1v80`.

| Metric | Value |
|---|---|
| Worst slack at T = 10 ns (ns) | 7.027 |
| T_min (ns) | 10 − 7.027 = 2.973, rounded up to 2.98 |
| F_max (MHz) | 1000 / 2.98 = 335.6 |
| Slack at T = T_min (ns) | 0.007 |
| Critical path start point | `_108_` (`dfrtp_1`, input register `b_r[0]`) |
| Critical path end point | `_103_` (`dfrtp_1`, output register `p[7]`, captures final carry `c3[4]`) |
| Number of cells on the critical path | 9 (including the launching flip-flop) |
| Latency (ns) = 2 × T_min | 5.96 |
| Throughput (million results per second) | 335.6 |

T_min is rounded up rather than to the nearest 0.01 ns (2.97) so that the slack stays non-negative.

Critical path cells, in order:

| # | Cell | Delay (ns) | Arrival (ns) |
|---|---|---|---|
| 1 | `_108_` `dfrtp_1` (CLK → Q) | 0.410 | 0.410 |
| 2 | `_050_` `and4_1` | 0.223 | 0.634 |
| 3 | `_061_` `o21ai_0` | 0.195 | 0.828 |
| 4 | `_062_` `nand3_1` | 0.140 | 0.969 |
| 5 | `_063_` `maj3_1` | 0.380 | 1.349 |
| 6 | `_069_` `xnor3_1` | 0.393 | 1.741 |
| 7 | `_074_` `maj3_1` | 0.369 | 2.110 |
| 8 | `_086_` `maj3_1` | 0.383 | 2.493 |
| 9 | `_087_` `maj3_1` | 0.349 | 2.842 |

Endpoint `_103_/D` arrival 2.842 ns, setup time 0.131 ns, required 2.849 ns.

Full-adder cells on the path: 4 `maj3` (carry) + 1 `xnor3` (sum) = 5, against the estimate of about 2N = 8 full-adder delays. The `and4`, `o21ai` and `nand3` cells are partial-product AND logic that synthesis merged with the first adder stages.

## Part D: Physical design

Source: `pnr/metrics.json` from `runs/RUN_2026-10-23_19-19-43` (attempt 5). Attempt log is in `README.md`.

| Metric | Value |
|---|---|
| CLOCK_PERIOD used (ns) | 6.0 |
| Number of runs needed | 5 |
| Core area (µm²) | 17,759.5 (die area 22,500) |
| Cells after synthesis (from Part B) | 68 |
| Cells after place and route | 1,891 |
| Kinds of cells added | decap, fill, tap, timing-repair buffers, clock buffers |
| Wirelength (µm) | 2,407 (routed) |
| Setup slack (ns) | 0.044 (worst corner, ss_100C_1v60) |
| Post-route F_max (MHz) | 1000 / (6.0 − 0.044) = 167.9 |
| F_max from Part C (MHz) | 335.6 |
| DRC errors | 0 (Magic, KLayout and router) |
| LVS errors | 0 |

Other values: hold slack 0.139 ns (worst corner); setup slack at the typical corner 2.914 ns; standard-cell utilisation 7.3 %.

Added cells (1,891 − 68 = 1,823). Decap/fill split counted from `final/def/mult_array.def`; `metrics.json` reports them together as `fill_cell` = 1,552.

| Kind | Cells | Count | Purpose |
|---|---|---|---|
| Decap | `decap_3/4/6/8/12` | 1,300 | Capacitance between power and ground to smooth supply noise |
| Fill | `fill_1`, `fill_2` | 252 | Fill row gaps so wells and power rails stay continuous |
| Tap | `tapvpwrvgnd_1` | 245 | Tie N-well and substrate to power and ground, preventing latch-up |
| Timing-repair buffers | `buf_2` × 17, `buf_4` × 4, `clkdlybuf4s50_1` × 2 | 23 | Drive weak or long nets to meet setup and slew limits |
| Clock tree buffers | `clkbuf_16` | 3 | Clock tree synthesis: balance clock arrival at the 16 flip-flops |

LibreLane runs its own synthesis, so the logic cells in the layout differ from the Part B netlist (for example 12 `nand2_1` instead of 8), even though the logic count is again 68.

KLayout screenshots (in `report/`):

| File | Use |
|---|---|
| `full_layout_top_level.png` | Whole die (report figure) |
| `zoomed_layout_full_hierarchy.png` | Zoomed view of cell rows and metal wires (report figure) |
| `full_layout_full_hierarchy.png` | Whole die with all cell contents (optional, appendix) |
| `zoomed_layout_top_level.png` | Zoomed routing with cell names visible (optional, supports question 4) |
