Name: absorb
Version: %{package_version}
Release: %{package_release}
Summary: An Audiobookshelf client
License: GPL-3.0-or-later
URL: https://github.com/pounat/absorb
Requires: libmpv.so.2()(64bit)
Requires: xdg-utils

# Flutter's private libraries resolve through the executable's RPATH.
%global __provides_exclude_from ^/opt/absorb/lib/
%global __requires_exclude ^lib(flutter_linux_gtk|[[:alnum:]_]+_plugin)[.]so[(][)][(]64bit[)]$

%description
Absorb connects to an Audiobookshelf server to browse and play audiobooks
and podcasts.

%install
cp -a "%{package_payload}/." "%{buildroot}/"

%files
%defattr(-,root,root,-)
/opt/absorb
/usr/bin/absorb
/usr/share/applications/com.barnabas.absorb.desktop
/usr/share/icons/hicolor/*/apps/com.barnabas.absorb.png
%license /usr/share/licenses/absorb/LICENSE
