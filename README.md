# Bluetooth Daemon

Send and receive files via bluetooth

## Building and Installation

You'll need the following dependencies:
    libgranite-dev >= 6.0.0
    libgtk3-dev
    meson
    valac

Run `meson` to configure the build environment and then `ninja` to build

    meson setup build --prefix=/usr
    cd build
    ninja

To install, use `ninja install`

    ninja install
