#!/bin/sh -e
NAME="Optware ipkg"
HOST_ARCH=$(uname -m)
PKG_PATH=/usr/local/AppCentral/optware
CD=${PKG_PATH}/bin/coreutils-${HOST_ARCH}-cp
FIND=/usr/bin/find

if test -z "${REAL_OPT_DIR}"; then
   # next line to be replaced according to OPTWARE_TARGET
   REAL_OPT_DIR=/usr/local/AppCentral/optware/opt
fi

. /lib/lsb/init-functions

function move_opt () {
	if test "$1" = "to-optware"; then
		# move file from /opt to our ./opt
		cd /opt
		$FIND ./ -type l -exec $CP --parent -pP {} ${PKG_PATH}/opt/ \;
	elif test "$1" = "from-optware"; then
		echo "not implemented yet!"
		exit 1
	else
		echo "not argument passed!"
		exit 1
	fi
}

case "$1" in
    start)
	echo "Starting $NAME"
	# check if there are already symbolic links in /opt and move
	# them to our opt
	move_opt "to-optware"

	if test -n "${REAL_OPT_DIR}"; then
	    if ! grep ' /opt ' /proc/mounts >/dev/null 2>&1 ; then
		mkdir -p /opt
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
	sed -i -e '%^export ENV=/opt/etc/profile$%d' /etc/profile

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
