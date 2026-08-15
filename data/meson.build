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

systemd_user_unit_dir = get_option('systemduserunitdir')
if systemd_user_unit_dir != 'no'
    systemd_dep = dependency ('systemd')

    if systemd_user_unit_dir == ''
        systemd_user_unit_dir = systemd_dep.get_variable('systemduserunitdir', pkgconfig_define: ['prefix', prefix])
    endif

    service_config = configuration_data()
    service_config.set('bindir', bindir)

    configure_file(
        input: 'bluetooth.service.in',
        output: meson.project_name() + '.service',
        configuration: service_config,
        install_dir: systemd_user_unit_dir
    )
endif

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
