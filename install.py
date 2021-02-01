import time
import uos
import upip

from boot import network_connect

SLEEP_TIME = 3
ip = network_connect()
print("ip: {}".format(ip))
print("sleeping {} seconds".format(SLEEP_TIME))
time.sleep(SLEEP_TIME)

install_location = "lib"
install_names = {"micropython-logging": "logging.py"}

for install_name, lib_name in install_names.items():
    try:
        uos.stat("./{}/{}".format(install_location, lib_name))
        print("exists {}".format(install_name))
    except OSError:
        upip.install("{}".format(install_name))
        print("installed {}".format(install_name))
