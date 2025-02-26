/*
 * Copyright 2021 elementary, Inc. (https://elementary.io)
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public
 * License as published by the Free Software Foundation; either
 * version 3 of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public
 * License along with this program; if not, write to the
 * Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 * Boston, MA 02110-1301 USA
 *
 * Authored by: Torikulhabib <torik.habib@gamail.com>
 *
 */

public class BluetoothApp : Gtk.Application {
    public const OptionEntry[] OPTIONS_BLUETOOTH = {
        { "silent", 's', 0, OptionArg.NONE, out silent, "Run the Application in background", null},
        { "send", 'f', 0, OptionArg.FILENAME_ARRAY, out arg_files, "Open file to send via Bluetooth", "FILE…" },
        { null }
    };

    public Bluetooth.ObjectManager object_manager;
    public Bluetooth.Obex.Agent agent_obex;
    public Bluetooth.Obex.Transfer transfer;
    public BtReceiver bt_receiver;
    public BtSender bt_sender;
    public ScanDialog bt_scan = null;
    public GLib.List<BtReceiver> bt_receivers;
    public GLib.List<BtSender> bt_senders;
    public static bool silent = true;
    public static bool active_once;
    [CCode (array_length = false, array_null_terminated = true)]
    public static string[]? arg_files = null;

    construct {
        application_id = "io.elementary.bluetooth";
        flags |= ApplicationFlags.HANDLES_COMMAND_LINE;
        Intl.setlocale (LocaleCategory.ALL, "");
        add_main_option_entries (OPTIONS_BLUETOOTH);
    }

    private File[] create_files_for_args (ApplicationCommandLine command, string[] args) {
        File[] files = {};

        foreach (unowned string arg in args) {
            var file = command.create_file_for_arg (arg);
            if (!file.query_exists ()) {
                stderr.printf (
                    "Ignoring not found file: %s\n",
                    file.get_path ()
                );
                continue;
            }

            files += file;
        }

        return files;
    }

    private void scan_and_send_files (File[] files) {
        if (bt_scan == null) {
            bt_scan = new ScanDialog (this, object_manager);
            Idle.add (() => { // Wait for async BtScan initialisation
                bt_scan.show_all ();
                return Source.REMOVE;
            });
        } else {
            bt_scan.present ();
        }

        bt_scan.destroy.connect (() => {
            bt_scan = null;
        });

        bt_scan.send_file.connect ((device) => {
            if (!insert_sender (files, device)) {
                bt_sender = new BtSender (this);
                bt_sender.add_files (files, device);
                bt_senders.append (bt_sender);
                bt_sender.show_all ();
                bt_sender.destroy.connect (() => {
                    bt_senders.foreach ((sender) => {
                        if (sender.device == bt_sender.device) {
                            bt_senders.remove_link (bt_senders.find (sender));
                        }
                    });
                });
            }
        });
    }

    public override int command_line (ApplicationCommandLine command) {
        activate ();

        // Handle "send" option
        if (arg_files != null) {
            File[] files = create_files_for_args (command, arg_files);

            if (files.length > 0) {
                scan_and_send_files (files);
            }
        }

        return 0;
    }

    protected override void activate () {
        var granite_settings = Granite.Settings.get_default ();
        var gtk_settings = Gtk.Settings.get_default ();

        gtk_settings.gtk_application_prefer_dark_theme =
            granite_settings.prefers_color_scheme == Granite.Settings.ColorScheme.DARK;

        granite_settings.notify["prefers-color-scheme"].connect (() => {
            gtk_settings.gtk_application_prefer_dark_theme =
            granite_settings.prefers_color_scheme == Granite.Settings.ColorScheme.DARK;
        });

        if (silent) {
            if (active_once) { // after process hold exist.
                release (); // Protect from multiple holds. Has no effect if not already held.
            }
            hold ();
            silent = false;
        }

        if (object_manager == null) {
            bt_receivers = new GLib.List<BtReceiver> ();
            bt_senders = new GLib.List<BtSender> ();
            object_manager = new Bluetooth.ObjectManager ();
            object_manager.notify["has-adapter"].connect (() => {
                var build_path = Path.build_filename (
                    Environment.get_home_dir (), ".local", "share", "contractor"
                );

                if (!File.new_for_path (build_path).query_exists ()) {
                    DirUtils.create (build_path, 0700);
                }

                var file = File.new_for_path (
                    Path.build_filename (
                        build_path,
                        Environment.get_application_name () + ".contract"
                    )
                );

                if (object_manager.has_adapter) {
                    if (!active_once) {
                        agent_obex = new Bluetooth.Obex.Agent ();
                        agent_obex.transfer_view.connect (dialog_active);
                        agent_obex.response_accepted.connect (response_accepted);
                        agent_obex.response_notify.connect (response_notify);
                        active_once = true;
                    }

                    if (!file.query_exists ()) {
                        var keyfile = new GLib.KeyFile ();
                        keyfile.set_string ("Contractor Entry", "Name", _("Send Files via Bluetooth"));
                        keyfile.set_string ("Contractor Entry", "Icon", "bluetooth");
                        keyfile.set_string ("Contractor Entry", "Description", _("Send files to device…"));
                        keyfile.set_string ("Contractor Entry", "Exec", "io.elementary.bluetooth -f %F");
                        keyfile.set_string ("Contractor Entry", "MimeType", "!inode;");

                        try {
                            keyfile.save_to_file (file.get_path ());
                        } catch (Error e) {
                            critical ("Unable to create contract: %s", e.message);
                        }
                    }
                } else {
                    if (file.query_exists ()) {
                        try {
                            file.delete ();
                        } catch (Error e) {
                            critical (e.message);
                        }
                    }
                }
            });
        }
    }

    private void dialog_active (string session_path) {
        bt_receivers.foreach ((receiver) => {
            if (receiver.transfer.session == session_path) {
                receiver.show_all ();
            }
        });
        bt_senders.foreach ((sender) => {
            if (sender.transfer.session == session_path) {
                sender.show_all ();
            }
        });
    }

    private bool insert_sender (File[] files, Bluetooth.Device device) {
        bool exist = false;
        bt_senders.foreach ((sender) => {
            if (sender.device == device) {
                sender.insert_files (files);
                sender.present ();
                exist = true;
            }
        });
        return exist;
    }

    private void response_accepted (string address, GLib.ObjectPath objectpath) {
        try {
            transfer = Bus.get_proxy_sync (BusType.SESSION, "org.bluez.obex", objectpath);
        } catch (Error e) {
            GLib.warning (e.message);
        }
        if (transfer.name == null) {
            return;
        }

        bt_receiver = new BtReceiver (this);
        bt_receivers.append (bt_receiver);
        bt_receiver.destroy.connect (() => {
            bt_receivers.foreach ((receiver) => {
                if (receiver.transfer.session == bt_receiver.session) {
                    bt_receivers.remove_link (bt_receivers.find (receiver));
                }
            });
        });
        Bluetooth.Device device = object_manager.get_device (address);
        var devicename = device.alias;
        var deviceicon = device.icon;
        bt_receiver.set_transfer (
            devicename == null ? get_device_description_from_icon (device) : devicename,
            deviceicon,
            objectpath
        );
    }

    private void response_notify (string address, GLib.ObjectPath objectpath) {
        Bluetooth.Device device = object_manager.get_device (address);
        var devicename = device.alias;
        var deviceicon = device.icon;
        try {
            transfer = Bus.get_proxy_sync (BusType.SESSION, "org.bluez.obex", objectpath);
        } catch (Error e) {
            GLib.warning (e.message);
        }
        var notification = new GLib.Notification ("bluetooth");
        notification.set_icon (new ThemedIcon (deviceicon));
        if (reject_if_exist (transfer.name, transfer.size)) {
            notification.set_title (_("Rejected file"));
            notification.set_body (
                GLib.Markup.printf_escaped (_("<b>File:</b> %s <b>Size: </b>%s already exists"),
                    transfer.name,
                    GLib.format_size (transfer.size)
                )
            );
            send_notification ("io.elementary.bluetooth", notification);
            Idle.add (() => {
                activate_action ("btcancel", new Variant.string ("Cancel"));
                return false;
            });
            return;
        }

        var settings = new Settings ("io.elementary.desktop.bluetooth");
        if (settings.get_boolean ("confirm-accept-files")) {
            notification.set_priority (NotificationPriority.URGENT);
            notification.set_title (_("Incoming file"));
            notification.set_body (
                GLib.Markup.printf_escaped (_("<b>%s</b> is ready to send file: %s size: %s"),
                    devicename == null? get_device_description_from_icon (device) : devicename,
                    transfer.name,
                    GLib.format_size (transfer.size)
                )
            );
            notification.add_button (
                _("Accept"),
                GLib.Action.print_detailed_name ("app.btaccept", new Variant ("s", "Accept"))
            );
            notification.add_button (
                ///Translators response to refuse a file transfer
                _("Decline"),
                GLib.Action.print_detailed_name ("app.btcancel", new Variant ("s", "Cancel"))
            );
        } else {
            notification.set_title (_("Receiving file"));
            notification.set_body (_("%s is sending file: %s size: %s").printf (
                devicename,
                transfer.name,
                GLib.format_size (transfer.size)
            ));
            Idle.add (() => {
                activate_action ("btaccept", new Variant.string ("Accept"));
                 return false;
            });
        }
        send_notification ("io.elementary.bluetooth", notification);
    }

    private string get_device_description_from_icon (Bluetooth.Device device) {
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

    private bool reject_if_exist (string name, uint64 size) {
        var input_file = File.new_for_path (
            Path.build_filename (
                Environment.get_user_special_dir (UserDirectory.DOWNLOAD),
                name
            )
        );
        uint64 size_file = 0;
        if (input_file.query_exists ()) {
           try {
                FileInfo info = input_file.query_info (GLib.FileAttribute.STANDARD_SIZE, 0);
                size_file = info.get_size ();
            } catch (Error e) {
                GLib.warning (e.message);
            }
        }
        return size == size_file && input_file.query_exists ();
    }

    public static int main (string[] args) {
        var app = new BluetoothApp ();
        return app.run (args);
    }
}
