#########################################################
#
# Tapper - Test infrastructure
# ----------------------------
#
# More information about Tapper:
#
#  - https://github.com/amd/Tapper-Doc/
#  - http://search.cpan.org/~amd/Tapper-Doc/
#
#########################################################
#
# Initial setup of a Tapper central control machine:
#
#  - chroot for installer to be booted over nfs
#
#  - chroot and image file for baseimage
#    to be installed on testmachines
#
#  - a client package with Tapper toolchain
#    to be installed on testmachines
#
#  - local setup for central Tapper host
#      . databases
#      . nfs exports
#      . tftpserver
#      . Tapper daemons
#      . initial Tapper config
#      . Web frontend on Apache
#      . initial example test report
# 
#########################################################

TMP=/tmp

DATATAPPER      = /data/tapper
METAREPORTSDIR  = $(DATATAPPER)/live/metareports                       # meta-reports
OUTPUTDIR       = $(DATATAPPER)/live/output                            # intermediate output
IMAGESDIR       = $(DATATAPPER)/live/repository/images                 # OS images
PACKAGESDIR     = $(DATATAPPER)/live/repository/packages               # packages
TAPPERUTILSDIR  = $(DATATAPPER)/live/repository/packages/tapperutils   # Tapper clientlib
TESTPROGRAMDIR  = $(DATATAPPER)/live/testprogram                       # test programs
CONFIGSDIR      = $(DATATAPPER)/live/configs                           # auto-generated configs
TFTPBOOTDIR     = $(DATATAPPER)/live/configs/tftpboot                  # grub configs via TFTP
SYNCDIR         = $(DATATAPPER)/live/sync                              # sync'ing interdependent tests
NFSROOTDIR      = $(DATATAPPER)/live/nfsroot                           # network bootable OS image

#DEBIANMIRROR=http://ftp.de.debian.org/debian/
DEBIANMIRROR=http://alzey/debian/

# installer NFS root
# 64bit always
INSTALLERCHROOT=/mnt/chroot/squeeze-tapper-nfsroot-for-installer
INSTALLERCHROOTPREPARE=prepare-installer-nfsroot-in-chroot

# baseimage
# 64bit
BASEIMAGE64FILE=$(IMAGESDIR)/debian_base64.tgz
BASEIMAGE64CHROOT=/mnt/chroot/squeeze-tapper-nfsroot-for-baseimage64
BASEIMAGE64CHROOTPREPARE=prepare-baseimage64-in-chroot
# 32bit
BASEIMAGE32=$(IMAGESDIR)/debian_base32.tgz
BASEIMAGE32CHROOT=/mnt/chroot/squeeze-tapper-nfsroot-for-baseimage32
BASEIMAGE32CHROOTPREPARE=prepare-baseimage32-in-chroot

# client package
# 64bit
CLIENTPKG64FILE=$(TAPPERUTILSDIR)/opt-tapper64.tar.gz
CLIENTPKG64CHROOT=/mnt/chroot/squeeze-tapper-clientpkg64
CLIENTPKG64CHROOTPREPARE=prepare-clientpkg64-in-chroot
# 32bit
CLIENTPKG32FILE=$(TAPPERUTILSDIR)/opt-tapper32.tar.gz
CLIENTPKG32CHROOT=/mnt/chroot/squeeze-tapper-clientpkg32
CLIENTPKG32CHROOTPREPARE=prepare-clientpkg32-in-chroot

### initial machine names
TAPPER_SERVER=tapper
TESTMACHINE1=johnconnor
TESTMACHINE2=sarahconnor

### Perl setup
### if version changed, also change it in the *CHROOTPREPARE scripts
PERLVERSION=5.12.3
DISTROPREFS=http://cpansearch.perl.org/src/ANDK/CPAN-1.9600/distroprefs/

### starter kit
STARTERKITBASENAME=tapper-starterkit
STARTERKIT=$(STARTERKITBASENAME).tgz
STARTERKITURL=http://amd64.org/pub/tapper/$(STARTERKIT)
STARTERKITDIR=$(TMP)/$(STARTERKITBASENAME)

### generated files to clean away
CLEANFILES = $(CLIENTPKG64FILE)


# default target
all:
	@echo "Try "
	@echo "  make installernfsroot -- a base OS subdir bootable from NFS for Tapper::Installer"
	@echo "  make baseimage64      -- a Debian imagefile used as base system for tests"
	@echo "  make clientpkg64      -- a Debian imagefile used as base system for tests"
	@echo "  make tapperhost       -- everything to run a central Tapper control host, contains"
	@echo "                              . make installernfsroot"
	@echo "                              . make baseimage64"
	@echo "                              . make clientpkg64"
	@echo "                           plus local setup"
	@echo "  make it so            -- same as 'make tapperhost'"


# ==============================================================
# *
# *
# *
# *                      General setup utils
# *
# *
# *
# ==============================================================

dependencies:
	@echo "########## install some build dependencies"
	apt-get install debootstrap
	apt-get install curl
	apt-get install wget
	apt-get install rsync
	curl -L $(STARTERKITURL) -o $(TMP)/$(STARTERKIT)
	cd $(TMP) ; tar xzf $(STARTERKIT)
	mkdir -p /root/.cpan/prefs/
	wget -r --no-parent -nd -P /root/.cpan/prefs/ $(DISTROPREFS)


# ==============================================================
# *
# *
# *
# *                      Installer NFS root
# *
# *
# *
# ==============================================================

installernfsroot: dependencies
	@echo "##################################################################"
	@echo "# "
	@echo "# "
	@echo "#         ,************************."
	@echo "# Set up  *   INSTALLER NFS ROOT   *  for net booting testmachines"
	@echo "#         '************************'"
	@echo "# "
	@echo "# "
	@echo "##################################################################"
#
### prepare subdirs
#
	@echo "########## prepare subdirs"
	-umount $(INSTALLERCHROOT)/sys
	-umount $(INSTALLERCHROOT)/proc
	-umount $(INSTALLERCHROOT)/dev/pts
	rm -fr $(INSTALLERCHROOT)
	mkdir -p $(INSTALLERCHROOT)
#
### bootstrap new debian in chroot
#
	@echo "########## bootstrap new debian in chroot"
	debootstrap --arch amd64 squeeze $(INSTALLERCHROOT) $(DEBIANMIRROR)
	mount -t proc proc $(INSTALLERCHROOT)/proc
	mount -t devpts devpts $(INSTALLERCHROOT)/dev/pts
#
### set shell environment
#
	@echo "########## set shell environment"
	echo 'PS1="CHROOT-Tapper-NFS-Installer:\w# "'  >> $(INSTALLERCHROOT)/root/.bashrc
	echo 'export PERL_AUTOINSTALL="--defaultdeps"' >> $(INSTALLERCHROOT)/root/.bashrc
	echo 'export TWMC_TEST_PORT=9876'              >> $(INSTALLERCHROOT)/root/.bashrc
	echo 'alias dir="ls -Flart --color"'           >> $(INSTALLERCHROOT)/root/.bashrc
	echo 'rm="rm -i"'                              >> $(INSTALLERCHROOT)/root/.bashrc
	echo 'cp="cp -i"'                              >> $(INSTALLERCHROOT)/root/.bashrc
	echo 'mv="mv -i"'                              >> $(INSTALLERCHROOT)/root/.bashrc
#
### Perl/CPAN setup
#
	@echo "########## Perl/CPAN setup"
	mkdir -p $(INSTALLERCHROOT)/root/.cpan/prefs/
	rsync -r /root/.cpan/prefs/ $(INSTALLERCHROOT)/root/.cpan/prefs/
#
### enable console login
#
	@echo "########## enable console login"
	echo 's0:12345:respawn:/sbin/getty 115200 ttyS0 vt100' >> $(INSTALLERCHROOT)/etc/inittab
#
### set NFS read-only
#
	@echo "########## set NFS read-only"
	sed -i -e 's/rootmode=rw/rootmode=ro/' $(INSTALLERCHROOT)/etc/init.d/checkroot.sh
#
### prepare writeable directories
#
	@echo "########## prepare writeable directories"
	echo 'proc  /proc      proc  defaults 0 0' >> $(INSTALLERCHROOT)/etc/fstab
	echo 'sysfs /sys       sysfs defaults 0 0' >> $(INSTALLERCHROOT)/etc/fstab
	echo 'tmpfs /tmp       tmpfs defaults 0 0' >> $(INSTALLERCHROOT)/etc/fstab
	echo 'ramfs /var/log   ramfs defaults 0 0' >> $(INSTALLERCHROOT)/etc/fstab
	echo 'ramfs /var/lock  ramfs defaults 0 0' >> $(INSTALLERCHROOT)/etc/fstab
	echo 'ramfs /var/run   ramfs defaults 0 0' >> $(INSTALLERCHROOT)/etc/fstab
	echo 'ramfs /var/spool ramfs defaults 0 0' >> $(INSTALLERCHROOT)/etc/fstab
#
### configure NFS working directory
#
	@echo "########## configure NFS working directory"
	echo "$(TAPPER_SERVER):$(DATATAPPER) $(DATATAPPER) nfs auto,defaults 0 0" >> $(INSTALLERCHROOT)/etc/fstab
#
### run remaining configuration from inside the chroot
#
	@echo "########## run remaining configuration from inside the chroot"
	cp $(STARTERKITDIR)/utils/$(INSTALLERCHROOTPREPARE) $(INSTALLERCHROOT)/
	cp $(TMP)/$(STARTERKIT) $(INSTALLERCHROOT)/tmp/
	chmod +x $(INSTALLERCHROOT)/$(INSTALLERCHROOTPREPARE)
	chroot $(INSTALLERCHROOT) /$(INSTALLERCHROOTPREPARE)
	rm -f $(INSTALLERCHROOT)/$(INSTALLERCHROOTPREPARE)
	rm $(INSTALLERCHROOT)/tmp/$(STARTERKIT)

# ==============================================================
# *
# *
# *
# *                      Base Image
# *
# *
# *
# ==============================================================

baseimage: dependencies
	@echo "########################################################"
	@echo "# "
	@echo "#         ,****************."
	@echo "# Set up  *   BASE IMAGE   *  to be used for Tests"
	@echo "#         '****************'"
	@echo "# "
	@echo "########################################################"
#
### prepare subdirs
#
	@echo "########## prepare subdirs"
	-umount $(BASEIMAGE64CHROOT)/sys
	-umount $(BASEIMAGE64CHROOT)/proc
	-umount $(BASEIMAGE64CHROOT)/dev/pts
	rm -fr $(BASEIMAGE64CHROOT)
	mkdir -p $(BASEIMAGE64CHROOT)
#
### bootstrap new debian in it
#
	@echo "########## bootstrap new debian in it"
	debootstrap --arch amd64 squeeze $(BASEIMAGE64CHROOT) $(DEBIANMIRROR)
	mount -t proc proc $(BASEIMAGE64CHROOT)/proc
	mount -t devpts devpts $(BASEIMAGE64CHROOT)/dev/pts
#
### set shell environment
#
	@echo "########## set shell environment"
	echo 'PS1="CHROOT-Tapper-BasImage:\w# "'       >> $(BASEIMAGE64CHROOT)/root/.bashrc
	echo 'export PERL_AUTOINSTALL="--defaultdeps"' >> $(BASEIMAGE64CHROOT)/root/.bashrc
	echo 'export PERLBREW_ROOT=/opt/tapper/perl'   >> $(BASEIMAGE64CHROOT)/root/.bashrc
	echo 'export TWMC_TEST_PORT=9876'              >> $(BASEIMAGE64CHROOT)/root/.bashrc
	echo 'alias dir="ls -Flart --color"'           >> $(BASEIMAGE64CHROOT)/root/.bashrc
	echo 'rm="rm -i"'                              >> $(BASEIMAGE64CHROOT)/root/.bashrc
	echo 'cp="cp -i"'                              >> $(BASEIMAGE64CHROOT)/root/.bashrc
	echo 'mv="mv -i"'                              >> $(BASEIMAGE64CHROOT)/root/.bashrc
#
### Perl/CPAN setup
#
	@echo "########## Perl/CPAN setup"
	mkdir -p $(BASEIMAGE64CHROOT)/root/.cpan/prefs/
	rsync -r /root/.cpan/prefs/ $(BASEIMAGE64CHROOT)/root/.cpan/prefs/
#
### enable console login
#
	@echo "########## enable console login"
	echo 's0:12345:respawn:/sbin/getty 115200 ttyS0 vt100' >> $(BASEIMAGE64CHROOT)/etc/inittab
#
### prepare writeable directories
#
	@echo "########## prepare writeable directories"
	echo 'proc  /proc      proc  defaults 0 0' >> $(BASEIMAGE64CHROOT)/etc/fstab
	echo 'sysfs /sys       sysfs defaults 0 0' >> $(BASEIMAGE64CHROOT)/etc/fstab
	echo 'tmpfs /tmp       tmpfs defaults 0 0' >> $(BASEIMAGE64CHROOT)/etc/fstab
	echo 'ramfs /var/log   ramfs defaults 0 0' >> $(BASEIMAGE64CHROOT)/etc/fstab
	echo 'ramfs /var/lock  ramfs defaults 0 0' >> $(BASEIMAGE64CHROOT)/etc/fstab
	echo 'ramfs /var/run   ramfs defaults 0 0' >> $(BASEIMAGE64CHROOT)/etc/fstab
	echo 'ramfs /var/spool ramfs defaults 0 0' >> $(BASEIMAGE64CHROOT)/etc/fstab
#
### configure NFS working directory
#
	@echo "########## configure NFS working directory"
	echo "$(TAPPER_SERVER):$(DATATAPPER) $(DATATAPPER) nfs auto,defaults 0 0" >> $(BASEIMAGE64CHROOT)/etc/fstab
#
### run remaining configuration from inside the chroot
#
	@echo "########## run remaining configuration from inside the chroot"
	cp $(STARTERKITDIR)/utils/$(BASEIMAGE64CHROOTPREPARE) $(BASEIMAGE64CHROOT)/
	cp $(TMP)/$(STARTERKIT) $(BASEIMAGE64CHROOT)/tmp/
	chmod +x $(BASEIMAGE64CHROOT)/$(BASEIMAGE64CHROOTPREPARE)
	chroot $(BASEIMAGE64CHROOT) /$(BASEIMAGE64CHROOTPREPARE)
	rm -f $(BASEIMAGE64CHROOT)/$(BASEIMAGE64CHROOTPREPARE)
	rm $(BASEIMAGE64CHROOT)/tmp/$(STARTERKIT)


clientpkg64: $(CLIENTPKG64FILE)

$(CLIENTPKG64FILE): baseimage64file
#
# Prepare client-side opt-tapper package
#
	@echo "##############################################################"
	@echo "# "
	@echo "#         ,********************."
	@echo "# Set up  *   CLIENT PACKAGE   *  to be installed in Test-OS"
	@echo "#         '********************'"
	@echo "# "
	@echo "##############################################################"
#
### prepare subdirs
#
	@echo "########## Prepare client-side opt-tapper package"
	rm -fr $(CLIENTPKG64CHROOT)
	mkdir $(CLIENTPKG64CHROOT)
	tar -C $(CLIENTPKG64CHROOT) -xzf $(BASEIMAGE64FILE)
	mount -t proc proc $(CLIENTPKG64CHROOT)/proc
	mount -t devpts devpts $(CLIENTPKG64CHROOT)/dev/pts

	cp $(STARTERKITDIR)/utils/$(CLIENTPKG64CHROOTPREPARE) $(CLIENTPKG64CHROOT)/
	chmod +x $(CLIENTPKG64CHROOT)/$(CLIENTPKG64CHROOTPREPARE)
	chroot $(CLIENTPKG64CHROOT) /$(CLIENTPKG64CHROOTPREPARE)
	rm -f $(CLIENTPKG64CHROOT)/$(CLIENTPKG64CHROOTPREPARE)
	-umount $(CLIENTPKG64CHROOT)/proc
	-umount $(CLIENTPKG64CHROOT)/dev/pts
	cd $(CLIENTPKG64CHROOT)
	tar -czf $(CLIENTPKG64FILE) opt/

# ==============================================================
# *
# *
# *
# *                      Tapper Central Server
# *
# *
# *
# ==============================================================

intro:
	@echo "########################################################"
	@echo "# "
	@echo "# "
	@echo "# Set up central Tapper host"
	@echo "# "
	@echo "# "
	@echo "########################################################"


workingdirs:
#
#  Prepare central workdir that is later exported via NFS
#
	@echo "########## Prepare central workdir that is later exported via NFS"
	mkdir -p $(METAREPORTSDIR)
	mkdir -p $(OUTPUTDIR)
	mkdir -p $(IMAGESDIR)
	mkdir -p $(PACKAGESDIR)
	mkdir -p $(TAPPERUTILSDIR)
	mkdir -p $(TESTPROGRAMDIR)
	mkdir -p $(CONFIGSDIR)
	mkdir -p $(TFTPBOOTDIR)
	mkdir -p $(SYNCDIR)
	mkdir -p $(NFSROOTDIR)

baseimage64file: $(BASEIMAGE64FILE)

$(BASEIMAGE64FILE): baseimage workingdirs
#
# Pack baseimage
#
	@echo "########## Pack baseimage64"
	cd $(BASEIMAGE64CHROOT) ; tar -czf $(BASEIMAGE64FILE) .

nfsrootdir: $(DATATAPPER)/live/nfsroot/etc/log4perl.cf

$(DATATAPPER)/live/nfsroot/etc/log4perl.cf: installernfsroot workingdirs
#
# Prepare network boot OS
#
	@echo "########## Prepare network boot OS"
	rsync -ax $(INSTALLERCHROOT)/ $(NFSROOTDIR)/

optperl:
#
# Install Perl
#
	@echo "########## Install Perl"
	export PERLBREW_ROOT=/opt/tapper/perl ; \
	mkdir -p $$PERLBREW_ROOT ; \
	curl -L http://xrl.us/perlbrew -o $(TMP)/perlbrew ; \
	chmod +x $(TMP)/perlbrew ; \
	$(TMP)/perlbrew install ; \
	/opt/tapper/perl/bin/perlbrew init ; \
	echo "source /opt/tapper/perl/etc/bashrc" >> $$HOME/.bashrc ; \
	source /opt/tapper/perl/etc/bashrc ; \
	perlbrew install perl-$(PERLVERSION) ; \
	perlbrew switch perl-$(PERLVERSION)
#
# CPAN config
#
	@echo "########## CPAN config"
	cp $(STARTERKITDIR)/misc/CPAN-Config.pm /opt/tapper/perl/perls/perl-$(PERLVERSION)/lib/$(PERLVERSION)/CPAN/Config.pm
	export PERL_AUTOINSTALL="--defaultdeps" ; echo "reload index" | cpan

nfsserver:
#
# Install an NFS server and export $(DATATAPPER)
#
	@echo "########## Install an NFS server and export $(DATATAPPER)"
	apt-get install nfs-kernel-server
	echo '$(DATATAPPER) 192.168.1.0/255.255.255.0(fsid=0,no_root_squash,no_subtree_check,rw)' >> /etc/exports

libdeps:
#
# Prepare packages
#
	@echo "########## Prepare packages"
	apt-get install mysql-server
	apt-get install libmysqlclient-dev
	apt-get install libsqlite3-0
	apt-get install sqlite3
	apt-get install libexpat-dev
	apt-get install apache2
	apt-get install libapache2-mod-fcgid
	apt-get install atftpd

perlpkgs:
#
# Prepare CPAN libs
#
	@echo "########## Prepare CPAN libs"
	PERL_AUTOINSTALL="--defaultdeps" cpan DBD::mysql
	PERL_AUTOINSTALL="--defaultdeps" cpan DBD::SQLite
	PERL_AUTOINSTALL="--defaultdeps" cpan Tapper::Schema
	PERL_AUTOINSTALL="--defaultdeps" cpan Tapper::CLI
	PERL_AUTOINSTALL="--defaultdeps" cpan Tapper::Reports::Web
	PERL_AUTOINSTALL="--defaultdeps" cpan Tapper::Reports::Receiver
	PERL_AUTOINSTALL="--defaultdeps" cpan Tapper::Reports::API

databases:
#
# Prepare mysql-server
#
	@echo "########## Prepare mysql-server"
	echo "create user tapper identified by 'tapper';" | mysql -uroot
	echo "create database reportsdb;" | mysql -uroot -p
	echo "grant all on reportsdb.* to tapper@'%';" | mysql -uroot
	echo "create database testrundb;" | mysql -uroot -p
	echo "grant all on testrundb.* to tapper@'%';" | mysql -u root
	yes | tapper-db-deploy init --db ReportsDB
	yes | tapper-db-deploy init --db TestrunDB
	@echo "(Newqueue fails if already exists. Ignore.)"
	-tapper-testrun newqueue --name AdHoc --prio 1000

examplemachines:
#
# Add known test machines
#
	@echo "########## Add known test machines"
	tapper-testrun newhost --name $(TESTMACHINE1)
	tapper-testrun newhost --name $(TESTMACHINE2)
#
# Add machine features (no public frontend tool available)
#
	@echo "########## Add machine features"
# machine1
	echo "insert into host_feature(host_id, entry, value)  values ((select id from host where name = '$(TESTMACHINE1)'),     'mem',  4096);" | mysql testrundb -utapper -ptapper
	echo "insert into host_feature(host_id, entry, value)  values ((select id from host where name = '$(TESTMACHINE1)'),   'cores',     4);" | mysql testrundb -utapper -ptapper
	echo "insert into host_feature(host_id, entry, value)  values ((select id from host where name = '$(TESTMACHINE1)'),  'vendor', 'AMD');" | mysql testrundb -utapper -ptapper
	echo "insert into host_feature(host_id, entry, value)  values ((select id from host where name = '$(TESTMACHINE1)'), 'has_ecc',     1);" | mysql testrundb -utapper -ptapper
# machine1
	echo "insert into host_feature(host_id, entry, value)  values ((select id from host where name = '$(TESTMACHINE2)'),     'mem',    2048);" | mysql testrundb -utapper -ptapper
	echo "insert into host_feature(host_id, entry, value)  values ((select id from host where name = '$(TESTMACHINE2)'),   'cores',       2);" | mysql testrundb -utapper -ptapper
	echo "insert into host_feature(host_id, entry, value)  values ((select id from host where name = '$(TESTMACHINE2)'),  'vendor', 'Intel');" | mysql testrundb -utapper -ptapper
	echo "insert into host_feature(host_id, entry, value)  values ((select id from host where name = '$(TESTMACHINE2)'), 'has_ecc',       0);" | mysql testrundb -utapper -ptapper

tapperconfig:
#
# Install Tapper config
	@echo "########## Install Tapper config"
	cp $(STARTERKITDIR)/etc/tapper.cfg /etc/

receiver:
#
# start scripts for reports-receiver
#
	@echo "########## start scripts for reports-receiver"
	cp $(STARTERKITDIR)/etc/init.d/tapper_reports_receiver_daemon /etc/init.d/
	insserv tapper_reports_receiver_daemon
	/etc/init.d/tapper_reports_receiver_daemon restart

api:
#
# start scripts for reports-api
#
	@echo "########## start scripts for reports-api"
	cp $(STARTERKITDIR)/etc/init.d/tapper_reports_api_daemon /etc/init.d/
	insserv tapper_reports_api_daemon
	/etc/init.d/tapper_reports_api_daemon restart

web:
#
# start scripts for web frontend
#
	@echo "########## start scripts for web frontend"
	cp $(STARTERKITDIR)/apache2/conf.d/tapper_reports_web.conf /etc/apache2/conf.d/
	/etc/init.d/apache2 restart
	@echo "We wait some seconds for the daemons to come up..."
	sleep 5

tftpserver:
#
# start scripts for web frontend
#
	cp $(STARTERKITDIR)/netboot/bzImage /tftpboot/
	ln -s $(TFTPBOOTDIR) /tftpboot/tftpboot

testreport:
# test report
	OURHOSTNAME=$$(perl -MSys::Hostname -e 'print Sys::Hostname::hostname') ;\
	  OURTAPPERPORT=$$(echo $$(cat /etc/tapper.cfg |grep '^report_port:'|cut -d: -f2)) ; \
	  cat $(STARTERKITDIR)/misc/starterkit.tap | sed -e "s/TAPPERHOST/$$OURHOSTNAME/" | \
	  netcat -q5 -w5 $(TAPPER_SERVER) $$OURTAPPERPORT
# look at frontend
	@echo "*** You should now be able to view reports here:"
	@echo "    http://$(TAPPER_SERVER)/tapper"

tapperhost: intro dependencies installernfsroot baseimage64file \
            nfsrootdir clientpkg64 workingdirs optperl nfsserver libdeps perlpkgs \
            databases examplemachines tapperconfig receiver api web tftpserver \
            testreport

engage: tapperhost

so: engage

it:
	@echo "Make it so!"