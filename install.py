import uos
import upip

install_location = "lib"
install_names = {"micropython-logging": "logging.py"}

for install_name, lib_name in install_names.items():
    try:
        uos.stat("./{}/{}".format(install_location, lib_name))
        print("exists {}".format(install_name))
    except OSError:
        upip.install("{}".format(install_name))
        print("installed {}".format(install_name))
