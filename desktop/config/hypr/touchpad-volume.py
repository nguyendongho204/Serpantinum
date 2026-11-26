#!/usr/bin/env python3
"""Vuốt 3 ngón trên touchpad để tăng/giảm âm lượng LIÊN TỤC.

Khác với libinput-gestures (chỉ chạy lệnh 1 lần khi kết thúc vuốt), script này
đọc dx/dy TỪNG FRAME từ `libinput debug-events` nên âm lượng đổi theo quãng
đường vuốt: vuốt xa/nhanh = đổi nhiều, vuốt ngắn/chậm = đổi ít.

Cấu hình: sửa các hằng bên dưới.
"""

from __future__ import annotations

import argparse
import os
import re
import subprocess
import sys
import time

PX_PER_STEP = 10.0        # px vuốt dọc tương ứng 1% âm lượng
FLUSH_INTERVAL = 0.03     # giây tối thiểu giữa 2 lần gọi wpctl
DIRECTION_LOCK_PX = 15.0  # px để chốt hướng, tránh lẫn với vuốt ngang (chuyển workspace)

# libinput: dy ÂM = ngón vuốt LÊN màn hình. Đảo thành -1 nếu chiều ngược lại.
UP_DY_SIGN = int(os.environ.get("TOUCHPAD_VOL_UP_SIGN", "-1"))

RE_BEGIN = re.compile(r"GESTURE_SWIPE_BEGIN\s+\S+\s+(\d+)\s*$")
# Format thật (libinput 1.32):
#   GESTURE_SWIPE_UPDATE [seq] <timestamp><TAB><ngón>  <dx>/<dy> ( <dx>/<dy> unaccelerated)
# Không có chữ "dx"/"dy" — chỉ là cặp X/Y, cách nhau bằng TAB và /
# Số dương bị thụt lùi nên sau / có space: "5.67/ 0.57" vs "0.00/-5.47"
RE_UPDATE = re.compile(
    r"GESTURE_SWIPE_UPDATE\s+(?:\d+\s+)?\S+\s+(\d+)\s+([-+]?[\d.]+)\s*/\s*([-+]?[\d.]+)"
)
RE_END = re.compile(r"GESTURE_SWIPE_END\s+\S+\s+(\d+)\s*$")


def log(msg: str) -> None:
    print(f"touchpad-volume: {msg}", file=sys.stderr, flush=True)


class Volume:
    """Tích lũy số bước âm lượng và gọi wpctl theo nhịp, không gọi liên tục."""

    def __init__(self, dry_run: bool = False) -> None:
        self.pending = 0
        self.last_flush = time.monotonic()
        self.dry_run = dry_run

    def add(self, steps: int) -> None:
        self.pending += steps

    def flush(self, force: bool = False) -> None:
        if self.pending == 0:
            return
        now = time.monotonic()
        if not force and now - self.last_flush < FLUSH_INTERVAL:
            return

        n, self.pending = self.pending, 0
        self.last_flush = now

        if self.dry_run:
            log(f"[dry-run] âm lượng {n:+d}%")
            return

        cmd = ["wpctl", "set-volume"]
        if n > 0:
            cmd += ["-l", "1.0"]
        cmd += ["@DEFAULT_AUDIO_SINK@", f"{abs(n)}%{'+' if n > 0 else '-'}"]
        try:
            subprocess.run(cmd, check=False, capture_output=True, timeout=2)
        except Exception as exc:  # noqa: BLE001
            log(f"lỗi gọi wpctl: {exc}")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--debug", action="store_true", help="in mọi dòng libinput ra stderr")
    parser.add_argument("--dry-run", action="store_true", help="chỉ log, không đổi âm lượng")
    args = parser.parse_args()

    vol = Volume(dry_run=args.dry_run)
    gesture: dict | None = None

    try:
        proc = subprocess.Popen(
            ["stdbuf", "-oL", "libinput", "debug-events"],
            stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL,
            text=True,
            bufsize=1,
        )
    except FileNotFoundError as exc:
        log(f"không chạy được: {exc}")
        return 1

    log(f"bắt đầu (PX_PER_STEP={PX_PER_STEP}, UP_DY_SIGN={UP_DY_SIGN})")

    try:
        assert proc.stdout is not None
        for raw in proc.stdout:
            line = raw.rstrip("\n")
            if args.debug:
                print(f"< {line}", file=sys.stderr, flush=True)

            match = RE_BEGIN.search(line)
            if match:
                vol.flush(force=True)
                if int(match.group(1)) == 3:
                    gesture = {"mode": None, "dx": 0.0, "dy": 0.0, "acc": 0.0, "n": 0}
                    log("BEGIN 3 ngón")
                else:
                    gesture = None
                continue

            if "GESTURE_SWIPE_UPDATE" in line:
                match = RE_UPDATE.search(line)
                if match is None:
                    log(f"UPDATE không parse được: {line!r}")
                    continue
                if gesture is None or int(match.group(1)) != 3:
                    continue
                dx, dy = float(match.group(2)), float(match.group(3))
                gesture["n"] += 1
                gesture["dx"] += dx
                gesture["dy"] += dy

                if gesture["mode"] is None:
                    if max(abs(gesture["dx"]), abs(gesture["dy"])) >= DIRECTION_LOCK_PX:
                        gesture["mode"] = "v" if abs(gesture["dy"]) > abs(gesture["dx"]) else "h"
                        log(
                            f"chốt hướng: {'dọc' if gesture['mode'] == 'v' else 'ngang'} "
                            f"(dx={gesture['dx']:+.1f} dy={gesture['dy']:+.1f})"
                        )

                if gesture["mode"] != "v":
                    continue

                gesture["acc"] += UP_DY_SIGN * dy
                while gesture["acc"] >= PX_PER_STEP:
                    vol.add(1)
                    gesture["acc"] -= PX_PER_STEP
                while gesture["acc"] <= -PX_PER_STEP:
                    vol.add(-1)
                    gesture["acc"] += PX_PER_STEP
                vol.flush()
                continue

            match = RE_END.search(line)
            if match:
                if gesture is not None:
                    log(
                        f"END n={gesture['n']} dx={gesture['dx']:+.1f} "
                        f"dy={gesture['dy']:+.1f} mode={gesture['mode']}"
                    )
                gesture = None
                vol.flush(force=True)
    except KeyboardInterrupt:
        log("dừng theo yêu cầu")
        return 0
    finally:
        vol.flush(force=True)
        proc.terminate()
        try:
            proc.wait(timeout=2)
        except subprocess.TimeoutExpired:
            proc.kill()

    log("libinput kết thúc — thoát với mã 1 để systemd khởi động lại")
    return 1


if __name__ == "__main__":
    sys.exit(main())
