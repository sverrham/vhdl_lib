import serial

ser = serial.Serial('COM5', 115200)

def decode_arp(data: bytearray):
    destination_mac = data[0:6]
    source_mac = data[6:12]
    ethertype = data[12:14]
    payload = data[14:]
    # print destination mac as hex string, standard mac format
    destination_mac = ':'.join(['{:02x}'.format(x) for x in destination_mac])
    source_mac = ':'.join(['{:02x}'.format(x) for x in source_mac])
    # print ethertype as hex string
    ethertype = ':'.join(['{:02x}'.format(x) for x in ethertype])
    print(f"destination_mac: {destination_mac} source_mac: {source_mac} ethertype: {ethertype} ")
    # print the rest of an arp packet as hex string with correct type before each field.
    Hardware_Type = int.from_bytes(payload[0:2], "big")
    # protocol type as hex string
    Protocol_Type = ':'.join(['{:02x}'.format(x) for x in payload[2:4]])
    Hardware_Address_Length = int.from_bytes(payload[4:5], "big")
    Protocol_Address_Length = int.from_bytes(payload[5:6], "big")
    print(f"Hardware_Type: {Hardware_Type} Protocol_Type: {Protocol_Type} Hardware_Address_Length: {Hardware_Address_Length} Protocol_Address_Length: {Protocol_Address_Length}")
    
    operation = int.from_bytes(payload[6:8], "big")
    # sender mac as standard mac format
    sender_mac = ':'.join(['{:02x}'.format(x) for x in payload[8:14]])
    # sender ip as standard ip format
    sender_ip = '.'.join([str(x) for x in payload[14:18]])
    # target mac as standard mac format
    target_mac = ':'.join(['{:02x}'.format(x) for x in payload[18:24]])
    # target ip as standard ip format
    target_ip = '.'.join([str(x) for x in payload[24:28]])
    print(f"operation: {operation} sender_mac: {sender_mac} sender_ip: {sender_ip} target_mac: {target_mac} target_ip: {target_ip}")


def decode(message_type: bytes, message_body: bytearray):

    if message_type == 1:
        transitions = int.from_bytes(message_body, "big")
        print(f"vld_ready_profiler: transitions: {transitions} bytes/s: {transitions*4}")
    if message_type == 2:
        # print(f"arp data {message_type} length: {len(message_body)} body: {message_body}")
        print(f"\narp data {message_type} length: {len(message_body)}")
        decode_arp(message_body)
    else:
        print(f"Unknown Message {message_type} length: {len(message_body)} body: {message_body}")

new_data = True
while True:
    serial_data = ser.readline()
    if new_data:
        data = serial_data
    else:
        data += serial_data

    if data[0:3] != 'SHA'.encode("utf-8"):
        new_data = True
        print("wrong framing")

    if data[-5:-2] == 'AHS'.encode("utf-8"):
        new_data = True
        decode(data[3], data[4:-5])