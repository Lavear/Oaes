#======================================================================
# run.do  -  compile and run in ModelSim / Questa.
#
#   vsim -c -do run.do
#
# To run more transactions:
#   vsim -c -do "set NUM_TXN 2000; do run.do"
#======================================================================

if {![info exists NUM_TXN]} { set NUM_TXN 200 }

set RTL ../../rtl

# Fresh library
if {[file exists work]} { vdel -all -lib work }
vlib work
vmap work work

# 1. Your Verilog RTL, unchanged.
echo "=== compiling RTL ==="
vlog -quiet $RTL/subbytes.v $RTL/shiftrows.v $RTL/mixcolumns.v \
            $RTL/addroundkey.v $RTL/aes_datapath.v $RTL/state_reg.v \
            $RTL/key_expansion.v $RTL/aes_controller.v $RTL/aes_top.v

# 2. The SystemVerilog testbench (this also compiles the golden model in
#    aes_reference.svh - no separate step, no DPI, no C compiler needed).
#    +incdir+.  tells vlog where the .svh files are.
#    -L mtiUvm  links the UVM library that ships with Questa.
echo "=== compiling testbench ==="
vlog -quiet -sv +incdir+. -L mtiUvm \
    aes_if.sv aes_assertions.sv aes_pkg.sv tb_top.sv

# 3. Run.
echo "=== running ==="
vsim -c -coverage -assertdebug -sv_seed random \
     +num_txn=$NUM_TXN -L mtiUvm work.tb_top

run -all

echo "=== assertions ==="
assertion report -recursive /tb_top -verbose

echo "=== functional coverage ==="
coverage report -detail -cvg

quit -f
