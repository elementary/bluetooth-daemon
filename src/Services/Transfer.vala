/*-
 * Copyright 2021 elementary, Inc. (https://elementary.io)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Library General Public License as published by
 * the Free Software Foundation, either version 2.1 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

[DBus (name = "org.bluez.obex.Transfer1")]
public interface Bluetooth.Obex.Transfer : Object {
    public abstract void cancel () throws GLib.Error;
    public abstract void resume () throws GLib.Error;
    public abstract void suspend () throws GLib.Error;
    public abstract string status { owned get; }
    public abstract ObjectPath session { owned get; }
    public abstract string name { owned get; }
    public abstract string Type { owned get; }
    public abstract uint64 time { owned get; }
    public abstract uint64 size { owned get; }
    public abstract uint64 transferred { owned get; }
    public abstract string filename { owned get; }
}
