#!/bin/bash

function lte () {
  ret=`qmicli -d /dev/cdc-wdm0 --dms-set-operating-mode='online'`
  #sudo qmicli -d /dev/cdc-wdm0 --dms-get-operating-mode
  #sudo qmicli -d /dev/cdc-wdm0 --nas-get-signal-strength
  #sudo qmicli -d /dev/cdc-wdm0 --nas-get-home-network

  # Interface name: wwan0
  iface=`qmicli -d /dev/cdc-wdm0 -w`
  ip link set ${iface} down
  echo 'Y' > /sys/class/net/wwan0/qmi/raw_ip
  ip link set ${iface} up

  # LG U+ or KT
  cmd=`qmicli -d /dev/cdc-wdm0 --nas-get-home-network | grep Description | awk 'BEGIN{FS=": "};{print $2}' | sed "s/'//g"`
  echo "[LTE] Detect USIM: $cmd"
  if [ "$cmd" = "LG U+" ];then
    echo "[LTE] Set U+"
    ret=`qmicli -p -d /dev/cdc-wdm0 --device-open-net='net-raw-ip|net-no-qos-header' --wds-start-network="apn='internet.lguplus.co.kr',username='YOUR_USERNAME',password='YOUR_PASSWORD',ip-type=4" --client-no-release-cid --silent`
  else
    echo "[LTE] Set KT"
    ret=`qmicli -p -d /dev/cdc-wdm0 --device-open-net='net-raw-ip|net-no-qos-header' --wds-start-network="apn='lte.ktfwing.com',username='YOUR_USERNAME',password='YOUR_PASSWORD',ip-type=4" --client-no-release-cid --silent`
  fi

  ret=`udhcpc -i ${iface} -n -q`
}

echo "[LTE] Connect LTE"
lte
recv_pkt=`ping -c 1 -I wwan0 google.co.kr | grep packets | awk 'BEGIN{FS=" "};{print $4}'`
if [ $recv_pkt = 1 ];then
  echo "[LTE] Connected to internet"
  break
else
  echo "[LTE] Not connected"
fi

