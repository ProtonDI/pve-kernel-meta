include /usr/share/dpkg/pkg-info.mk

export KERNEL_VER=6.2
export KERNEL_ABI=6.2.11-2-pve

GITVERSION:=$(shell git rev-parse HEAD)

KERNEL_DEB=pve-kernel-${KERNEL_VER}_${DEB_VERSION_UPSTREAM_REVISION}_all.deb
HEADERS_DEB=pve-headers-${KERNEL_VER}_${DEB_VERSION_UPSTREAM_REVISION}_all.deb

BUILD_DIR=build

DEBS=${KERNEL_DEB} ${HEADERS_DEB}

.PHONY: deb
deb: ${DEBS}

${HEADERS_DEB}: ${KERNEL_DEB}
${KERNEL_DEB}: debian
	rm -rf ${BUILD_DIR}
	mkdir -p ${BUILD_DIR}/debian
	rsync -a * ${BUILD_DIR}/
	cd ${BUILD_DIR}; debian/rules debian/control
	echo "git clone git://git.proxmox.com/git/pve-kernel-meta.git\\ngit checkout ${GITVERSION}" > ${BUILD_DIR}/debian/SOURCE
	cd ${BUILD_DIR}; dpkg-buildpackage -b -uc -us
	lintian ${DEBS}

.PHONY: upload
upload: UPLOAD_DIST ?= $(DEB_DISTRIBUTION)
upload: ${DEBS}
	tar cf - ${DEBS}|ssh repoman@repo.proxmox.com -- upload --product pve,pmg,pbs --dist $(UPLOAD_DIST)

.PHONY: clean distclean
distclean: clean
clean:
	rm -rf *~ ${BUILD_DIR} *.deb *.dsc *.changes *.buildinfo
