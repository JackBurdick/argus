import tinyweb
import time
from .cam import setup_cam
from .sd import setup_sd
import uos
import network
import gc
import json
from ulog import ULog
import machine


IMG_PATH_TEMPLATE = "app/resources/{}__{}__{}.jpg"
V1_BASE_PATH = "/api/v1"
IMG_API_PATH = "{}/{}".format(V1_BASE_PATH, "retrieve")
RESET_API_PATH = "{}/{}".format(V1_BASE_PATH, "reset")
IMG_API_CAPTURE_PATH = "{}/{}".format(V1_BASE_PATH, "obtain")

logger = ULog("main.py")
run_logger = ULog("runtime")

# LED = machine.Pin(1, machine.Pin.OUT)
# time.sleep_ms(300)
# logger.info("led set to pin 1")
# LED.off()
# logger.info("led.off")

# TODO: check if connected

CAM = None
if not CAM:
    CAM = setup_cam(logger)
logger.info("camera setup")
app = tinyweb.webserver(
    host="0.0.0.0",
    port=8081,
    request_timeout=4,
    max_concurrency=2,
    backlog=5,
    debug=True,
)
logger.debug("app webserver created")


def _capture_image():
    global CAM
    try:
        # LED.on()
        # time.sleep_ms(500)
        buf = CAM.capture()
    except Exception as e:
        raise Exception("unable to capture image: {}".format(e))
    return buf


def _write_image(cam_info):
    ret = {}
    if cam_info:
        buf = _capture_image()
        img_path = IMG_PATH_TEMPLATE.format(
            cam_info["bucket"], cam_info["index"], cam_info["ts"]
        )
        f = open(img_path, "w")
        f.write(buf)
        time.sleep_ms(100)
        f.close()
        # LED.off()
        ret["path"] = img_path
        ret["bucket"] = cam_info["bucket"]
        ret["index"] = cam_info["index"]
        ret["ts"] = cam_info["ts"]
    return ret


def _basic_parse_qs(raw_qs):
    qs_d = {}
    raw_qstrs = raw_qs.decode("utf-8").split("&")
    for qs in raw_qstrs:
        kv = qs.split("=")
        qs_d[kv[0]] = kv[1]
    return qs_d


class Status:
    url = "{}/{}".format(V1_BASE_PATH, "status")

    def get(self, data):
        mem = {
            "mem_alloc": gc.mem_alloc(),
            "mem_free": gc.mem_free(),
            "mem_total": gc.mem_alloc() + gc.mem_free(),
        }
        sta_if = network.WLAN(network.STA_IF)
        ifconfig = sta_if.ifconfig()
        net = {
            "ip": ifconfig[0],
            "netmask": ifconfig[1],
            "gateway": ifconfig[2],
            "dns": ifconfig[3],
        }
        return {"memory": mem, "network": net}, 200


def reset_machine():
    machine.reset()


@app.route(RESET_API_PATH)
async def reset(req, resp):
    msg = {"message": "reset"}
    resp.code = 200
    resp.add_header("Content-Type", "application/json")
    msg_json = json.dumps(msg)
    resp.add_header("Content-Length", len(msg_json))
    await resp._send_headers()
    await resp.send(msg_json)
    time.sleep(2)
    reset_machine()


@app.route(IMG_API_PATH)
async def images(req, resp):
    qs = req.query_string
    try:
        qs_d = _basic_parse_qs(qs)
    except Exception:
        # catch all exceptions
        qs_d = None
    if qs_d:
        try:
            ts = qs_d["ts"]
        except KeyError:
            ts = None
        try:
            index = qs_d["index"]
        except KeyError:
            index = None
        try:
            bucket = qs_d["bucket"]
        except KeyError:
            bucket = None
    else:
        ts = None
        index = None
        bucket = None

    if bucket is not None and index is not None and ts is not None:
        fp = IMG_PATH_TEMPLATE.format(bucket, index, ts)
        await resp.send_file(fp, content_type="image/jpeg")
    else:
        msg = {
            "message": "bucket ({}) index ({}) or ts ({}) missing: qs_d:{}".format(
                bucket, index, ts, qs_d
            )
        }
        resp.code = 400
        resp.add_header("Content-Type", "application/json")
        msg_json = json.dumps(msg)
        resp.add_header("Content-Length", len(msg_json))
        await resp._send_headers()
        await resp.send(msg_json)


logger.debug("add resource: {}".format(IMG_API_PATH))


@app.route(IMG_API_CAPTURE_PATH)
async def image_capture(req, resp):
    qs = req.query_string
    try:
        qs_d = _basic_parse_qs(qs)
    except Exception:
        # catch all exceptions
        qs_d = None
    if qs_d:
        try:
            ts = qs_d["ts"]
        except KeyError:
            ts = None
        try:
            index = qs_d["index"]
        except KeyError:
            index = None
        try:
            bucket = qs_d["bucket"]
        except KeyError:
            bucket = None
    else:
        ts = None
        index = None
        bucket = None

    cam_info = {}
    cam_info["bucket"] = bucket
    cam_info["index"] = index
    cam_info["ts"] = ts

    if bucket is not None and index is not None and ts is not None:
        ret = _write_image(cam_info)
        fp = ret["path"]
        await resp.send_file(fp, content_type="image/jpeg", max_age=0)
        try:
            f = open(fp, "r")
        except OSError:
            pass
            # TODO: handle
        else:
            f.close()
            uos.remove("{}".format(fp))

    else:
        msg = {
            "message": "bucket ({}) index ({}) or ts ({}) missing: qs_d:{}".format(
                bucket, index, ts, qs_d
            )
        }
        resp.code = 400
        resp.add_header("Content-Type", "application/json")
        msg_json = json.dumps(msg)
        resp.add_header("Content-Length", len(msg_json))
        await resp._send_headers()
        await resp.send(msg_json)


logger.debug("add resource: {}".format(IMG_API_CAPTURE_PATH))


def run():

    app.add_resource(Status, Status.url)
    logger.debug("add resource: {}".format(Status.url))

    logger.debug("calling app.run()")
    logger.to_file("app/resources/mylog.json")
    app.run()


def begin():
    print("hello from tinyweb")
    logger.debug("running as script")
    try:
        run()
    except Exception as e:
        run_logger.error("exception: {}".format(e))
