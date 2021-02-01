import gc
import time

import app.secrets as sc
import esp
import network

# from ulog import ULog

esp.osdebug(None)

# boot_logger = ULog("boot_logger")


gc.collect()


def network_connect():
    station = network.WLAN(network.STA_IF)
    station.active(True)
    station.connect(sc.SSID, sc.PASSWORD)
    time.sleep(0.5)
    while station.isconnected() == False:
        time.sleep(0.5)
    ip = station.ifconfig()[0]
    return ip


ip = network_connect()
print("ip: {}".format(ip))
