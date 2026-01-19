import sys
import argparse
from .commands import rgb, dpi, profile

def parse_colors(args, count):
    colors = []
    for arg in args:
        parts = arg.split(',')
        if len(parts) != 3:
            raise ValueError(f"Invalid color: {arg}. Use R,G,B")
        r, g, b = map(int, parts)
        if not (0 <= r <= 255 and 0 <= g <= 255 and 0 <= b <= 255):
            raise ValueError(f"RGB must be 0-255: {arg}")
        colors.append([r, g, b])
    if len(colors) != count:
        raise ValueError(f"Need {count} colors, got {len(colors)}")
    return colors

def main():
    parser = argparse.ArgumentParser(description='Cosmic Byte Firestorm Controller')
    subparsers = parser.add_subparsers(dest='command', help='Command category')

    rgb_parser = subparsers.add_parser('rgb', help='RGB LED control')
    rgb_sub = rgb_parser.add_subparsers(dest='rgb_command')

    rgb_effect = rgb_sub.add_parser('set-effect', help='Set LED effect')
    rgb_effect.add_argument('effect', help='Effect name')

    rgb_colors = rgb_sub.add_parser('set-colors', help='Set LED colors')
    rgb_colors_group = rgb_colors.add_mutually_exclusive_group(required=True)
    rgb_colors_group.add_argument('--profile', help='Color profile')
    rgb_colors_group.add_argument('--colors', nargs=8, metavar='R,G,B', help='8 RGB values')

    rgb_sub.add_parser('list', help='List effects and profiles')

    dpi_parser = subparsers.add_parser('dpi', help='DPI control')
    dpi_sub = dpi_parser.add_subparsers(dest='dpi_command')

    dpi_mode = dpi_sub.add_parser('set-mode', help='Set active DPI level')
    dpi_mode.add_argument('level', type=int, help='DPI level (1-6)')

    dpi_values = dpi_sub.add_parser('set-values', help='Set DPI values')
    dpi_values.add_argument('values', type=int, nargs=6, metavar='DPI', help='6 DPI values')
    dpi_values.add_argument('--active', type=int, help='Set active level')

    dpi_colors = dpi_sub.add_parser('set-colors', help='Set per-DPI colors')
    dpi_colors_group = dpi_colors.add_mutually_exclusive_group(required=True)
    dpi_colors_group.add_argument('--profile', help='DPI color profile')
    dpi_colors_group.add_argument('--colors', nargs=6, metavar='R,G,B', help='6 RGB values')

    dpi_sub.add_parser('list', help='List DPI color profiles')

    prof_parser = subparsers.add_parser('profile', help='Profile management')
    prof_sub = prof_parser.add_subparsers(dest='profile_command')
    prof_sub.add_parser('show', help='Show current profile')
    prof_sub.add_parser('apply', help='Apply profile to device')
    prof_sub.add_parser('reset', help='Reset profile to defaults')

    args = parser.parse_args()

    if not args.command:
        parser.print_help()
        return 1

    try:
        if args.command == 'rgb':
            if args.rgb_command == 'set-effect':
                rgb.set_effect(args.effect)
            elif args.rgb_command == 'set-colors':
                if args.profile:
                    rgb.set_colors(profile_name=args.profile)
                else:
                    colors = parse_colors(args.colors, 8)
                    rgb.set_colors(custom_colors=colors)
            elif args.rgb_command == 'list':
                rgb.list_options()
            else:
                rgb_parser.print_help()
                return 1

        elif args.command == 'dpi':
            if args.dpi_command == 'set-mode':
                dpi.set_mode(args.level)
            elif args.dpi_command == 'set-values':
                dpi.set_values(args.values, args.active)
            elif args.dpi_command == 'set-colors':
                if args.profile:
                    dpi.set_colors(profile_name=args.profile)
                else:
                    colors = parse_colors(args.colors, 6)
                    dpi.set_colors(custom_colors=colors)
            elif args.dpi_command == 'list':
                dpi.list_options()
            else:
                dpi_parser.print_help()
                return 1

        elif args.command == 'profile':
            if args.profile_command == 'show':
                profile.show()
            elif args.profile_command == 'apply':
                profile.apply()
            elif args.profile_command == 'reset':
                profile.reset()
            else:
                prof_parser.print_help()
                return 1

    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        return 1

    return 0

if __name__ == '__main__':
    sys.exit(main())
