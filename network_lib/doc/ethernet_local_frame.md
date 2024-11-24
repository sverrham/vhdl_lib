# Ethernet local framing

Ethernet data should be framed and sent on the bus.

Want the stream to just flow through modules with flow control.

So valid/ready flow control.
producer can set valid only when data is valid and never revoke it. can set it no mater the state of the ready signal.

consumer can set ready at any time, before or after producer has set valid.
consumer can retract ready if it wants.

psl to check the ready valid interface is correct.
`vld and not rdy -> vld and stable(data)`

if valid is high and ready is low, next clock vld must be high and no change to data.

## Framing
internal bus, with metadata.
- encapsulates one packet
- Tag about the data on the bus
    - start of frame (header word) SOF
    - start of packet SOP
    - end of frame EOF
    - data DATA
    - 

```vhdl
type  t_stream_tag_type is (SOF, SOP, DATA, EOF);
type t_stream is record(
    data : std_logic_vector(31 downto 0);
    tag  : t_stream_tag_type;
)
```


### Start of frame SOF
|bits | | |  |
|-|-|-|-|
|31 -> 8 | | | reserved|
|7 -> 0  |  |  | Type |

### Start of packet
|bis | | | |
|-|-|-|-|
|31 downto 0 | | data |

### Data
| bits | | | | 
|-|-|-|-|
|31 -> 0 | | data |

### End of frame EOF
| bits | | | |
|-|-|-|-|
|31 -> 0 | | data |
