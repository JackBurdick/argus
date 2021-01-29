from ulog import ULog
from app.start import begin
from updater.ota_updater import OTAUpdater
import app.secrets as sc


# logger = ULog("main.py")
run_logger = ULog("runtime")


def maybe_download_and_install_update():
    run_logger.info("Checking for Updates...")

    ota_updater = OTAUpdater(
        "https://github.com/JackBurdick/argus",
        github_src_dir="src",
        main_dir="app",
        secrets_file="secrets.py",
    )
    run_logger.info("ota_updater created")

    # ota_updater.install_update_if_available()
    ota_updater.install_update_if_available_after_boot(sc.SSID, sc.PASSWORD)
    run_logger.info("installing if available")

    del ota_updater


def boot():
    maybe_download_and_install_update()
    begin()


boot()