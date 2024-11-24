from vunit import VUnit

# Create VUnit instance by parsing command line arguments
vu = VUnit.from_argv()

vu.add_osvvm()

# Create library 'lib'
servo_lib = vu.add_library("servo_lib")
com_lib = vu.add_library("com_lib")
ref_lib = vu.add_library("reference_lib")

# Add all files ending in .vhd in current working directory to library
servo_lib.add_source_files("servo_lib/**/*.vhd")
com_lib.add_source_files("com_lib/hdl/*.vhd")
com_lib.add_source_files("com_lib/tb/*.vhd") 
ref_lib.add_source_files("reference_lib/hdl/*.vhd")
ref_lib.add_source_files("reference_lib/tb/*.vhd")

# Run vunit function
vu.main()