#!/bin/sh -e
NAME="Optware ipkg"
HOST_ARCH=$(uname -m)
PKG_PATH=/usr/local/AppCentral/optware
LOGFILE=/tmp/optware-start-stop.log

CP=${PKG_PATH}/bin/coreutils-${HOST_ARCH}-cp
#FIND=/usr/bin/find
FIND=${PKG_PATH}/bin/findutils-${HOST_ARCH}-find

if test -z "${REAL_OPT_DIR}"; then
   # next line to be replaced according to OPTWARE_TARGET
   REAL_OPT_DIR=/usr/local/AppCentral/optware/opt
fi

. /lib/lsb/init-functions
. ${PKG_PATH}/lib/sh-functions

case "$1" in
    start)
	echo "Starting $NAME"
	# check if there are already symbolic links in /opt and move
	# them to our opt
	if move_opt "to-optware"; then
		echo "move_opt didn't succeed" >> $LOGFILE
	else
		echo "move_opt did succeed" >> $LOGFILE
	fi

	if test -n "${REAL_OPT_DIR}"; then
	    if ! grep ' /opt ' /proc/mounts >/dev/null 2>&1 ; then
			mkdir -p /opt ${REAL_OPT_DIR}
			mount -o bind ${REAL_OPT_DIR} /opt
	    fi
	fi
	if ! grep 'export ENV=/opt/etc/profile' /etc/profile ; then
	   echo 'export ENV=/opt/etc/profile' >> /etc/profile
	fi

	# run the optware init scripts
	[ -x /opt/etc/rc.optware ] && /opt/etc/rc.optware
	;;
    stop)
	echo "Stopping $NAME"
	## TODO : using lsof (install if necessary) to determine if
	## any apps running on /opt and stop them
	## -> does that really make sense?
	if test -n "${REAL_OPT_DIR}"; then
	    if grep ' /opt ' /proc/mounts >/dev/null 2>&1 ; then
			umount /opt
	    fi
	fi
	# remove the ENV variable from /etc/profile
	sed -i -e '/^export ENV=\/opt\/etc\/profile$/d' /etc/profile

	;;
    restart)
	echo "Restarting $NAME"

	;;
    *)
	echo "Usage: $0 {start|stop|restart}"
	exit 2
	;;
esac

exit 0
