/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2016-2025 elementary, Inc. (https://elementary.io)
 *
 * Authored by: Corentin Noël <corentin@elementary.io>
 *              Torikulhabib <torik.habib@gamail.com>
 */

public class DeviceRow : Gtk.ListBoxRow {
    public signal void send_file (Bluetooth.Device device);

    public Bluetooth.Device device { get; construct; }
    public unowned Bluetooth.Adapter adapter { get; construct; }

    private static Gtk.SizeGroup size_group;
    private Gtk.Button send_button;
    private Gtk.Image state;

    public DeviceRow (Bluetooth.Device device, Bluetooth.Adapter adapter) {
        Object (
            device: device,
            adapter: adapter
        );
    }

    static construct {
        size_group = new Gtk.SizeGroup (HORIZONTAL);
    }

    construct {
        var image = new Gtk.Image.from_icon_name (device.icon ?? "bluetooth", DND);

        state = new Gtk.Image.from_icon_name ("emblem-disabled", MENU) {
            halign = END,
            valign = END
        };

        var state_label = new Gtk.Label (null) {
            xalign = 0
        };
        state_label.get_style_context ().add_class (Granite.STYLE_CLASS_SMALL_LABEL);

        var overlay = new Gtk.Overlay () {
            child = image,
            tooltip_text = device.address
        };
        overlay.add_overlay (state);

        string? device_name = device.alias;
        if (device_name == null) {
            if (device.icon != null) {
                device_name = device_icon ();
            } else {
                device_name = device.address;
            }
        }

        var label = new Gtk.Label (device_name) {
            ellipsize = END,
            hexpand = true,
            xalign = 0
        };

        send_button = new Gtk.Button () {
            valign = CENTER,
            label = _("Send")
        };

        size_group.add_widget (send_button);

        var grid = new Gtk.Grid () {
            margin = 6,
            column_spacing = 6
        };
        grid.attach (overlay, 0, 0, 1, 2);
        grid.attach (label, 1, 0);
        grid.attach (state_label, 1, 1);
        grid.attach (send_button, 4, 0, 1, 2);

        child = grid;
        show_all ();

        set_sensitive (adapter.powered);
        set_status (device.connected);

        ((DBusProxy)adapter).g_properties_changed.connect ((changed, invalid) => {
            var powered = changed.lookup_value ("Powered", new VariantType ("b"));
            if (powered != null) {
                set_sensitive (adapter.powered);
            }
        });

        ((DBusProxy)device).g_properties_changed.connect ((changed, invalid) => {
            var connected = changed.lookup_value ("Connected", new VariantType ("b"));
            if (connected != null) {
                set_status (device.connected);
            }

            var name = changed.lookup_value ("Name", new VariantType ("s"));
            if (name != null) {
                label.label = device.alias;
            }

            var icon = changed.lookup_value ("Icon", new VariantType ("s"));
            if (icon != null) {
                image.icon_name = device.icon ?? "bluetooth";
            }
        });

        state_label.label = device_icon ();

        send_button.clicked.connect (() => {
            send_file (device);
            get_toplevel ().destroy ();
        });
    }

    private string device_icon () {
        switch (device.icon) {
            case "audio-card":
                return _("Speaker");
            case "input-gaming":
                return _("Controller");
            case "input-keyboard":
                return _("Keyboard");
            case "input-mouse":
                return _("Mouse");
            case "input-tablet":
                return _("Tablet");
            case "input-touchpad":
                return _("Touchpad");
            case "phone":
                return _("Phone");
            default:
                return device.address;
        }
    }

    private void set_status (bool status) {
        state.icon_name = status? "emblem-enabled" : "emblem-disabled";
    }
}
