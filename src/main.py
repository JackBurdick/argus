import machine
from ulog import ULog
from updater.ota_updater import OTAUpdater

install_logger = ULog("install")


def maybe_download_and_install_update():
    install_logger.info("Checking for Updates...")

    ota_updater = OTAUpdater(
        "https://github.com/JackBurdick/argus",
        github_src_dir="src",
        main_dir="app",
        secrets_file="secrets.py",
    )
    install_logger.info("ota_updater created")

    new_update_installed = ota_updater.install_update_if_available()
    install_logger.info("no new update installed")
    if new_update_installed:
        install_logger.info("installed update")
        install_logger.info("restarting machine")
        machine.reset()

    del ota_updater


def boot():
    maybe_download_and_install_update()

    # import after updating device
    from app.start import begin

    begin()


boot()
