import usb.core
import usb.util
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

    try:
        # Setup commands (before color data)
        dev.ctrl_transfer(0x21, 0x09, 0x0300, 2, bytes.fromhex("2727d5ffec0d9e76"), 500)
        time.sleep(0.02)

        dev.ctrl_transfer(0x21, 0x09, 0x0300, 2, bytes.fromhex("252dadffe8120eee"), 500)
        time.sleep(0.02)

        dev.ctrl_transfer(0x21, 0x09, 0x0300, 2, bytes.fromhex("272bd5fff0059e76"), 500)
        time.sleep(0.02)

        dev.ctrl_transfer(0x21, 0x09, 0x0300, 2, bytes.fromhex("272bddfff0fd9e76"), 500)
        time.sleep(0.02)

        # Active DPI
        dev.ctrl_transfer(0x21, 0x09, 0x0300, 2, bytes.fromhex(ACTIVE_DPI[active]), 500)
        time.sleep(0.02)

        dev.ctrl_transfer(0x21, 0x09, 0x0300, 2, bytes.fromhex("272b9504a0159e76"), 500)
        time.sleep(0.02)

        # Effect
        dev.ctrl_transfer(0x21, 0x09, 0x0300, 2, bytes.fromhex(EFFECTS[effect]), 500)
        time.sleep(0.02)

        # Prepare for color data
        dev.ctrl_transfer(0x21, 0x09, 0x0300, 2, bytes.fromhex("272a8dffe8759e36"), 500)
        time.sleep(0.02)

        # COLOR DATA
        dev.write(0x03, color_data, 500)
        time.sleep(0.02)

        # CRITICAL: After color data, commands must ALTERNATE ctrl/intr properly!

        # Confirm colors
        dev.ctrl_transfer(0x21, 0x09, 0x0300, 2, bytes.fromhex("272a85fff0759e36"), 500)
        time.sleep(0.02)

        # DPI indicator colors
        dev.write(0x03, dpi_color_data, 500)
        time.sleep(0.02)

        # Setup for DPI
        dev.ctrl_transfer(0x21, 0x09, 0x0300, 2, bytes.fromhex("272bf5ffd87d9eb6"), 500)
        time.sleep(0.02)

        # DPI data
        dev.write(0x03, dpi_data, 500)
        time.sleep(0.02)

        # Continue
        dev.ctrl_transfer(0x21, 0x09, 0x0300, 2, bytes.fromhex("272d55fff085a076"), 500)
        time.sleep(0.02)

        # Two more interrupt packets
        dev.write(0x03, bytes.fromhex("0100f0000100f1000100f2000100f4000100f300070003000b0000000af02103"), 500)
        time.sleep(0.02)

        dev.write(0x03, bytes.fromhex("0b0000000b000000000000000000000000000000000000000400010004000200"), 500)
        time.sleep(0.02)

        # Continue
        dev.ctrl_transfer(0x21, 0x09, 0x0300, 2, bytes.fromhex("272d2dfff885a076"), 500)
        time.sleep(0.02)

        # Two zero packets
        dev.write(0x03, bytes(32), 500)
        time.sleep(0.02)

        dev.write(0x03, bytes(32), 500)
        time.sleep(0.02)

        # Continue
        dev.ctrl_transfer(0x21, 0x09, 0x0300, 2, bytes.fromhex("272bf5ff00759ed6"), 500)
        time.sleep(0.02)

        # Final interrupt
        dev.write(0x03, bytes.fromhex("ff00000000000000000000000000000000000000000000000000000000000000"), 500)
        time.sleep(0.02)

        # Finalization
        dev.ctrl_transfer(0x21, 0x09, 0x0300, 2, bytes.fromhex("272c6d02383ab4d6"), 500)
        time.sleep(0.05)

    finally:
        # Release resources
        try:
            usb.util.dispose_resources(dev)
        except:
            pass
