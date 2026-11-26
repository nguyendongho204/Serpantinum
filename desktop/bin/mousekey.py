#!/usr/bin/env python3
"""Gui phim Ctrl+C / Ctrl+V qua uinput (cho nut phu chuot).

Dung: mousekey.py copy|paste
"""
import fcntl
import os
import struct
import sys
import time

UI_DEV_CREATE = 0x5501
UI_DEV_DESTROY = 0x5502
UI_DEV_SETUP = 0x405c5503
UI_SET_EVBIT = 0x40045564
UI_SET_KEYBIT = 0x40045565

EV_SYN, EV_KEY = 0x00, 0x01
KEY_LEFTCTRL = 29
KEY_C = 46
KEY_V = 47

ACTIONS = {"copy": KEY_C, "paste": KEY_V}


def main():
    action = sys.argv[1] if len(sys.argv) > 1 else "copy"
    keycode = ACTIONS.get(action)
    if keycode is None:
        print(f"unknown action: {action}", file=sys.stderr)
        return 2

    fd = os.open("/dev/uinput", os.O_WRONLY | os.O_NONBLOCK)
    try:
        for ev in (EV_KEY, EV_SYN):
            fcntl.ioctl(fd, UI_SET_EVBIT, ev)
        for code in (KEY_LEFTCTRL, keycode):
            fcntl.ioctl(fd, UI_SET_KEYBIT, code)
        fcntl.ioctl(fd, UI_DEV_SETUP,
                    struct.pack("HHHH80sI", 3, 0x1209, 0x0020, 1, b"zb-mousekey", 0))
        fcntl.ioctl(fd, UI_DEV_CREATE)
        time.sleep(0.12)

        def emit(etype, code, value):
            os.write(fd, struct.pack("llHHi", 0, 0, etype, code, value))
            os.write(fd, struct.pack("llHHi", 0, 0, EV_SYN, 0, 0))

        emit(EV_KEY, KEY_LEFTCTRL, 1)
        emit(EV_KEY, keycode, 1)
        emit(EV_KEY, keycode, 0)
        emit(EV_KEY, KEY_LEFTCTRL, 0)
        time.sleep(0.08)
    finally:
        try:
            fcntl.ioctl(fd, UI_DEV_DESTROY)
        except Exception:
            pass
        os.close(fd)
    return 0


if __name__ == "__main__":
    sys.exit(main())
