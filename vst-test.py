
import serial
import sys

#serialPort=serial.Serial(port="/dev/ttyS3", baudrate=115200, bytesize=8, timeout=2, stopbits=serial.STOPBITS_ONE)
serialport=serial.Serial(sys.argv[1])

# draw a square
data=[ [2,0,0],
       [2,0,100],
       [2,100,100],
       [2,100,0],
       [2,0,0]]

serialport.write(bytearray([0,0,0,0,0]))
loop = 0
while loop == 0:
  loop = 0
  for d in data:
    combined = d[0]<<22 
    combined |= d[1]<<11
    combined |= d[2]<<0
    command = bytearray([((combined >> 16) & 255),
                          ((combined >> 8) & 255),
                          ((combined >> 0) & 255)])
    serialport.write(command)
  serialport.write(bytearray([1,1,1,0,0,0]))

