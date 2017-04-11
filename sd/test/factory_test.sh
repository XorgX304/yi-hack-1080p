#!/bin/sh
######################################################
# yi-hack-1080p
######################################################
#
# Features
# ========
#
# * no more cloud!
# * network configuration done in this file. No more need to use a Xiaomi app on a smartphone!
# * telnet server : port 23
# * ftp server    : port 21
# * rtsp server   : port 554
#      rtsp://x.x.x.x/ch0_0.h264     : replace with your ip
#
# How it works
# ============
#
# See https://github.com/xmflsct/yi-hack-1080p

LOG_DIR=/tmp/sd/test/
LOG_FILE=${LOG_DIR}/log.txt

log() {
  echo "$@" >> ${LOG_FILE}
  sync
}

get_config() {
  grep "^$1=" /tmp/sd/test/yi-hack-1080p.cfg  | cut -d"=" -f2
}

######################################################
# start of our custom script
######################################################

echo "Starting to log..." > ${LOG_FILE}
log "[INIT] Your firmware version is:"
log $(cat /home/homever)

### Take over from original init.sh
log "[INIT] Killing original init.sh script."
ps | grep /home/app/init.sh | grep -v "grep" | awk '{print $1}' | xargs kill -9

### set the root password
root_pwd=$(get_config ROOT_PASSWORD)
[ $? -eq 0 ] &&  echo "root:$root_pwd" | chpasswd

### Update a new busybox
if [ ! -f "/home/app/localbin/busybox" ]; then
  log "[BUSYBOX] Copy busybox 1.16.1 to system."
  cp /tmp/sd/test/app/busybox /home/app/localbin/busybox
  chmod +x /home/app/localbin/busybox
else
  log "[good] busybox 1.16.1 is in the system."
fi

### Update RTSP server
if [ ! -f "/home/app/localbin/rtsp2301" ]; then
  log "[RTSP SERVER] Copy rtsp2301 to system."
  cp /tmp/sd/test/app/rtsp2301 /home/app/localbin/rtsp2301
  chmod +x /home/app/localbin/rtsp2301
else
  log "[good] rtsp2301 is in the system."
fi

######################################################
# FROM ORIGINAL INIT.SH
######################################################

sysctl -w vm.dirty_background_ratio=2
sysctl -w vm.dirty_ratio=5
sysctl -w vm.dirty_writeback_centisecs=100
sysctl -w vm.dirty_expire_centisecs=500
echo 5 > /proc/sys/vm/laptop_mode
echo 0 > /proc/sys/vm/swappiness

#/home/base/tools/nvram_tools_h19
bcmver="bd1e"
bcmver1="0bdc"
bcmcmd=$(lsusb|grep "0a5c"|cut -d':' -f3)

lsusb

#/home/app/script/info.sh

if [ $bcmver = $bcmcmd ];then
	/home/base/tools/bcmdl -n /home/app/localbin/nvram_wubb-738gn.txt /home/base/wifi/firmware/fw_bcmdhd_xy159.bin.trx -C 10
	insmod /home/base/wifi/driver/bcmdhd.ko iface_name=wlan0
	himm 0x20120080 0x1c00
	himm 0x20120080 0x1c20
	himm 0x20120080 0x1b0a
	himm 0x20120080 0x1b2a
	echo "BCM" > /tmp/BCM
elif [ $bcmver1 = $bcmcmd ];then
	/home/base/tools/bcmdl -n /home/app/localbin/nvram_wubb-738gn.txt /home/base/wifi/firmware/fw_bcmdhd_xy159.bin.trx -C 10
	insmod /home/base/wifi/driver/bcmdhd.ko iface_name=wlan0
	himm 0x20120080 0x1c00
	himm 0x20120080 0x1c20
	himm 0x20120080 0x1b0a
	himm 0x20120080 0x1b2a
	echo "BCM" > /tmp/BCM
else
	himm 0x20180100 0
	sleep 1
	himm 0x20180100 0x40
	sleep 1
	insmod /home/base/wifi/driver/mt7601Usta.ko
	echo "MTK 7601" > /tmp/MTK
fi

######################################################
# FROM ORIGINAL INIT.SH END
######################################################

### Use our own wpa_supplicant configuration
cp /tmp/sd/test/wpa_supplicant.conf /tmp/wpa_supplicant.conf

### Configure timezone
echo "$(get_config TIMEZONE)" > /etc/TZ

ifconfig
ifconfig wlan0

##### Connect to WiFi

### Original behaviour
rm /etc/resolv.conf
ln -s /tmp/resolv.conf /etc/resolv.conf

### Connect to wifi
log "Check for wifi configuration file..."
log $(find /tmp -name "wpa_supplicant.conf")

log "Start wifi configuration..."
res=$(/home/base/tools/wpa_supplicant -c/tmp/wpa_supplicant.conf -g/var/run/wpa_supplicant-global -iwlan0 -B)
log "Status for wifi configuration=$? (0 is ok)"

if [[ $(get_config DHCP) == "yes" ]] ; then
  log "Do network configuration (DHCP)"
  /sbin/udhcpc -i wlan0 -b -s /home/app/script/default.script
  sleep 5
  log "Done"
else
  log "Do network configuration 1/2 (IP and Gateway)"
  ifconfig wlan0 $(get_config IP) netmask $(get_config NETMASK)
  route add default gw $(get_config GATEWAY)
  log "Done"
  ### configure DNS (google one)
  log "Do network configuration 2/2 (DNS)"
  echo "nameserver $(get_config NAMESERVER)" > /etc/resolv.conf
  log "Done"
fi

### Ping test until connected
until ping -c1 $(get_config TESTSERVER) &>/dev/null; do :; done

log "Configuration is:"
ifconfig | sed "s/^/    /" >> ${LOG_FILE}

### configure time on a NTP server
log "Get time from a NTP server..."
NTP_SERVER=$(get_config NTP_SERVER)
until ping -c1 $(get_config NTP_SERVER) &>/dev/null; do :; done
log "Previous datetime is $(date)"
/home/app/localbin/busybox ntpd -q -p ${NTP_SERVER}
log "Done"
log "New datetime is $(date)"

######################################################
# FROM ORIGINAL INIT.SH
######################################################

### cd /home/app
### ./log_server &
### ./dispatch &

cd /home/hisiko
./load3518e -i
himm 0x201200cc 0xfe033144
himm 0x201200c8 0x23c2e
himm 0x201200d8 0x0d1ec001

insmod /home/base/hi_cipher.ko
### cd /home/app
### ./rmm &
### sleep 2
### ./mp4record &
### ./cloud &
### ./p2p_tnp &
### ./oss &
### ./watch_process &
#lua /home/app/script/cifs.luac /home/app/recbackup &
insmod /home/app/localko/watchdog.ko

######################################################
# FROM ORIGINAL INIT.SH END
######################################################

### Launch Telnet server
log "Starting telnet server..."
/home/app/localbin/busybox telnetd &

### Launch FTP server
log "Starting FTP server..."
/home/app/localbin/busybox tcpsvd -vE 0.0.0.0 21 /home/app/localbin/busybox ftpd -w / &

### Launch RTSP server
log "Starting RTSP server..."
#/home/app/localbin/busybox script -c "/home/app/localbin/rtsp2301" /dev/null
/home/app/localbin/rtsp2301 >& /dev/null &

sync

##### Final initialization

### List the processes after startup
log "Processes after startup :"
ps >> ${LOG_FILE}

### List storage status
log "Storage status :"
df >> ${LOG_FILE}

sync
