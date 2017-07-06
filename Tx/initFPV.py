#serve the config file to the ground station before starting actual Tx
import bluetooth
import sys
import json

if(len(sys.argv) != 2):
    print("Please include the path to the config file in the args")
    exit()

config_file = open(sys.argv[1], 'r')
raw_json = config_file.read()
config_json = json.loads(raw_json) #Load the JSON to check for errors

hostMACAddress = 'B8:27:EB:69:ED:8B' #local BT addr
port = 9
backlog = 1
size = 1024*1024 #bytes? we'll get there

sock = bluetooth.BluetoothSocket(bluetooth.RFCOMM)
sock.bind((hostMACAddress, port))
sock.listen(backlog)

try:
    run = True
    while run:
        print("\tWaiting for connection on " + str(sock.getsockname()))
        client, clientInfo = sock.accept()
        print("\tConnected to " + str(client) + ". Sending file")
        client.send(str(raw_json))
    print("\tClosing BT")
    client.close()
    sock.close()
except:
    print("Socket exception. Closing.\n")
    client.close()
    sock.close()
    raise
