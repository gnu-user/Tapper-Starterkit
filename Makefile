STARTERKIT=tapper-starterkit
EXAMPLEFILES = $(STARTERKIT)/etc/log4perl.cfg \
               $(STARTERKIT)/etc/apache2/conf.d/tapper_reports_web.conf \
               $(STARTERKIT)/etc/init.d/tapper_reports_receiver_daemon \
               $(STARTERKIT)/etc/init.d/tapper_reports_api_daemon \
               $(STARTERKIT)/etc/dhcp.conf \
               $(STARTERKIT)/etc/tapper.cfg \
               $(STARTERKIT)/misc/CPAN-Config.pm \
               $(STARTERKIT)/misc/starterkit.tap \
               $(STARTERKIT)/utils/opt-tapper-package.sh \
               $(STARTERKIT)/utils/prepare-installer-nfsroot-in-chroot \
               $(STARTERKIT)/utils/prepare-baseimage64-in-chroot \
               $(STARTERKIT)/utils/prepare-clientpkg64-in-chroot \
               $(STARTERKIT)/tftpboot/bzImage

CLEANFILES = $(STARTERKIT).tgz

all:
	@echo "For starterkit maintainer:"
	@echo ""
	@echo "  make starterkit  - create tgz archive"
	@echo "  make clean       - cleanup"
	@echo ""
	@echo "For Tapper users:"
	@echo ""
	@echo "  make install     - install the whole system"

starterkit: $(STARTERKIT).tgz

$(STARTERKIT).tgz: $(EXAMPLEFILES)
	tar -czf $(STARTERKIT).tgz $(STARTERKIT)/
	@echo "Don't forget to deploy $(STARTERKIT).tgz to final place."

clean:
	rm -f $(CLEANFILES)

install:
	cd installer && $(MAKE) it so
