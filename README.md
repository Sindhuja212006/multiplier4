# 4-bit Array Multiplier: RTL to GDSII (SKY130)

## Team

| Name | Roll number |
|---|---|
| Allu Joanna Preetika | 2024112008 |
| Sindhuja Babu | 2024102055 |

All commands are run from the repository root inside the IIC-OSIC-TOOLS container, unless noted. Results are in `report/report.pdf`.

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

Error test: `sum` in `rtl/full_adder.v` temporarily changed to `a ^ b`, then the same commands run again, then the change reverted:

```sh
iverilog -g2012 -o sim tb/tb_mult.v rtl/full_adder.v rtl/mult_array.v
vvp sim
```

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

## Part C: Static timing analysis

The clock period is set by `set T` in `sta/sta.tcl`. First run with `set T 10`, then with `set T 2.98` (T_min):

```sh
sta sta/sta.tcl
```

## Part D: Place and route

The container's default PDK is not SKY130, so the PDK and standard cell library are passed explicitly:

```sh
cd pnr
librelane --manual-pdk --pdk-root /foss/pdks --pdk sky130A --scl sky130_fd_sc_hd config.json
```

After each run that failed timing, `CLOCK_PERIOD` in `config.json` was increased by 0.5 ns and the flow was run again.

| Attempt | Run folder | CLOCK_PERIOD (ns) | Outcome |
|---|---|---|---|
| 1 | RUN_2026-10-23_18-59-28 | 4.0 | Failed: setup violations |
| 2 | RUN_2026-10-23_19-04-48 | 4.5 | Failed: setup violations |
| 3 | RUN_2026-10-23_19-08-06 | 5.0 | Failed: setup violations |
| 4 | RUN_2026-10-23_19-15-56 | 5.5 | Failed: setup violations |
| 5 | RUN_2026-10-23_19-19-43 | 6.0 | Passed |

Final outputs copied from the passing run:

```sh
cp runs/RUN_2026-10-23_19-19-43/final/metrics.json .
cp runs/RUN_2026-10-23_19-19-43/final/gds/mult_array.gds .
```
