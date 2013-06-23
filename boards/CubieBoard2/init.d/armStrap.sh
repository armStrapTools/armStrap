#! /bin/sh
### BEGIN INIT INFO
# Provides:          
# Required-Start:    $remote_fs $syslog $all
# Required-Stop:
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: First run tasks for armStrap builds, will be deleted once done.
### END INIT INFO

PATH=/sbin:/usr/sbin:/bin:/usr/bin

. /lib/init/vars.sh
. /lib/lsb/init-functions

do_start() {
  [ "$VERBOSE" != no ] && log_begin_msg "Running First run tasks for armStrap builds"
  export DEBIAN_FRONTEND=noninteractive
  /usr/bin/apt-get -f install
  ES=$?
  [ "$VERBOSE" != no ] && log_end_msg $ES
  /usr/sbin/update-rc.d -f armStrap remove
  rm -f /etc/init.d/armStrap.sh
  return $ES
}

case "$1" in
  start)
    do_start
    ;;
  restart|reload|force-reload)
    echo "Error: argument '$1' not supported" >&2
    exit 3
    ;;
  stop)
   ;;
  *)
    echo "Usage: $0 start" >&2
    exit 3
    ;;
esac
