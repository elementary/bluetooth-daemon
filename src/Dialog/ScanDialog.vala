/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2016-2025 elementary, Inc. (https://elementary.io)
 *
 * Authored by: Corentin Noël <corentin@elementary.io>
 *              Oleksandr Lynok <oleksandr.lynok@gmail.com>
 *              Torikulhabib <torik.habib@gamail.com>
 */

public class ScanDialog : Granite.Dialog {
    public signal void send_file (Bluetooth.Device device);

    public Bluetooth.ObjectManager manager { get; construct; }

    private Gtk.ListBox list_box;

    public ScanDialog (Gtk.Application application, Bluetooth.ObjectManager manager) {
        Object (
            application: application,
            manager: manager,
            resizable: false
        );
    }

    construct {
        var icon_image = new Gtk.Image.from_icon_name ("io.elementary.bluetooth", Gtk.IconSize.DIALOG) {
            valign = CENTER,
            halign = CENTER
        };

        var title_label = new Gtk.Label (_("Bluetooth File Transfer")) {
            max_width_chars = 45,
            use_markup = true,
            wrap = true,
            xalign = 0
        };
        title_label.get_style_context ().add_class ("primary");

        var info_label = new Gtk.Label (_("Select a Bluetooth Device Below to Send Files")) {
            max_width_chars = 45,
            use_markup = true,
            wrap = true,
            xalign = 0
        };

        var empty_alert = new Granite.Widgets.AlertView (
            _("No Devices Found"),
            _("Please ensure that your devices are visible and ready for pairing."),
            ""
        );
        empty_alert.show_all ();

        list_box = new Gtk.ListBox () {
            activate_on_single_click = true,
            selection_mode = BROWSE
        };
        list_box.set_sort_func ((Gtk.ListBoxSortFunc) compare_rows);
        list_box.set_placeholder (empty_alert);

        var scrolled = new Gtk.ScrolledWindow (null, null) {
            child = list_box,
            hexpand = true,
            vexpand = true,
            hscrollbar_policy = NEVER,
            margin_end = 10,
            margin_start = 10,
            max_content_height = 350,
            propagate_natural_height = true
        };
        scrolled.get_style_context ().add_class (Gtk.STYLE_CLASS_FRAME);

        var overlay = new Gtk.Overlay () {
            child = scrolled
        };

        var overlaybar = new Granite.Widgets.OverlayBar (overlay) {
            label = _("Discovering")
        };

        var image_grid = new Gtk.Grid () {
            margin_bottom = 6
        };
        image_grid.attach (icon_image, 0, 0, 1, 2);
        image_grid.attach (title_label, 1, 0);
        image_grid.attach (info_label, 1, 1);

        var content_box = new Gtk.Box (VERTICAL, 0) {
            valign = CENTER
        };
        content_box.add (image_grid);
        content_box.add (overlay);

        get_content_area ().add (content_box);

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
        for (int i = 0; list_box.get_row_at_index (i) != null; i++) {
            if (((DeviceRow) list_box.get_row_at_index (i)).device == device) {
                return;
            }
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
        for (int i = 0; list_box.get_row_at_index (i) != null; i++) {
            if (((DeviceRow) list_box.get_row_at_index (i)).device == device) {
                list_box.remove (list_box.get_row_at_index (i));
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
