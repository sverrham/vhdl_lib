# OSVVM Style script to compile library

library com_lib
analyze hdl/com_pkg.vhd
analyze hdl/uart_tx_arbiter.vhd
analyze hdl/uart.vhd

analyze tb_osvvm/tb_uart_tx_arbiter_osvvm.vhd

TestCase tb_uart_tx_arbiter_osvvm
simulate tb_uart_tx_arbiter_osvvm