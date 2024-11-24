# Compile and run testbenches for all modules using the HDLRegresion library

import sys
# sys.path.append('C:\\projects\\vhdl\\HDLRegresion')

from hdlregression import HDLRegression

hr = HDLRegression(output_path='hdlreg')

hr.compile_uvvm('C:\\Projects\\vhdl\\UVVM')

hr.set_library(library_name='stream_lib')
hr.add_files(filename='hdl/*.vhd')
hr.add_files(filename='tb/*.vhd')


# hr.set_result_check_string('Test passed')


hr.start()
