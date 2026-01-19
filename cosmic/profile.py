import os
import yaml
from pathlib import Path

PROFILE_PATH = Path.home() / ".cosmic_profile.yaml"

def get_defaults():
    return {
        'effect': 'standard',
        'led_colors': [[255, 0, 0]] * 8,
        'dpi_values': [1000, 1600, 2400, 4800, 9600, 12600],
        'active_dpi': 2,
        'dpi_colors': [[255, 0, 0], [255, 128, 0], [255, 255, 0], [0, 255, 0], [0, 255, 255], [0, 0, 255]]
    }

def normalize_color(color):
    if isinstance(color, dict):
        return [int(color['r']), int(color['g']), int(color['b'])]
    else:
        return [int(c) for c in color]

def load():
    if not PROFILE_PATH.exists():
        return get_defaults()

    with open(PROFILE_PATH, 'r') as f:
        profile = yaml.safe_load(f)

    profile['active_dpi'] = int(profile['active_dpi'])
    profile['dpi_values'] = [int(v) for v in profile['dpi_values']]
    profile['led_colors'] = [normalize_color(c) for c in profile['led_colors']]
    profile['dpi_colors'] = [normalize_color(c) for c in profile['dpi_colors']]

    return profile

def save(profile):
    with open(PROFILE_PATH, 'w') as f:
        yaml.dump(profile, f, default_flow_style=False)

def update(key, value):
    profile = load()
    profile[key] = value
    save(profile)
    return profile
