#!/bin/sh -e
HOST_ARCH=$(uname -m)
NAME="Optware ipkg"
PKG_DIR=/usr/local/AppCentral/optware

if test -z "${REAL_OPT_DIR}"; then
   # next line to be replaced according to OPTWARE_TARGET
   REAL_OPT_DIR=/usr/local/AppCentral/optware/opt
fi

. /lib/lsb/init-functions
. ${PKG_DIR}/lib/sh-functions

case "$1" in
    start)
	echo "Starting $NAME"
	if test -n "${REAL_OPT_DIR}"; then
		if [ ! -L /opt ]; then
			move_to_optware_opt
			rm -rf /opt/* && rm -rf /opt/.[^.]*
			# if /opt is not an symlink and the directory is empty
			rmdir /opt
			if [ $? -ne 0 ]; then
				echo "/opt wasn't empty... too bad."
				exit 1
			fi
			ln -s ${REAL_OPT_DIR} /opt
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
		# delete symlink to REAL_OPT_DIR and create a new, empty one
		rm /opt
		mkdir /opt
		move_to_opt
		# delete the empty directories in optware/opt recursively
		$FIND ${PKG_DIR}/opt -depth -type d -empty | xargs rmdir -p
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
