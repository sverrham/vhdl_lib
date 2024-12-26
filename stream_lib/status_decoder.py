import serial

ser = serial.Serial('COM5', 115200)


def decode(message_type: bytes, message_body: bytearray):

    if message_type == 1:
        transitions = int.from_bytes(message_body, "big")
        print(f"vld_ready_profiler: transitions: {transitions} bytes/s: {transitions*4}")
    if message_type == 2:
        print(f"arp data {message_type} length: {len(message_body)} body: {message_body}")
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