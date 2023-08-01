include /usr/share/dpkg/pkg-info.mk

GITVERSION:=$(shell git rev-parse HEAD)

KERNEL_DEB=proxmox-default-kernel_$(DEB_VERSION)_all.deb
HEADERS_DEB=proxmox-default-headers_$(DEB_VERSION)_all.deb

BUILD_DIR=proxmox-kernel-meta_$(DEB_VERSION)
DSC=proxmox-kernel-meta_$(DEB_VERSION).dsc

DEBS=$(KERNEL_DEB) $(HEADERS_DEB)

.PHONY: deb dsc
deb: $(DEBS)
dsc: $(DSC)

$(BUILD_DIR): debian
	rm -rf $@ $@.tmp
	mkdir $@.tmp
	cp -a debian $@.tmp/
	cd $@.tmp; debian/rules debian/control
	echo "git clone git://git.proxmox.com/git/pve-kernel-meta.git\\ngit checkout $(GITVERSION)" > $@.tmp/debian/SOURCE
	mv $@.tmp $@

$(HEADERS_DEB): $(KERNEL_DEB)
$(KERNEL_DEB): $(BUILD_DIR)
	cd $(BUILD_DIR); dpkg-buildpackage -b -uc -us
	lintian $(DEBS)

$(DSC): $(BUILD_DIR)
	cd $(BUILD_DIR); dpkg-buildpackage -S -uc -us
	lintian $(DSC)

sbuild: $(DSC)
	sbuild $(DSC)

.PHONY: upload
upload: UPLOAD_DIST ?= $(DEB_DISTRIBUTION)
upload: $(DEBS)
	tar cf - $(DEBS)|ssh repoman@repo.proxmox.com -- upload --product pve,pmg,pbs --dist $(UPLOAD_DIST)

.PHONY: clean distclean
distclean: clean
clean:
	rm -rf *~ proxmox-kernel-meta*/ proxmox-kernel-meta*.tar.* *.deb *.dsc *.changes *.buildinfo *.build
