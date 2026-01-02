# Enhanced Touchpad

Mac-like touchpad experience for Linux with advanced gesture control.

## Features

### 🖱️ Mac-like Cursor Acceleration
- Slow movements provide precise control
- Fast movements cover large distances
- Exponential acceleration curve for natural feel

### 📜 Strict 2-Finger Scroll
- Both fingers must move in the same direction to scroll
- Prevents accidental scrolling from finger positioning
- Natural and predictable scrolling behavior

## Installation

### Using Nix Flakes (Recommended)

Add this to your Home Manager configuration:

```nix
{
  inputs = {
    enhanced-touchpad.url = "github:ojii3/enhanced-touchpad";
  };

  outputs = { self, nixpkgs, home-manager, enhanced-touchpad, ... }: {
    homeConfigurations."user@hostname" = home-manager.lib.homeManagerConfiguration {
      modules = [
        enhanced-touchpad.homeManagerModules.default
        {
          programs.enhanced-touchpad = {
            enable = true;
            verbose = false;  # Set to true for debug logging
            # device = "/dev/input/event4";  # Optional: specify device path
          };
        }
      ];
    };
  };
}
```

### Manual Installation

```bash
# Clone the repository
git clone https://github.com/ojii3/enhanced-touchpad
cd enhanced-touchpad

# Build and run
nix run .
```

## Usage

### Command Line

```bash
# Auto-detect touchpad and run
enhanced-touchpad

# Enable verbose logging
enhanced-touchpad -v

# Specify device manually
enhanced-touchpad --device /dev/input/event4

# List available input devices
enhanced-touchpad --list-devices
```

### Systemd Service

The Home Manager module automatically sets up a systemd user service:

```bash
# Check status
systemctl --user status enhanced-touchpad

# Restart service
systemctl --user restart enhanced-touchpad

# View logs
journalctl --user -u enhanced-touchpad -f
```

## Configuration

The acceleration curve can be customized by modifying the parameters in `enhanced-touchpad.py`:

```python
# Acceleration curve parameters (Mac-like)
self.accel_base = 1.0           # Base multiplier
self.accel_sensitivity = 0.015  # How much speed affects acceleration
self.accel_exponent = 1.6       # Exponential curve (higher = more aggressive)
```

- **More acceleration**: Increase `accel_sensitivity` (e.g., 0.020)
- **Less acceleration**: Decrease `accel_sensitivity` (e.g., 0.010)
- **Different curve**: Adjust `accel_exponent` (1.0 = linear, 2.0 = quadratic)

## Development

### Setup Development Environment

```bash
# Enter the project directory
cd enhanced-touchpad

# Allow direnv (first time only)
direnv allow

# The development environment will be automatically loaded
```

### Running in Development

```bash
# Run directly with Python
python enhanced-touchpad.py -v

# Or use Nix
nix run . -- -v
```

### Building

```bash
# Build the package
nix build

# Run the built package
./result/bin/enhanced-touchpad
```

## Requirements

- Linux kernel with evdev support
- Multi-touch touchpad
- User must be in the `input` group for device access

Add your user to the `input` group:

```nix
# In your NixOS configuration
users.users.<username>.extraGroups = [ "input" ];
```

## How It Works

1. **Device Grabbing**: The daemon grabs the touchpad device to intercept all events
2. **Event Processing**: Raw touch events are processed to detect gestures
3. **Gesture Recognition**: Distinguishes between 1-finger (cursor) and 2-finger (scroll) gestures
4. **Transformation**: Applies acceleration curves and filters
5. **Virtual Device**: Sends transformed events to a virtual input device

## Troubleshooting

### Permission Denied

Ensure your user is in the `input` group:

```bash
groups  # Check if 'input' is listed
```

### Device Not Found

List available devices to find your touchpad:

```bash
enhanced-touchpad --list-devices
```

Then specify it manually:

```bash
enhanced-touchpad --device /dev/input/eventX
```

### Service Won't Start

Check the logs:

```bash
journalctl --user -u enhanced-touchpad -n 50
```

## License

MIT

## Author

ojii3
