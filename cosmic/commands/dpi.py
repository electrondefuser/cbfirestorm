from ..config import DPI_COLOR_PROFILES
from ..profile import load, save
from ..device import send_config

def set_mode(level):
    if level < 1 or level > 6:
        raise ValueError(f"DPI level must be 1-6, got {level}")

    profile = load()
    profile['active_dpi'] = level
    save(profile)
    send_config(profile)
    print(f"[*] Active DPI set to level: {level}")

def set_values(values, active_level=None):
    if len(values) != 6:
        raise ValueError(f"Need 6 DPI values, got {len(values)}")

    for i, dpi in enumerate(values):
        if dpi < 100 or dpi > 25600 or dpi % 100 != 0:
            raise ValueError(f"DPI value {dpi} at position {i+1} invalid")

    profile = load()
    profile['dpi_values'] = values
    if active_level:
        if active_level < 1 or active_level > 6:
            raise ValueError(f"Active level must be 1-6, got {active_level}")
        profile['active_dpi'] = active_level

    save(profile)
    send_config(profile)
    print(f" [*] DPI values set: {values}")
    if active_level:
        print(f"  Active level: {active_level} ({values[active_level-1]} DPI)")

def set_colors(profile_name=None, custom_colors=None):
    if profile_name:
        if profile_name not in DPI_COLOR_PROFILES:
            raise ValueError(f"Unknown DPI color profile: {profile_name}")
        colors = DPI_COLOR_PROFILES[profile_name]
        msg = f"[*] DPI colors set to profile: {profile_name}"
    else:
        colors = custom_colors
        msg = "[*] Custom DPI colors set"

    profile = load()
    profile['dpi_colors'] = colors
    save(profile)
    send_config(profile)
    print(msg)

def list_options():
    print("\nDPI Color Profiles:")
    for prof in sorted(DPI_COLOR_PROFILES.keys()):
        print(f"  {prof}")
