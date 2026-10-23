# 4-bit Array Multiplier: RTL to GDSII (SKY130)

## Team

| Name | Roll number |
|---|---|
| Allu Joanna Preetika | 2024112008 |
| Sindhuja Babu | 2024102055 |

All commands are run from the repository root inside the IIC-OSIC-TOOLS container, unless noted.

Temporarily made a "results.md" file to store results before making the final report pdf.

## Setup

```sh
iverilog -V | head -1
yosys -V
sta -version
echo $PDK_ROOT $PDK
```

## Part A: RTL simulation

```sh
iverilog -g2012 -o sim tb/tb_mult.v rtl/full_adder.v rtl/mult_array.v
vvp sim
gtkwave mult.vcd
```

Result: `PASS: 256 vectors checked, 0 errors`

Error test (`sum` in `rtl/full_adder.v` temporarily changed to `a ^ b`, then reverted):

```sh
iverilog -g2012 -o sim tb/tb_mult.v rtl/full_adder.v rtl/mult_array.v
vvp sim
```

Result: `FAIL: 256 vectors checked, 95 errors`

## Part B: Synthesis

```sh
yosys -c synth/synth.tcl
```

Gate-level simulation:

```sh
CELLS=$PDK_ROOT/sky130A/libs.ref/sky130_fd_sc_hd/verilog
iverilog -g2012 -DFUNCTIONAL -DUNIT_DELAY=#1 -o gls \
  tb/tb_mult.v $CELLS/primitives.v $CELLS/sky130_fd_sc_hd.v synth/mult_array_netlist.v
vvp gls
```

Result: `PASS: 256 vectors checked, 0 errors`

## Part C: Static timing analysis

The clock period is set by `set T` in `sta/sta.tcl`.

```sh
sta sta/sta.tcl
```

| Run | T (ns) | Worst slack (ns) |
|---|---|---|
| 1 | 10 | 7.027 |
| 2 | 2.98 | 0.007 |

T_min = 10 − 7.027 = 2.973 ns, rounded up to 2.98 ns. F_max = 1000 / 2.98 = 335.6 MHz.

`sta/mult_array_timing.rpt` is the report from run 2 (T = 2.98 ns).

## Part D: Place and route

The container's default PDK is not SKY130, so the PDK and standard cell library are passed explicitly:

```sh
cd pnr
librelane --manual-pdk --pdk-root /foss/pdks --pdk sky130A --scl sky130_fd_sc_hd config.json
```

The starting CLOCK_PERIOD is 1.2 × 2.98 = 3.58 ns, rounded up to 4.0 ns. After each failed run, CLOCK_PERIOD in `config.json` was increased by 0.5 ns and the flow was run again.

| Attempt | Run folder | CLOCK_PERIOD (ns) | Setup slack (ns) | DRC errors | LVS errors | Outcome |
|---|---|---|---|---|---|---|
| 1 | RUN_2026-10-23_18-59-28 | 4.0 | −1.688 | 0 | 0 | Failed: setup violations (ss_100C_1v60 corners) |
| 2 | RUN_2026-10-23_19-04-48 | 4.5 | −1.188 | 0 | 0 | Failed: setup violations (ss_100C_1v60 corners) |
| 3 | RUN_2026-10-23_19-08-06 | 5.0 | −0.688 | 0 | 0 | Failed: setup violations (ss_100C_1v60 corners) |
| 4 | RUN_2026-10-23_19-15-56 | 5.5 | −0.188 | 0 | 0 | Failed: setup violations (ss_100C_1v60 corners) |
| 5 | RUN_2026-10-23_19-19-43 | 6.0 | 0.044 | 0 | 0 | Passed |

Setup slack is the worst value over all corners (`timing__setup__ws`). DRC is 0 for Magic, KLayout and the router.

Final outputs copied from the passing run:

```sh
cp runs/RUN_2026-10-23_19-19-43/final/metrics.json .
cp runs/RUN_2026-10-23_19-19-43/final/gds/mult_array.gds .
```
