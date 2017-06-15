#serve the config file to the ground station before starting actual Tx
print("starting FPV")
import bluetooth
import sys
import json

if(len(sys.argv) != 2):
    print("Please include the path to the config file in the args")
    exit()

print("reading " + sys.argv[1])
config_file = open(sys.argv[1], 'r')
config_json = json.loads(config_file.read())
print("done")

hostMACAddress = 'B8:27:EB:69:ED:8B' #local BT addr
port = 9
backlog = 1
size = 1024*1024 #bytes? we'll get there

print("starting bluetooth")
sock = bluetooth.BluetoothSocket(bluetooth.RFCOMM)
sock.bind((hostMACAddress, port))
sock.listen(backlog)

try:
    print("waiting for connection on " + str(sock.getsockname()))
    client, clientInfo = sock.accept()
    print("Connected to " + str(client) + ". Sending file")
    client.send(str(config_json))
    print("Sent. Closing")
    client.close()
    sock.close()
except:
    print("Socket exception. Closing.\n")
    client.close()
    sock.close()
    raise
