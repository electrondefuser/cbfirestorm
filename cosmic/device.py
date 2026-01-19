import usb.core
import time
from .config import VENDOR_ID, PRODUCT_ID, EFFECTS, ACTIVE_DPI

def send_config(profile):
    colors          = profile['led_colors']
    dpi             = profile['dpi_values']
    active          = profile['active_dpi']
    effect          = profile['effect']
    per_dpi_colors  = profile['dpi_colors']

    color_data = bytearray(32)
    for i, (r, g, b) in enumerate(colors):
        color_data[i*3:i*3+3] = [r, g, b]

    dpi_color_data = bytearray(32)
    for i, (r, g, b) in enumerate(per_dpi_colors):
        dpi_color_data[i*3:i*3+3] = [r, g, b]

    dpi_data = bytearray(32)
    for i, d in enumerate(dpi):
        dpi_data[i] = d // 100
    dpi_data[6:8] = [0x63, 0x68]

    dev = usb.core.find(idVendor=VENDOR_ID, idProduct=PRODUCT_ID)
    if not dev:
        raise RuntimeError("Mouse not found")

    cmds = [
        ("2727d5ffec0d9e76", "252dadffe8120eee", "272bd5fff0059e76", "272bddfff0fd9e76", ACTIVE_DPI[active], "272b9504a0159e76", EFFECTS[effect], "272a8dffe8759e36"),
        ("272a85fff0759e36", "272bf5ffd87d9eb6", "272d55fff085a076", "272d2dfff885a076","272bf5ff00759ed6", "272c6d02383ab4d6")
    ]
    intr = [
        "ff000000ff000000ffffff00ff00ff00ffffff8000ffffff0000000000000000",
        "0100f0000100f1000100f2000100f4000100f300070003000b0000000af02103",
        "0b0000000b000000000000000000000000000000000000000400010004000200",
        "00" * 32, "00" * 32, "ff" + "00" * 31
    ]

    for c in cmds[0]:
        dev.ctrl_transfer(0x21, 0x09, 0x0300, 2, bytes.fromhex(c), 500)
        time.sleep(0.02)

    dev.write(0x03, color_data, 500)
    time.sleep(0.02)

    dev.ctrl_transfer(0x21, 0x09, 0x0300, 2, bytes.fromhex(cmds[1][0]), 500)
    time.sleep(0.02)

    dev.write(0x03, dpi_color_data, 500)
    time.sleep(0.02)

    dev.ctrl_transfer(0x21, 0x09, 0x0300, 2, bytes.fromhex(cmds[1][1]), 500)
    time.sleep(0.02)

    dev.write(0x03, dpi_data, 500)
    time.sleep(0.02)

    dev.ctrl_transfer(0x21, 0x09, 0x0300, 2, bytes.fromhex(cmds[1][2]), 500)
    time.sleep(0.02)

    for i in intr[:3]:
        dev.write(0x03, bytes.fromhex(i.replace(' ', '')), 500)
        time.sleep(0.02)

    dev.ctrl_transfer(0x21, 0x09, 0x0300, 2, bytes.fromhex(cmds[1][3]), 500)
    time.sleep(0.02)

    for i in intr[3:5]:
        dev.write(0x03, bytes(32), 500)
        time.sleep(0.02)

    dev.ctrl_transfer(0x21, 0x09, 0x0300, 2, bytes.fromhex(cmds[1][4]), 500)
    time.sleep(0.02)

    dev.write(0x03, bytes.fromhex(intr[5]), 500)
    time.sleep(0.02)

    dev.ctrl_transfer(0x21, 0x09, 0x0300, 2, bytes.fromhex(cmds[1][5]), 500)
