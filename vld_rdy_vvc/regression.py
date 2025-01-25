from hdlregression import HDLRegression

hr = HDLRegression(output_path='hdlreg')

hr.compile_uvvm('C:\\Projects\\vhdl\\UVVM')

hr.set_library(library_name='vip_vld_rdy')
hr.add_files(filename='c:/Projects/vhdl/UVVM/uvvm_vvc_framework/src_target_dependent/*.vhd')
hr.add_files(filename='./src/*.vhd')
hr.add_files(filename='./tb/*.vhd')

hr.start()