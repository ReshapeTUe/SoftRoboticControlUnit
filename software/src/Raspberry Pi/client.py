import socket
import sys

# Create a socket
sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)

# Connect to the remote host and port
sock.connect(('localhost', 2999))

# Send a request to the host
data = [0, 1,2 ,3 , 4, 5]
sock.send(bytes(data))

# Get the host's response, no more than, say, 1,024 bytes
response_data = sock.recv(1024)

# Terminate
sock.close(  )