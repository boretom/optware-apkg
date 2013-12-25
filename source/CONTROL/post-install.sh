#!/bin/sh

export HOST_ARCH=$(uname -m)
export PKG_DIR=$APKG_PKG_DIR
export OPTWARE_PKG_DIR=/volume1/Optware

export INSTALL_LOG=$PKG_DIR/bootstrap_$(date +"%Y%m%d_%H%M%S").log
export IPKG_NAME=ipkg-opt_0.99.163-10_${HOST_ARCH}.ipk
export ASUSTOR_LOCAL_FEED=asustor-${HOST_ARCH}-feed.conf
export ASUSTOR_KUPPER_FEED="asustor-${HOST_ARCH}-kupper-org-feed.conf"

. ${PKG_DIR}/lib/sh-functions

case "$APKG_PKG_STATUS" in
	install|upgrade)
		MSG_PREFIX="[pkg $APKG_PKG_STATUS]"
		# copy optware/opt back from temp directory if upgrade
		if [ $APKG_PKG_STATUS = upgrade ]; then
			echo "$MSG_PREFIX backup optware/opt to tmp directory" >> $INSTALL_LOG 2>&1
			mv -f $APKG_TEMP_DIR/opt/ $PKG_DIR	
		fi

		echo "$MSG_PREFIX creating tmp directory for installation" >> $INSTALL_LOG 2>&1
		TMP_DIR=$(mktemp -d -t fluffyXXXXXX)		
		cd $TMP_DIR
		echo "$MSG_PREFIX install the ipkg-opt package"
		mv ${PKG_DIR}/packages/${IPKG_NAME} $TMP_DIR
		rmdir ${PKG_DIR}/packages
		tar -xOvzf ${IPKG_NAME} ./data.tar.gz | tar -C ${PKG_DIR} -xzvf - 2>/dev/null

		echo "$MSG_PREFIX copying symlinks in /opt to optware/opt" >> $INSTALL_LOG 2>&1
		# we're updating and /opt is not symlinked to optware/opt
		move_to_optware_opt
		# still a bit paranoid about deleting everything in /opt so do it complicated ;)
		rm -rf /opt/*
		rm -rf /opt/.[^.]*
		rmdir /opt
		if [ $? -ne 0 ] ; then
			echo "$MSG_PREFIX /opt/ is not empty, aborting..." >> $INSTALL_LOG 2>&1
			exit 1
		fi

		echo "$MSG_PREFIX deleting temporary directory ..." >> $INSTALL_LOG 2>&1
		cd ..
		rm -rf $TMP_DIR

		echo "$MSG_PREFIX copy profile and profile.d to /opt/etc" >> $INSTALL_LOG 2>&1
		cp -a $PKG_DIR/etc/profile $PKG_DIR/opt/etc/
		cp -aR $PKG_DIR/etc/profile.d $PKG_DIR/opt/etc/
		rm -rf $PKG_DIR/etc

		echo "$MSG_PREFIX copy local package feed template (empty package list) if empty" >> $INSTALL_LOG 2>&1
		if [ ! -f $OPTWARE_PKG_DIR/local-feed/asustor-${HOST_ARCH}/cross/unstable/Packages.filelist ]; then
			echo "$MSG_PREFIX copy local package feed template to Optware local feed directory" >> $INSTALL_LOG 2>&1
			cp -aR $PKG_DIR/local-feed/ $OPTWARE_PKG_DIR/
		fi
		rm -rf $PKG_DIR/local-feed/
		if [ ${HOST_ARCH} = i686 ]; then
			echo "$MSG_PREFIX enable i686g25 feed if HOST_ARCH is i686" >> $INSTALL_LOG 2>&1
			if [ -f $PKG_DIR/opt/etc/ipkg.conf ]; then
				sed -i -e 's$^# src/gz i686-g25$src/gz i686-g25$g' $PKG_DIR/opt/etc/ipkg.conf
			fi
		fi

		echo "$MSG_PREFIX create config for local asustor feed" >> $INSTALL_LOG 2>&1
 		[ ! -d $PKG_DIR/opt/etc/ipkg ] && mkdir -p $PKG_DIR/opt/etc/ipkg
		if [ ! -e $PKG_DIR/opt/etc/ipkg/${ASUSTOR_LOCAL_FEED} ]; then
			echo "$MSG_PREFIX creating $PKG_DIR/opt/etc/ipkg/${ASUSTOR_LOCAL_FEED}..." >> $INSTALL_LOG 2>&1
			echo "src/gz asustor-${HOST_ARCH} file://${OPTWARE_PKG_DIR}/local-feed/asustor-${HOST_ARCH}/cross/unstable" > $PKG_DIR/opt/etc/ipkg/${ASUSTOR_LOCAL_FEED}
		fi
		if [ ${HOST_ARCH} = x86_64 ] && [ ! -e $PKG_DIR/opt/etc/ipkg/${ASUSTOR_KUPPER_FEED} ]; then
			echo "$MSG_PREFIX creating $PKG_DIR/opt/etc/ipkg/${ASUSTOR_KUPPER_FEED}..." >> $INSTALL_LOG 2>&1
			echo "src/gz asustor-kupper-${HOST_ARCH} http://optware.kupper.org/asustor-${HOST_ARCH}/cross/unstable" > $PKG_DIR/opt/etc/ipkg/${ASUSTOR_KUPPER_FEED}
		fi
		echo "$MSG_PREFIX sym-link to /opt ... if /opt is empty" >> $INSTALL_LOG 2>&1
		ln -sf ${PKG_DIR}/opt /opt

		echo "$MSG_PREFIX update the package list" >> $INSTALL_LOG 2>&1
		/opt/bin/ipkg update >> $INSTALL_LOG 2>&1
		touch $PKG_DIR/opt/.installed
		;;
	*)
		;;
esac

exit 0
