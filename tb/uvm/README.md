# AES-128 UVM Testbench

A small UVM environment for the AES core in `rtl/`. Your Verilog RTL is
not modified — the simulator compiles Verilog RTL and a SystemVerilog
testbench together in the same run, which is normal practice.

## Run it

```bash
cd tb/uvm

vsim -c -do run.do

# More transactions:
vsim -c -do "set NUM_TXN 2000; do run.do"
```

## The four features, one file each

| # | Feature | File | What it does |
|---|---|---|---|
| 1 | Constrained-random | `aes_stimulus.svh` | Generates random plaintexts and keys, weighted so the extremes (all 0s, all 1s, `AAAA…`, `5555…`) actually show up |
| 2 | Golden-model scoreboard | `aes_scoreboard.svh` + `aes_reference.svh` | Asks a reference model what the answer should be, compares against the hardware |
| 3 | SVA | `aes_assertions.sv` | Alarms if `valid_out` doesn't arrive exactly N cycles after `valid_in` |
| 4 | Functional coverage | `aes_coverage.svh` | Ticks boxes on a checklist, prints a % at the end |

`aes_reference.svh` is AES-128 written from FIPS-197 in plain
SystemVerilog — no DPI, no C compiler needed, so it runs anywhere the
testbench does (ModelSim Starter Edition, EDA Playground, Questa).

## Supporting files

| File | What it is |
|---|---|
| `aes_if.sv` | The bundle of DUT pins the classes reach through |
| `aes_env.svh` | Driver, monitor, environment, test — the wiring |
| `aes_pkg.sv` | Puts the classes in one namespace |
| `tb_top.sv` | Clock, reset, DUT instance, `run_test()` |
| `run.do` | Compile + run script |

## How it fits together

```
aes_sequence --> sequencer --> driver --> [ your RTL ] --> monitor --+--> scoreboard
   (random)                                                          |    (vs reference model)
                                                                      +--> coverage
                          assertions watch the pins the whole time
```

The monitor rebuilds every transaction from the **pins**, not from the
driver's copy. That matters: if it trusted the driver's data, a driver
bug would be invisible, because the testbench would just be checking
itself.

## What "passing" looks like

Three independent things have to be true:

1. **Scoreboard**: `0 failed` — every ciphertext matched the reference model.
2. **Assertions**: no `a_latency` / `a_not_early` failures, and
   `c_encryption_ran` was hit (proving the test wasn't silently doing
   nothing).
3. **Coverage**: near 100% — the edge cases really were exercised.

Any one alone is not enough. A run can pass every assertion by never
starting an encryption, and hit 100% coverage while producing wrong
answers.

## Latency: spec says 10, this RTL takes 12

Worth knowing before anyone asks you about it in an interview.

`aes_controller.v` runs `IDLE → INIT → ROUND(x10) → FINISH`. That's ten
round cycles plus one for `INIT` (loading `plaintext ^ cipher_key`) and
one for `FINISH` (asserting `done`) — **12 total**.

Measured against your RTL, not assumed:

```
latency=12  ct=69c4e0d86a7b0430d8cdb78070b4c55a  MATCH   (FIPS-197 C.1)
latency=12  ct=3925841d02dc09fbdc118597196a0b32  MATCH   (FIPS-197 B)
latency=12  ct=66e94bd4ef8a2c3b884cfa59ca342b2e  MATCH   (all zeros)
latency=12  ct=bcbf217cb280cf30b2517052193ab979  MATCH   (all ones)
```

**The encryption is correct on every vector** — only the cycle count
differs from the spec. `LATENCY` in `aes_assertions.sv` is set to 12 so
the testbench passes against the RTL as it is. Set it to 10 and the
assertions will fire, which is exactly what a checker is for.

To make the hardware match the spec you'd fold `INIT` into the first
`ROUND` cycle and assert `done` during the last round instead of in a
separate `FINISH` state. That's an RTL change and is deliberately not
made here.

## Jargon, decoded

| Term | Plain English |
|---|---|
| sequence item | One transaction (here: a plaintext + key + result) |
| sequence | The generator that produces a stream of items |
| sequencer | Passes items from a sequence to the driver |
| driver | Turns a transaction into pin wiggles |
| monitor | Watches pins and rebuilds what it saw |
| scoreboard | Decides pass/fail |
| analysis port | A broadcast — one `write()` reaches every listener |
| env | The box holding all of the above |
| test | The top; picks which stimulus to run |
| `uvm_component_utils` | "This class is permanent" (driver, monitor, env, test) |
| `uvm_object_utils` | "This class is temporary" (transaction, sequence) |
| build_phase | Construct components — runs top-down |
| connect_phase | Wire them together — runs bottom-up, after all builds |
| run_phase | The only phase that consumes simulation time |
| objection | "I'm not finished yet." The test ends when all are dropped |
| factory / `type_id::create()` | Build by name so a type can be swapped without editing the code that builds it |
