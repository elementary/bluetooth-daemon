icon_sizes = ['32', '48', '64']

foreach i : icon_sizes
    install_data(
        'icons' / i + '.svg',
        install_dir: get_option('datadir') / 'icons' / 'hicolor' / i + 'x' + i / 'apps',
        rename: meson.project_name() + '.svg'
    )
    install_data(
        'icons' / i + '.svg',
        install_dir: get_option('datadir') / 'icons' / 'hicolor' / i + 'x' + i + '@2' / 'apps',
        rename: meson.project_name() + '.svg'
    )
endforeach

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

i18n.merge_file(
    input: 'bluetooth-daemon.metainfo.xml',
    output: meson.project_name() + '.metainfo.xml',
    po_dir: meson.project_source_root () / 'po' / 'extra',
    type: 'xml',
    install_dir: get_option('datadir') / 'metainfo',
    install: true
)

install_data(
    'gschema.xml',
    rename: meson.project_name() +  '.gschema.xml',
    install_dir: get_option('datadir') / 'glib-2.0' / 'schemas'
)
