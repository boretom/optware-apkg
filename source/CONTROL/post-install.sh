#!/bin/sh

HOST_ARCH=$(uname -m)
PKG_DIR=$APKG_PKG_DIR
OPTWARE_PKG_DIR=/volume1/Optware
BOOTSTRAP_SCRIPT=$PKG_DIR/bin/asustor-${HOST_ARCH}-bootstrap_1.2-7_${HOST_ARCH}.xsh

INSTALL_LOG=$PKG_DIR/boostrap_$(date +"%Y%m%d_%H%M%S").log
IPKG_NAME=ipkg-opt_0.99.163-10_i686.ipk
ASUSTOR_LOCAL_FEED=asustor-${HOST_ARCH}-feed.conf

case "$APKG_PKG_STATUS" in
	install)
		echo "[PKG INSTALL] creating tmp directory for installation" >> $INSTALL_LOG 2>&1
		TMP_DIR=$(mktemp -d -t fluffyXXXXXX)		
		cd $TMP_DIR
		echo "[PKG INSTALL] install the ipkg-opt package"
		mv ${PKG_DIR}/packages/${IPKG_NAME} $TMP_DIR
		rmdir ${PKG_DIR}/packages
		tar -xOvzf ${IPKG_NAME} ./data.tar.gz | tar -C ${PKG_DIR} -xzvf - 2>/dev/null

		echo "[PKG INSTALL] sym-link to /opt ... if /opt is empty" >> $INSTALL_LOG 2>&1
		rmdir /opt
		if [ $? -ne 0 ] ; then
			echo "[PKG INSTALL] /opt/ is not empty, aborting..." >> $INSTALL_LOG 2>&1
			exit 1
		fi
		ln -sf ${PKG_DIR}/opt /opt

		echo "[PKG INSTALL] deleting temporary directory ..." >> $INSTALL_LOG 2>&1
		cd ..
		rm -rf $TMP_DIR

		echo "[PKG INSTALL] copy profile and profile.d to /opt/etc" >> $INSTALL_LOG 2>&1
		cp -a $PKG_DIR/etc/profile /opt/etc/
		cp -aR $PKG_DIR/etc/profile.d /opt/etc/

		# remove the unnecessary /etc/init.d/S99Optware file - not the best solution but a lot easier then
		# changing the Optware bootstrap script template
		if [[ -f /etc/init.d/S99Optware ]]; then
			echo "[PKG INSTALL] remove unnecessary /etc/init.d/S99Optware script" >> $INSTALL_LOG 2>&1
			rm /etc/init.d/S99Optware
		fi
		echo "[PKG INSTALL] copy local package feed template (empty package list) if empty" >> $INSTALL_LOG 2>&1
		if [[ ! -f $OPTWARE_PKG_DIR/local-feed/asustor-${HOST_ARCH}/cross/unstable/Packages.filelist ]]; then
			echo "[PKG INSTALL] copy local package feed template to Optware local feed directory" >> $INSTALL_LOG 2>&1
			cp -aR $PKG_DIR/local-feed/ $OPTWARE_PKG_DIR/
		fi
		if [[ ${HOST_ARCH} == i686 ]]; then
			echo "[PKG INSTALL] enable i686g25 feed if HOST_ARCH is i686" >> $INSTALL_LOG 2>&1
			if [[ -f $PKG_DIR/opt/etc/ipkg.conf ]]; then
				sed -i -e 's$^# src/gz i686-g25$src/gz i686-g25$g' $PKG_DIR/opt/etc/ipkg.conf
			fi
		fi
		echo "[PKG INSTALL] create config for local asustor feed" >> $INSTALL_LOG 2>&1
 		[ ! -d /opt/etc/ipkg ] && mkdir -p /opt/etc/ipkg
		if [ ! -e /opt/etc/ipkg/${ASUSTOR_LOCAL_FEED} ]; then
			echo "[PKG INSTALL] creating /opt/etc/ipkg/${ASUSTOR_LOCAL_FEED}..." >> $INSTALL_LOG 2>&1
			echo "src/gz asustor-${HOST_ARCH} file://${OPTWARE_PKG_DIR}/local-feed/asustor-${HOST_ARCH}/cross/unstable" > /opt/etc/ipkg/asustor-${HOST_ARCH}-feed.conf
		fi

		echo "[PKG INSTALL] update the package list" >> $INSTALL_LOG 2>&1
		/opt/bin/ipkg update >> $INSTALL_LOG 2>&1
		;;
	upgrade)
		;;
	*)
		;;
esac

exit 0
