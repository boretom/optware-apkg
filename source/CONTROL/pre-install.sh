#!/bin/sh

case "$APKG_PKG_STATUS" in
	install)
		;;
	upgrade)
		mv -f $APKG_PKG_DIR/opt/ $APKG_TEMP_DIR
		;;
	*)
		;;
esac

exit 0
