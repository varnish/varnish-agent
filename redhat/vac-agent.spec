Summary: VAC agent
Name: vac-agent
Version: 0.1
Release: 0.20111005%{?dist}
License: BSD
Group: System Environment/Daemons
URL: http://www.varnish-software.com/
#Source0: http://repo.varnish-cache.org/source/%{name}-%{version}.tar.gz

#Source0: %{name}-trunk.tar.gz
BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
# To build from git, start with a make dist, see redhat/README.redhat 
# You will need at least automake autoconf libtool python-docutils
#BuildRequires: automake autoconf libtool python-docutils
BuildRequires: ncurses-devel libxslt groff pcre-devel pkgconfig
Requires: varnish-libs = %{version}-%{release}
Requires: varnish
#liblog-log4perl-perl
#libdigest-sha-perl
##libconfig-simple-perl
#Requires(pre): shadow-utils
Requires(post): /sbin/chkconfig
#, /usr/bin/uuidgen
Requires(preun): /sbin/chkconfig
Requires(preun): /sbin/service
%if %{undefined suse_version}
Requires(preun): initscripts
%endif

%description
This is the VAC agent that must be run on all caches.

%prep
#%setup -q
%setup -q -n varnish-trunk

#mkdir examples
#cp bin/varnishd/default.vcl etc/zope-plone.vcl examples

%build
# No pkgconfig/libpcre.pc in rhel4
%if 0%{?rhel} == 4
	export PCRE_CFLAGS="`pcre-config --cflags`"
	export PCRE_LIBS="`pcre-config --libs`"
%endif

# Remove "--disable static" if you want to build static libraries 
# jemalloc is not compatible with Red Hat's ppc64 RHEL kernel :-(
%ifarch ppc64 ppc
	%configure --disable-static --localstatedir=/var/lib --without-jemalloc
%else
	%configure --disable-static --localstatedir=/var/lib
%endif

# We have to remove rpath - not allowed in Fedora
# (This problem only visible on 64 bit arches)
#sed -i 's|^hardcode_libdir_flag_spec=.*|hardcode_libdir_flag_spec=""|g;
#	s|^runpath_var=LD_RUN_PATH|runpath_var=DIE_RPATH_DIE|g' libtool

%{__make} %{?_smp_mflags}

#head -6 etc/default.vcl > redhat/default.vcl
#
#cat << EOF >> redhat/default.vcl
#backend default {
##  .host = "127.0.0.1";
#  .port = "80";
#}
#EOF

#tail -n +11 etc/default.vcl >> redhat/default.vcl

#%if 0%{?fedora}%{?rhel} != 0 && 0%{?rhel} <= 4 && 0%{?fedora} <= 8
#	# Old style daemon function
#	sed -i 's,--pidfile \$pidfile,,g;
#		s,status -p \$pidfile,status,g;
#		s,killproc -p \$pidfile,killproc,g' \
#	redhat/varnish.initrc redhat/varnishlog.initrc redhat/varnishncsa.initrc
#%endif

#cp -r doc/sphinx/\=build/html doc

#%check
## rhel5 on ppc64 is just too strange
#%ifarch ppc64
#	%if 0%{?rhel} > 4
#		cp bin/varnishd/.libs/varnishd bin/varnishd/lt-varnishd
#	%endif
#%endif
#
## The redhat ppc builders seem to have some ulimit problems?
## These tests work on a rhel4 ppc/ppc64 instance outside the builders
#%ifarch ppc64 ppc
#	%if 0%{?rhel} == 4
#		rm bin/varnishtest/tests/c00031.vtc
#		rm bin/varnishtest/tests/r00387.vtc
#	%endif
#%endif

#%{__make} check LD_LIBRARY_PATH="../../lib/libvarnish/.libs:../../lib/libvarnishcompat/.libs:../../lib/libvarnishapi/.libs:../../lib/libvcl/.libs:../../lib/libvgz/.libs"

%install
rm -rf %{buildroot}
#make install DESTDIR=%{buildroot} INSTALL="install -p"

# None of these for fedora
#find %{buildroot}/%{_libdir}/ -name '*.la' -exec rm -f {} ';'

# Remove this line to build a devel package with symlinks
#find %{buildroot}/%{_libdir}/ -name '*.so' -type l -exec rm -f {} ';'

#mkdir -p %{buildroot}/var/lib/varnish
#mkdir -p %{buildroot}/var/log/varnish
#mkdir -p %{buildroot}/var/run/varnish
#%{__install} -D -m 0644 redhat/default.vcl %{buildroot}%{_sysconfdir}/varnish/default.vcl
#%{__install} -D -m 0644 redhat/varnish.sysconfig %{buildroot}%{_sysconfdir}/sysconfig/varnish
#%{__install} -D -m 0644 redhat/varnish.logrotate %{buildroot}%{_sysconfdir}/logrotate.d/varnish
#%{__install} -D -m 0755 redhat/varnish.initrc %{buildroot}%{_initrddir}/varnish
#%{__install} -D -m 0755 redhat/varnishlog.initrc %{buildroot}%{_initrddir}/varnishlog
#%{__install} -D -m 0755 redhat/varnishncsa.initrc %{buildroot}%{_initrddir}/varnishncsa
#%{__install} -D -m 0755 redhat/varnish_reload_vcl %{buildroot}%{_bindir}/varnish_reload_vcl

%clean
rm -rf %{buildroot}

%files
%defattr(-,root,root,-)
/* 
#%{_sbindir}/*
#%{_bindir}/*
#%{_libdir}/varnish
#%{_var}/lib/varnish
#%{_var}/log/varnish
#%{_mandir}/man1/*.1*
#%{_mandir}/man3/*.3*
#%{_mandir}/man7/*.7*
#%doc INSTALL LICENSE README redhat/README.redhat ChangeLog
#%doc examples
#%dir %{_sysconfdir}/varnish/
#%config(noreplace) %{_sysconfdir}/varnish/default.vcl
#%config(noreplace) %{_sysconfdir}/sysconfig/varnish
#%config(noreplace) %{_sysconfdir}/logrotate.d/varnish
#%{_initrddir}/varnish
#%{_initrddir}/varnishlog
#%{_initrddir}/varnishncsa

#%files libs-static
#%{_libdir}/libvarnish.a
#%{_libdir}/libvarnishapi.a
#%{_libdir}/libvarnishcompat.a
#%{_libdir}/libvcl.a
#%doc LICENSE

#%pre
#getent group varnish >/dev/null || groupadd -r varnish
#getent passwd varnish >/dev/null || \
#	useradd -r -g varnish -d /var/lib/varnish -s /sbin/nologin \
#		-c "Varnish Cache" varnish
#exit 0

#%post
/sbin/chkconfig --add vac-agent
#/sbin/chkconfig --add varnishlog
#/sbin/chkconfig --add varnishncsa 
#test -f /etc/varnish/secret || (uuidgen > /etc/varnish/secret && chmod 0600 /etc/varnish/secret)

%preun
if [ $1 -lt 1 ]; then
  /sbin/service vac-agent stop > /dev/null 2>&1
#  /sbin/service varnishlog stop > /dev/null 2>&1
#  /sbin/service varnishncsa stop > /dev/null 2>%1
  /sbin/chkconfig --del vac-agent
##  /sbin/chkconfig --del varnishlog
#  /sbin/chkconfig --del varnishncsa 
fi

#%post libs -p /sbin/ldconfig

#%postun libs -p /sbin/ldconfig

%changelog
* Wed Oct 5 2011 Lasse Karstensen <lkarsten@varnish-software.com> - 0.1-0.20111005
- Initial version.
