#!/usr/bin/env python3

import evdev
import asyncio
import time
from subprocess import check_output

arkos_joypad = evdev.InputDevice("/dev/input/event2")

class Joypad:
    l1 = 310
    r1 = 311

    up = 544
    down = 545
    left = 546
    right = 547

    f2 = 706
    f3 = 705
    f1 = 704

def runcmd(cmd, *args, **kw):
    print(f">>> {cmd}")
    check_output(cmd, *args, **kw)

async def handle_event(device):
    async for event in device.async_read_loop():
        if device.name == "OpenSimHardware OSH PB Controller" or device.name == "GO-Super Gamepad":
            keys = arkos_joypad.active_keys()
            if Joypad.f1 in keys:
                if event.code == Joypad.f3:
                    runcmd("pkill GameTankEmulato", shell=True)
                    exit

def run():
    asyncio.ensure_future(handle_event(arkos_joypad))

    loop = asyncio.get_event_loop()
    loop.run_forever()

if __name__ == "__main__": # admire
    run()

