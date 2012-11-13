Summary: Varnish VAC Agent
Name: varnish-agent
Version: 1.16
Release: 0%{?dist}
License: BSD
Group: System Environment/Daemons
# for now, lets build i386 and x86_64 explicitly.
#BuildArch: noarch
URL: http://github.com/varnish/varnish-agent/
Source0: ./%{name}-v%{version}.tar.gz
BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
Requires: varnish > 2.1
# you need EPEL
Requires: perl-Log-Log4perl
Requires: perl-Digest-SHA
Requires: perl-Config-Simple
Requires: perl-File-Pid
Requires: perl-Proc-Daemon

Requires(post): /sbin/chkconfig
Requires(preun): /sbin/chkconfig
Requires(preun): /sbin/service
%if %{undefined suse_version}
Requires(preun): initscripts
%endif

%description
Varnish Agent software that runs on all caches managed by Varnish Administration Console (VAC).

%prep
%setup -n varnish-agent-v%{version}

%build 
#echo "No build step necessary"

%install
rm -rf %{buildroot}

mkdir -p %{buildroot}/usr/bin/ 
mkdir -p %{buildroot}/etc/init.d/
mkdir -p %{buildroot}/etc/varnish/
mkdir -p %{buildroot}/etc/sysconfig/
mkdir -p %{buildroot}/etc/varnish-agent/
mkdir -p %{buildroot}/var/lib/varnish-agent/
mkdir -p %{buildroot}/usr/share/doc/varnish-agent/examples/

cp src/varnish-agent      %{buildroot}/usr/bin/
cp example-agent.conf     %{buildroot}/usr/share/doc/varnish-agent/examples/agent.conf
cp example-agent.conf     %{buildroot}/etc/varnish/agent.conf

cp LICENCE.txt %{buildroot}/usr/share/doc/varnish-agent/
cp README.rst  %{buildroot}/usr/share/doc/varnish-agent/

cp redhat/varnish-agent.initrc    %{buildroot}/etc/init.d/varnish-agent
cp redhat/varnish-agent.sysconfig %{buildroot}/etc/sysconfig/varnish-agent

mkdir -p %{buildroot}/%{_mandir}/man1/
%{buildroot}/usr/bin/varnish-agent --man > %{buildroot}/%{_mandir}/man1/varnish-agent.1


%clean
rm -rf %{buildroot}

%files
%defattr(-,root,root,-)
%{_bindir}/*
#%{_libdir}/varnish
%{_var}/lib/varnish-agent
#%{_var}/log/varnish
%{_mandir}/man1/*.1*
#%{_mandir}/man3/*.3*
#%{_mandir}/man7/*.7*
%doc /usr/share/doc/varnish-agent/*

#%doc examples
#%dir %{_sysconfdir}/varnish/
#%config(noreplace) %{_sysconfdir}/varnish-agent.conf
%config(noreplace) /etc/varnish/agent.conf
%config(noreplace) /etc/sysconfig/varnish-agent
/etc/init.d/varnish-agent

%post
/sbin/chkconfig --add varnish-agent

%preun
#if [ $1 -lt 1 ]; then
/sbin/service varnish-agent stop > /dev/null 2>&1
/sbin/chkconfig --del varnish-agent
#fi

%changelog
* Wed Aug 29 2012 Kristian Lyngstøl <kristian@varnish-software.com> - 1.16
- Fix heredocs

* Thu Apr 19 2012 Lasse Karstensen <lasse@varnish-software.com> - 1.14.0-rc
- Prepare a stable 1.1-tree.

* Wed Dec 14 2011 Lasse Karstensen <lasse@varnish-software.com> - 1.1-0.20111214
- bumping version to split from VAC numbering.
- changed paths

* Tue Nov 1 2011 Lasse Karstensen <lkarsten@varnish-software.com> - 1.0-0.20111101
- beta3 changes.

* Wed Oct 5 2011 Lasse Karstensen <lkarsten@varnish-software.com> - 0.1-0.20111005
- Initial version.
