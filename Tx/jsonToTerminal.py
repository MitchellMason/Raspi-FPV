#Reads the config file and prints it (bash friendly) into the terminal

import sys
import json

file = sys.argv[1]
config_file = open(file, 'r')

config_json = json.loads(config_file.read())

for cat in config_json:
    for val in config_json[cat]:
        print(val + '=' + str(config_json[cat][val]))
