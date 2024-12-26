import sys

# Import the HDLRegression module to the Python script:
from hdlregression import HDLRegression

# Define a HDLRegression item to access the HDLRegression functionality:
hr = HDLRegression(output_path="hdlreg")

hr.compile_uvvm('C:\\Projects\\vhdl\\UVVM')

# hr.add_files("ethertype_decode.vhd", "my_lib")
# hr.add_files("tb_ethertype_decode.vhd", "my_lib")
hr.add_files("./hdl/*.vhd", "network_lib")
hr.add_files("./tb/*.vhd", "network_lib")
hr.add_files("../stream_lib/hdl/stream_pkg.vhd", "stream_lib")
hr.add_files("../stream_lib/hdl/status_pkg.vhd", "stream_lib")

hr.add_files("../open-logic/src/base/vhdl/olo_base_pkg_array.vhd", "olo_lib")



# => hr.add_files(<filename>)                   # Use default library my_work_lib
# => hr.add_files(<filename>, <library_name>)   # or specify a library name.

# hr.set_result_check_string("pass")
hr.start()