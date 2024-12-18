# Compile and run testbenches for all modules using the HDLRegresion library

import sys
# sys.path.append('C:\\projects\\vhdl\\HDLRegresion')

from hdlregression import HDLRegression

hr = HDLRegression(output_path='hdlreg')

hr.compile_uvvm('C:\\Projects\\vhdl\\UVVM')
hr.compile_osvvm('C:\\Projects\\vhdl\\OSVVM')

hr.set_library(library_name='com_lib')
hr.add_files(filename='com_lib/hdl/*.vhd')
hr.add_files(filename='com_lib/tb_osvvm/*.vhd')

hr.set_library(library_name='reference_lib')
hr.add_files(filename='reference_lib/hdl/*.vhd')
# hr.add_files(filename='reference_lib/tb_osvvm/*.vhd')

hr.set_result_check_string('Test passed')


hr.start()
