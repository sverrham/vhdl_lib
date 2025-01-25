# Compile and run testbenches for all modules using the HDLRegresion library

import sys
# sys.path.append('C:\\projects\\vhdl\\HDLRegresion')

from hdlregression import HDLRegression

hr = HDLRegression(output_path='hdlreg')

hr.compile_uvvm('C:\\Projects\\vhdl\\UVVM')
# hr.compile_osvvm('C:\\Projects\\vhdl\\OSVVM')

hr.set_library(library_name='vip_vld_rdy')
hr.add_files(filename='c:/Projects/vhdl/UVVM/uvvm_vvc_framework/src_target_dependent/*.vhd')
hr.add_files(filename='vld_rdy_vvc/src/*.vhd')
hr.add_files(filename='vld_rdy_vvc/tb/*.vhd')

hr.set_library(library_name='com_lib')
hr.add_files(filename='com_lib/hdl/*.vhd')
# hr.add_files(filename='com_lib/tb_osvvm/*.vhd')

hr.set_library(library_name='reference_lib')
hr.add_files(filename='reference_lib/hdl/*.vhd')
# hr.add_files(filename='reference_lib/tb_osvvm/*.vhd')

hr.set_library(library_name='stream_lib')
hr.add_files(filename='stream_lib/hdl/*.vhd')
hr.add_files(filename='stream_lib/tb/*.vhd')

hr.set_library(library_name='olo_lib')
hr.add_files(filename='open-logic/src/base/vhdl/olo_base_pkg_array.vhd')

hr.add_files("network_lib/hdl/*.vhd", "network_lib")
hr.add_files("network_lib/tb/*.vhd", "network_lib")

hr.start()


# hr_osvvm = HDLRegression(output_path='hdlreg_osvvm')

# hr_osvvm.compile_osvvm('C:\\Projects\\vhdl\\OSVVM')

# hr_osvvm.set_library(library_name='com_lib')
# hr_osvvm.add_files(filename='com_lib/hdl/*.vhd')
# hr_osvvm.add_files(filename='com_lib/tb_osvvm/*.vhd')

# hr_osvvm.set_library(library_name='reference_lib')
# hr_osvvm.add_files(filename='reference_lib/hdl/*.vhd')
# hr_osvvm.add_files(filename='reference_lib/tb_osvvm/*.vhd')

# hr_osvvm.set_result_check_string('Test passed')

# hr_osvvm.start()
