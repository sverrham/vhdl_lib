import serial

ser = serial.Serial('COM5', 115200)


def decode(message_type: bytes, message_body: bytearray):

    if message_type == 1:
        transitions = int.from_bytes(message_body, "big")
        print(f"vld_ready_profiler: transitions: {transitions} bytes/s: {transitions*4}")
    else:
        print(f"Unknown Message {message_type} body: {message_body}")

while True:
    data = ser.readline()
    # verify integrity of line
    if data[0:3] == 'SHA'.encode("utf-8") and data[-5:-2] == 'AHS'.encode("utf-8"):
        # print(data)
        decode(data[3], data[4:-5])
        # print(data[3:-6])

    else:
        print(f"wrong framing: {data}")