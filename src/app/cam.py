import camera
import machine
import time


def setup_cam(logger):
    QUALITY = 12
    try:
        camera.init(0)
    except OSError as e:
        # TODO: there should be a safeguard here to prevent constant restart
        time.sleep(2)
        logger.error("unable to initialize camera. restarting.\n err: {}".format(e))
        machine.reset()
    else:
        logger.debug("Camera initialized")
        camera.quality(QUALITY)
        logger.debug("Camera quality set to {}".format(QUALITY))
        return camera


if __name__ == "__main__":
    pass