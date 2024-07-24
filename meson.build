project(
    'io.elementary.bluetooth',
    'vala', 'c',
    version: '1.0.0',
    meson_version : '>= 0.57'
)

add_global_arguments('-DGETTEXT_PACKAGE="@0@"'.format(meson.project_name()), language:'c')

gnome = import('gnome')
i18n = import('i18n')

granite_dep = dependency ('granite')
gtk_dep = dependency ('gtk+-3.0')

subdir('data')
subdir('po')
subdir('src')

gnome.post_install(
    glib_compile_schemas: true,
    gtk_update_icon_cache: true
)
