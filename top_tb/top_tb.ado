setenv SIM_WORKING_FOLDER .
set newDesign 0
if {![file exists "D:/Users/Chirikalo/Lattice_proj/DKS-5351_fpga_for_MACHXO2_2000/top_tb/top_tb.adf"]} { 
	design create top_tb "D:/Users/Chirikalo/Lattice_proj/DKS-5351_fpga_for_MACHXO2_2000"
  set newDesign 1
}
design open "D:/Users/Chirikalo/Lattice_proj/DKS-5351_fpga_for_MACHXO2_2000/top_tb"
cd "D:/Users/Chirikalo/Lattice_proj/DKS-5351_fpga_for_MACHXO2_2000"
designverincludedir -clear
designverlibrarysim -PL -clear
designverlibrarysim -L -clear
designverlibrarysim -PL pmi_work
designverlibrarysim ovi_machxo2
designverdefinemacro -clear
if {$newDesign == 0} { 
  removefile -Y -D *
}
addfile "D:/Users/Chirikalo/Lattice_proj/DKS-5351_fpga_for_MACHXO2_2000/impl1/source/top.v"
addfile "D:/Users/Chirikalo/Lattice_proj/DKS-5351_fpga_for_MACHXO2_2000/impl1/source/highvoltage.v"
addfile "D:/Users/Chirikalo/Lattice_proj/DKS-5351_fpga_for_MACHXO2_2000/impl1/source/wb_ctrl.v"
addfile "D:/Users/Chirikalo/Lattice_proj/DKS-5351_fpga_for_MACHXO2_2000/impl1/source/RAM.v"
addfile "D:/Users/Chirikalo/Lattice_proj/DKS-5351_fpga_for_MACHXO2_2000/impl1/source/main_ctrl.v"
addfile "D:/Users/Chirikalo/Lattice_proj/DKS-5351_fpga_for_MACHXO2_2000/impl1/source/spi_not_efb.v"
addfile "D:/Users/Chirikalo/Lattice_proj/DKS-5351_fpga_for_MACHXO2_2000/impl1/source/FIFO.v"
addfile "D:/Users/Chirikalo/Lattice_proj/DKS-5351_fpga_for_MACHXO2_2000/impl1/source/counter.v"
addfile "D:/Users/Chirikalo/Lattice_proj/DKS-5351_fpga_for_MACHXO2_2000/impl1/source/capacitance_avk.v"
addfile "D:/Users/Chirikalo/Lattice_proj/DKS-5351_fpga_for_MACHXO2_2000/impl1/source/dividers1.v"
addfile "D:/Users/Chirikalo/Lattice_proj/DKS-5351_fpga_for_MACHXO2_2000/impl1/source/testbench.v"
addfile "D:/Users/Chirikalo/Lattice_proj/DKS-5351_fpga_for_MACHXO2_2000/impl1/source/testbench_clock_5ms.v"
addfile "D:/Users/Chirikalo/Lattice_proj/DKS-5351_fpga_for_MACHXO2_2000/impl1/source/testbench_clock_4mhz.v"
addfile "D:/Users/Chirikalo/Lattice_proj/DKS-5351_fpga_for_MACHXO2_2000/impl1/source/testbench_pulse_counter.v"
addfile "D:/Users/Chirikalo/Lattice_proj/DKS-5351_fpga_for_MACHXO2_2000/impl1/source/testbench_antibounce.v"
addfile "D:/Users/Chirikalo/Lattice_proj/DKS-5351_fpga_for_MACHXO2_2000/impl1/source/testbench_spi.v"
addfile "D:/Users/Chirikalo/Lattice_proj/DKS-5351_fpga_for_MACHXO2_2000/impl1/source/tb_fifo.v"
vlib "D:/Users/Chirikalo/Lattice_proj/DKS-5351_fpga_for_MACHXO2_2000/top_tb/work"
set worklib work
adel -all
vlog -dbg -work work "D:/Users/Chirikalo/Lattice_proj/DKS-5351_fpga_for_MACHXO2_2000/impl1/source/top.v"
vlog -dbg -work work "D:/Users/Chirikalo/Lattice_proj/DKS-5351_fpga_for_MACHXO2_2000/impl1/source/highvoltage.v"
vlog -dbg -work work "D:/Users/Chirikalo/Lattice_proj/DKS-5351_fpga_for_MACHXO2_2000/impl1/source/wb_ctrl.v"
vlog -dbg -work work "D:/Users/Chirikalo/Lattice_proj/DKS-5351_fpga_for_MACHXO2_2000/impl1/source/RAM.v"
vlog -dbg -work work "D:/Users/Chirikalo/Lattice_proj/DKS-5351_fpga_for_MACHXO2_2000/impl1/source/main_ctrl.v"
vlog -dbg -work work "D:/Users/Chirikalo/Lattice_proj/DKS-5351_fpga_for_MACHXO2_2000/impl1/source/spi_not_efb.v"
vlog -dbg -work work "D:/Users/Chirikalo/Lattice_proj/DKS-5351_fpga_for_MACHXO2_2000/impl1/source/FIFO.v"
vlog -dbg -work work "D:/Users/Chirikalo/Lattice_proj/DKS-5351_fpga_for_MACHXO2_2000/impl1/source/counter.v"
vlog -dbg -work work "D:/Users/Chirikalo/Lattice_proj/DKS-5351_fpga_for_MACHXO2_2000/impl1/source/capacitance_avk.v"
vlog -dbg -work work "D:/Users/Chirikalo/Lattice_proj/DKS-5351_fpga_for_MACHXO2_2000/impl1/source/dividers1.v"
vlog -dbg -work work "D:/Users/Chirikalo/Lattice_proj/DKS-5351_fpga_for_MACHXO2_2000/impl1/source/testbench.v"
vlog -dbg -work work "D:/Users/Chirikalo/Lattice_proj/DKS-5351_fpga_for_MACHXO2_2000/impl1/source/testbench_clock_5ms.v"
vlog -dbg -work work "D:/Users/Chirikalo/Lattice_proj/DKS-5351_fpga_for_MACHXO2_2000/impl1/source/testbench_clock_4mhz.v"
vlog -dbg -work work "D:/Users/Chirikalo/Lattice_proj/DKS-5351_fpga_for_MACHXO2_2000/impl1/source/testbench_pulse_counter.v"
vlog -dbg -work work "D:/Users/Chirikalo/Lattice_proj/DKS-5351_fpga_for_MACHXO2_2000/impl1/source/testbench_antibounce.v"
vlog -dbg -work work "D:/Users/Chirikalo/Lattice_proj/DKS-5351_fpga_for_MACHXO2_2000/impl1/source/testbench_spi.v"
vlog -dbg -work work "D:/Users/Chirikalo/Lattice_proj/DKS-5351_fpga_for_MACHXO2_2000/impl1/source/tb_fifo.v"
module testbench
vsim  +access +r testbench   -PL pmi_work -L ovi_machxo2
add wave *
run 1000ns
