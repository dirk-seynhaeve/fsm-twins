# fsm-twins

One state machine, written twice: once in SystemVerilog and once in VHDL. A top level runs both
on the same inputs and compares every output on every clock. A UVM testbench drives them through
every reachable state and transition and checks that the twins never disagree.

It is small on purpose, and it uses on purpose the constructs that state-machine tools have to
get right, so it doubles as a test case for anything that reads, draws or checks state machines.

## The machine

A transfer controller. `IDLE` waits for a command; `decode` turns the command into the next state;
`LOAD`, `RUN`, `HOLD`, `FLUSH` and `FINISH` move a transfer along; `abort` sends every state to
`ERROR`, which only a reset leaves.

| What | Where |
|---|---|
| Two processes: a clocked one copies the next state, a combinational one decides it | both twins |
| An asynchronous active-low reset (`rst_n`) and a synchronous one (`clr`), both to `IDLE` | `state_reg` |
| One condition that wins in every state: `abort`, tested before the `case`, to `ERROR` | next-state process |
| A next state decided in a function, `decode`, called from `IDLE` and from `HOLD` | `decode` |
| Several transitions between the same two states (`decode` sends two commands to `LOAD`) | `IDLE`, `HOLD` |
| Staying by default (the next state starts as the current one) and staying by an explicit assignment | `HOLD` |
| A machine inside a state: the beat machine `SA`, `SB`, `SC` runs inside `RUN` | `RUN` |
| States as an enumeration (outer) and as named constants (inner) | declarations |
| A dead state: nothing leaves `ERROR` but a reset | `ERROR` |
| An unreachable state: nothing enters `SPARE` | `SPARE` |
| States with no arm of their own, handled only by the default arm: `ODD`, `PARK` | `others` / `default` |
| Ten states in a four-bit register: six codes are no state | `state_t` |
| Moore outputs (`busy`, `done`, `fault`), a Mealy output (`pulse`), defaults before the `case`, and a registered output (`beats`) | both twins |
| Comments on states and on the branches transitions take | both twins |

State names avoid the VHDL keywords and port names they would clash with, since VHDL is not case
sensitive: hence `FINISH`, `ERROR` and `PARK`.

## Layout

```
rtl/ctrl_fsm.sv        the SystemVerilog twin   (module ctrl_fsm_sv)
rtl/ctrl_fsm.vhd       the VHDL twin            (entity ctrl_fsm_vhd)
rtl/fsm_twins_top.sv   both twins and the comparison (output mismatch)
tb/                    the UVM testbench: interface, top, and tb/uvm/
files.f                every file in compile order
Makefile               Questa
```

## The testbench

- `twins_tour_test` walks a fixed tour from reset that reaches every reachable state and takes
  every transition, including every `abort`.
- `twins_test` runs the tour, then 3000 clocks of random traffic (`+TWINS_RANDOM_CLOCKS=<n>`).
- The scoreboard compares the twins on every clock after the first reset; one disagreement fails
  the test.
- The coverage model counts every reachable state (9), every transition (27), and the inner
  machine's states (3) and transitions (4). The test fails below 100%. `SPARE` is unreachable by
  design, so it has no bin; the test fails if it is ever entered.
- No constrained randomization and no covergroups: random traffic comes from `$urandom` and the
  coverage is counted by the bench, so it runs on the free starter editions of simulators too.

## Running it

With Questa on `PATH`:

```
make            # twins_test, seed 1
make tour       # twins_tour_test
make SEED=7
```

A passing run ends with `UVM_ERROR :    0` and prints, for example:

```
[COVERAGE] states 100.0% (9), transitions 100.0% (27), inner states 100.0% (3), inner transitions 100.0% (4)
[SCOREBOARD] 3076 clocks, 3076 compared, 0 mismatches
```

## License

Apache-2.0. See [LICENSE](LICENSE).
