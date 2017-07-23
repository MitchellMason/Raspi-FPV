import socket
import sys

# Create a TCP/IP socket
sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)

# Bind the socket to the port
server_addr = ('localhost', 9305)
client_addr = ('localhost', 9305)

print >>sys.stderr, 'starting server on %s port %s\n' % server_addr
sock.bind(server_addr)

while True:
    print >>sys.stderr, 'reading from stdin'
    data = sys.stdin.read()
    if len(data) > 0:
        sent = sock.sendto(data, client_addr)
        print >>sys.stderr, 'sent %s bytes to %s' % (sent, client_addr)
