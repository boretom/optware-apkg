#!/bin/sh

HOST_ARCH=$(uname -m)
PKG_DIR=$APKG_PKG_DIR
OPTWARE_PKG_DIR=/volume1/Optware
BOOTSTRAP_SCRIPT=$PKG_DIR/bin/asustor-${HOST_ARCH}-bootstrap_1.2-7_${HOST_ARCH}.xsh

INSTALL_LOG=$PKG_DIR/boostrap_$(date +"%Y%m%d_%H%M%S").log

case "$APKG_PKG_STATUS" in
	install)
		# if there's no opt sub-directory in the app directory run
		# the Optware bootstraping script
		if [[ ! -d $PKG_DIR/opt ]]; then
			$BOOTSTRAP_SCRIPT > $INSTALL_LOG 2>&1
			echo "[PKG INSTALL] copy profile and profile.d to /opt/etc" >> $INSTALL_LOG 2>&1
			cp -a $PKG_DIR/etc/profile /opt/etc/
			cp -aR $PKG_DIR/etc/profile.d /opt/etc/
		else
			echo "[PKG INSTALL] '/opt' dir already exists. Won't do anything" >> $INSTALL_LOG 2>&1
		fi
		# remove the unnecessary /etc/init.d/S99Optware file - not the best solution but a lot easier then
		# changing the Optware bootstrap script template
		if [[ -f /etc/init.d/S99Optware ]]; then
			echo "[PKG INSTALL] remove unnecessary /etc/init.d/S99Optware script" >> $INSTALL_LOG 2>&1
			rm /etc/init.d/S99Optware
		fi
		# copy local package feed template (empty package list) if
		if [[ ! -f $OPTWARE_PKG_DIR/local-feed/asustor-${HOST_ARCH}/cross/unstable/Packages.filelist ]]; then
			echo "[PKG INSTALL] copy local package feed template to Optware local feed directory" >> $INSTALL_LOG 2>&1
			cp -aR $PKG_DIR/local-feed/ $OPTWARE_PKG_DIR/
		fi
		# enable i686g25 feed if HOST_ARCH is i686	
		if [[ ${HOST_ARCH} == i686 ]]; then
			echo "[PKG INSTALL] enable i686g25 feed in /opt/etc/ipkg.conf" >> $INSTALL_LOG 2>&1
			if [[ -f $PKG_DIR/opt/etc/ipkg.conf ]]; then
				sed -i -e 's$^# src/gz i686-g25$src/gz i686-g25$g' $PKG_DIR/opt/etc/ipkg.conf
			fi
		fi
		# update the package list
		$PKG_DIR/opt/bin/ipkg update >> $INSTALL_LOG 2>&1
		;;
	upgrade)
		;;
	*)
		;;
esac

exit 0
