## Run formal
`podman run -i -t --rm -v .:/fpga ghcr.io/sverrham/bookworm/formal:24.11 bash`

The to run formal
`sby --yosys "yosys -m ghdl" -f <file>.sby`