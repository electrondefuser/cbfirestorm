from ..config import EFFECTS, COLOR_PROFILES
from ..profile import load, update
from ..device import send_config

def set_effect(effect):
    if effect not in EFFECTS:
        raise ValueError(f"Unknown effect: {effect}")

    profile = update('effect', effect)
    send_config(profile)
    print(f"[*] Effect set to: {effect}")

def set_colors(profile_name=None, custom_colors=None):
    if profile_name:
        if profile_name not in COLOR_PROFILES:
            raise ValueError(f"Unknown color profile: {profile_name}")
        colors = COLOR_PROFILES[profile_name]
        msg = f"[*] Colors set to profile: {profile_name}"
    else:
        colors = custom_colors
        msg = "[*] Custom colors set"

    profile = update('led_colors', colors)
    send_config(profile)
    print(msg)

def list_options():
    print("\nEffects:")
    for effect in sorted(EFFECTS.keys()):
        print(f"  {effect}")

    print("\nColor Profiles:")
    for prof in sorted(COLOR_PROFILES.keys()):
        print(f"  {prof}")
