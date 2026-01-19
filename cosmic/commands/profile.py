from ..profile import load, save, get_defaults, PROFILE_PATH
from ..device import send_config

def show():
    profile = load()
    print(f"\nCurrent Profile ({PROFILE_PATH}):")
    print(f"  Effect: {profile['effect']}")
    print(f"  LED Colors: {len(profile['led_colors'])} colors")
    print(f"  DPI Values: {profile['dpi_values']}")
    print(f"  Active DPI: {profile['active_dpi']} ({profile['dpi_values'][profile['active_dpi']-1]} DPI)")
    print(f"  DPI Colors: {len(profile['dpi_colors'])} colors")

def apply():
    profile = load()
    send_config(profile)
    print("[*] Profile applied to device")

def reset():
    profile = get_defaults()
    save(profile)
    print("[*] Profile reset to defaults")
