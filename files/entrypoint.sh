#!/bin/bash

#zerotier-one
supervisord -c /etc/supervisor/supervisord.conf

[ ! -z $NETWORK_ID ] && { sleep 5; zerotier-cli join $NETWORK_ID || exit 1; }

# waiting for Zerotier IP
# why 2? because you have an ipv6 and an a ipv4 address by default if everything is ok
IP_OK=0
while [ $IP_OK -lt 2 ]
do
  ZTDEV=$( ip addr | grep -i zt | grep -i mtu | awk '{ print $2 }' | cut -f1 -d':' )
  echo "Waiting for a ZeroTier IP on $ZTDEV interface... Accept the new host on my.zerotier.com"
  IP_OK=$( ip addr show dev $ZTDEV | grep -i inet | wc -l )
  sleep 5
done

#
# add route rules
#  from variable
#
if [ ! -z $ROUTES ]
then
  for routeline in $( echo $ROUTES | sed "s@;@\n@g" )
  do
    ADDR="$( echo $routeline | cut -f1 -d',' )"
    GW="$( echo $routeline | cut -f2 -d',' )"
    if [ ! -z $ADDR ] && [ ! -z $GW ]
    then
      echo "adding route ... $ADDR via $GW"
      ip route add "$ADDR" via "$GW"
    fi
  done
  ip route
fi

#
# add route rules
#  from file
#
if [ -e /config/route.list ]
then
  echo "Route file found: /config/route.list"
  cat config/route.list | while read line
  do  
    for routeline in "$( echo $line | grep -iv '^#' )"
    do
      # if empty line found - skip this loop
      [ -z "$routeline" ] && { continue; }

      ADDR="$( echo $routeline | cut -f1 -d',' | cut -f1 -d' ' )"
      GW="$( echo $routeline | cut -f2 -d',' | cut -f2 -d' '  )"
      if [ ! -z $ADDR ] && [ ! -z $GW ]
      then
        echo "adding route ... $ADDR via $GW"
        ip route add "$ADDR" via "$GW"
      fi
    done
  done
  ip route
fi


# Allow FWD
echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
iptables save

# something that keep the container running
tail -f /dev/null