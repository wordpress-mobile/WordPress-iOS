#!/usr/bin/env python3
"""
Interactive menu for evaluation script
"""
import sys
import os

def is_interactive():
    """Check if stdin is connected to a terminal"""
    return sys.stdin.isatty() and sys.stdout.isatty()

def show_menu(options, title="What would you like to do?"):
    """Show an interactive menu and return selected option"""
    # If not running interactively, return "Nothing" to skip menu
    if not is_interactive():
        return "Nothing"

    print(f"\n{title}\n")

    for i, option in enumerate(options, 1):
        print(f"  {i}. {option}")

    print()

    while True:
        try:
            choice = input(f"Select option (1-{len(options)}): ")
            idx = int(choice) - 1
            if 0 <= idx < len(options):
                return options[idx]
            print(f"Invalid option. Please enter 1-{len(options)}")
        except ValueError:
            print(f"Invalid input. Please enter a number 1-{len(options)}")
        except KeyboardInterrupt:
            print("\n\nCancelled")
            return "Nothing"
        except EOFError:
            print("\n\nCancelled")
            return "Nothing"

if __name__ == "__main__":
    # Read options from command line args
    options = sys.argv[1:]
    if not options:
        print("Error: No options provided", file=sys.stderr)
        sys.exit(1)

    selected = show_menu(options)
    print(selected)
