XILINX_DIR = /opt/Xilinx/Vivado/2017.3

MAIN = main/main.vhd main/ic.vhd main/timer.vhd \
		 main/cpu/cpu.vhd main/cpu/datapath.vhd main/cpu/ctl.vhd main/cpu/pc.vhd main/cpu/ar.vhd main/cpu/hi.vhd main/cpu/lo.vhd main/cpu/alu.vhd main/cpu/sr.vhd main/cpu/sp.vhd main/cpu/xr.vhd main/cpu/yr.vhd main/cpu/zp.vhd \
		 main/mem/mem.vhd main/mem/rom.vhd main/mem/ram.vhd main/mem/dmem.vhd main/mem/memio.vhd
SRC  = $(MAIN) \
		 comp.vhd waiter.vhd clk.vhd cdc.vhd cdc_pulse.vhd \
		 keyboard/ps2.vhd keyboard/scancode.vhd keyboard/keyboard.vhd \
       ethernet/ethernet.vhd ethernet/lan8720a/lan8720a.vhd ethernet/lan8720a/rmii_rx.vhd ethernet/lan8720a/rmii_tx.vhd \
       ethernet/rx_dma.vhd ethernet/fifo.vhd ethernet/rx_header.vhd \
   	 vga/vga.vhd vga/overlay.vhd vga/pix.vhd vga/font.vhd vga/opcodes.vhd vga/chars.vhd
XDC  = comp.xdc
TB = main_tb
TB_SRC = main/$(TB).vhd keyboard/ps2_tb.vhd
WAVE   = main/$(TB).ghw
SAVE   = main/$(TB).gtkw


#####################################
# Generate bit-file and program FPGA
#####################################

comp.bit: comp.tcl $(SRC) $(XDC) ../rom.txt
	bash -c "source $(XILINX_DIR)/settings64.sh ; vivado -mode tcl -source $<"

fpga: comp.bit
	djtgcfg prog -d Nexys4DDR -i 0 --file $<


#####################################
# Simulation
#####################################

sim: $(MAIN) $(TB_SRC) ../rom.txt
	ghdl -i --std=08 --work=unisim $(XILINX_DIR)/data/vhdl/src/unisims/unisim_VCOMP.vhd
	ghdl -i --std=08 --work=unisim $(XILINX_DIR)/data/vhdl/src/unisims/unisim_VPKG.vhd
	ghdl -i --std=08 --work=unisim $(XILINX_DIR)/data/vhdl/src/unisims/primitive/*.vhd
	ghdl -i --std=08 --work=work $(MAIN) $(TB_SRC)
	ghdl -m --std=08 -frelaxed-rules $(TB)
	ghdl -r $(TB) --assert-level=error --wave=$(WAVE) --stop-time=660us
	gtkwave $(WAVE) $(SAVE)


#####################################
# Cleanup
#####################################

clean:
	rm -rf usage_statistics_webtalk.*
	rm -rf vivado*
	rm -rf *.o
	rm -rf comp.bit
	rm -rf comp.dcp
	rm -rf .Xil
	rm -rf .cache
	rm -rf work-obj08.cf
	rm -rf unisim-obj08.cf
	rm -rf $(TB)
	rm -rf $(WAVE)
	rm -rf comp.bit
	rm -rf comp.bmm
	rm -rf fsm_encoding.os
	rm -rf timing_summary.rpt

