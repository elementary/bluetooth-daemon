/*
 * SPDX-License-Identifier: LGPL-3.0-or-later
 * SPDX-FileCopyrightText: 2016-2024 elementary, Inc. (https://elementary.io)
 *
 * Authored by: Corentin Noël <corentin@elementary.io>
 *              Oleksandr Lynok <oleksandr.lynok@gmail.com>
 *              Torikulhabib <torik.habib@gamail.com>
 */

public class BtScan : Granite.MessageDialog {
    public signal void send_file (Bluetooth.Device device);

    public Bluetooth.ObjectManager manager { get; construct;}

    private Gtk.ListBox list_box;

    public BtScan (Bluetooth.ObjectManager manager) {
        Object (manager: manager);
    }

    construct {
        image_icon = new ThemedIcon ("bluetooth");
        primary_text = _("Bluetooth File Transfer");
        secondary_text = _("Select a Bluetooth Device Below to Send Files");
        resizable = true;

        var placeholder = new Granite.Widgets.AlertView (
            _("No Devices Found"),
            _("Please ensure that your devices are visible and ready for pairing."),
            ""
        );
        placeholder.show_all ();

        list_box = new Gtk.ListBox () {
            activate_on_single_click = true,
            selection_mode = BROWSE
        };
        list_box.set_sort_func ((Gtk.ListBoxSortFunc) compare_rows);
        list_box.set_placeholder (placeholder);

        var scrolled = new Gtk.ScrolledWindow (null, null) {
            hexpand = true,
            vexpand = true,
            child = list_box,
            hscrollbar_policy = NEVER,
            propagate_natural_height = true,
            max_content_height = 350
        };
        scrolled.get_style_context ().add_class (Gtk.STYLE_CLASS_FRAME);

        var overlay = new Gtk.Overlay () {
            child = scrolled
        };

        var overlaybar = new Granite.Widgets.OverlayBar (overlay) {
            label = _("Discovering")
        };

        custom_bin.add (overlay);

        manager.device_added.connect (add_device);
        manager.device_removed.connect (device_removed);
        manager.status_discovering.connect (() => {
            overlaybar.active = manager.check_discovering ();
        });

        add_button (_("Close"), Gtk.ResponseType.CLOSE);

        response.connect ((response_id) => {
            manager.stop_discovery.begin ();
            destroy ();
        });
    }

    public override void show () {
        base.show ();
        var devices = manager.get_devices ();
        foreach (var device in devices) {
            add_device (device);
        }
        manager.start_discovery.begin ();
    }

    private void add_device (Bluetooth.Device device) {
        bool device_exist = false;
        foreach (var row in list_box.get_children ()) {
            if (((DeviceRow) row).device == device) {
                device_exist = true;
            }
        }
        if (device_exist) {
            return;
        }
        var row = new DeviceRow (device, manager.get_adapter_from_path (device.adapter));
        list_box.add (row);
        if (list_box.get_selected_row () == null) {
            list_box.select_row (row);
            list_box.row_activated (row);
        }
        row.send_file.connect ((device)=> {
            manager.stop_discovery.begin ();
            send_file (device);
        });
    }

    public void device_removed (Bluetooth.Device device) {
        foreach (var row in list_box.get_children ()) {
            if (((DeviceRow) row).device == device) {
                list_box.remove (row);
                break;
            }
        }
    }

    [CCode (instance_pos = -1)]
    private int compare_rows (DeviceRow row1, DeviceRow row2) {
        unowned Bluetooth.Device device1 = row1.device;
        unowned Bluetooth.Device device2 = row2.device;
        if (device1.paired && !device2.paired) {
            return -1;
        }

        if (!device1.paired && device2.paired) {
            return 1;
        }

        if (device1.connected && !device2.connected) {
            return -1;
        }

        if (!device1.connected && device2.connected) {
            return 1;
        }

        if (device1.name != null && device2.name == null) {
            return -1;
        }

        if (device1.name == null && device2.name != null) {
            return 1;
        }

        var name1 = device1.name ?? device1.address;
        var name2 = device2.name ?? device2.address;
        return name1.collate (name2);
    }
}
