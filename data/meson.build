install_data(
    'bluetooth-daemon.desktop',
    rename: meson.project_name() + '.desktop',
    install_dir: get_option('sysconfdir') / 'xdg' / 'autostart'
)

i18n.merge_file(
    input: 'bluetooth.desktop',
    output: meson.project_name() + '.desktop',
    po_dir: meson.project_source_root () / 'po' / 'extra',
    type: 'desktop',
    install_dir: get_option('datadir') / 'applications',
    install: true
)

install_data(
    'gschema.xml',
    rename: meson.project_name() +  '.gschema.xml',
    install_dir: datadir / 'glib-2.0' / 'schemas'
)
