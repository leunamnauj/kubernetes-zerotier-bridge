#!/bin/sh

set -e

: "${ZT_NETWORK_IDS?"ZT Need to set ZT_NETWORK_IDS"}"

# set default path
: "${CADDYFILE_PATH:=/etc/caddy/Caddyfile}"

if [ -n "$ZT_IDENTITY_PUBLIC" ]; then
	echo "$ZT_IDENTITY_PUBLIC" > /var/lib/zerotier-one/identity.public
elif [ -n "$ZT_IDENTITY_PUBLIC_PATH" ]; then
	cp "$ZT_IDENTITY_PUBLIC" /var/lib/zerotier-one/identity.public
fi

if [ -n "$ZT_IDENTITY_SECRET" ]; then
	echo "$ZT_IDENTITY_SECRET" > /var/lib/zerotier-one/identity.secret
elif [ -n "$ZT_IDENTITY_SECRET_PATH" ]; then
	cp "$ZT_IDENTITY_SECRET_PATH" /var/lib/zerotier-one/identity.secret
fi

if [ ! -f /var/lib/zerotier-one/identity.secret ]; then
	echo "ZT /var/lib/zerotier-one/identity.secret not found! Will generate my own secret identity..."
	zerotier-idtool generate > /var/lib/zerotier-one/identity.secret
fi

if [ ! -f /var/lib/zerotier-one/identity.public ]; then
	echo "ZT /var/lib/zerotier-one/identity.public not found! Will generate my own public identity..."
	zerotier-idtool getpublic /var/lib/zerotier-one/identity.secret > /var/lib/zerotier-one/identity.public
fi

if [ ! -f "$CADDYFILE_PATH" ]; then
	echo "$CADDYFILE_PATH not found!"
	exit 1
fi

# start zerotier and daemonize
zerotier-one -d -p0

# let zerotier daemon startup
sleep 1

echo "ZT Identity: $(zerotier-cli info -j | jq -r .address)"

has_ip() {
	zerotier-cli listnetworks -j | jq -er '.[] | select(.id == "'$1'") | .assignedAddresses | length > 0' &>/dev/null
}

for network_id in $ZT_NETWORK_IDS; do
	(	
	    if [ "$network_id" = "8056c2e21c000001" ]; then
			echo "ZT WARNING! You are connecting to ZeroTier's Earth network!"
	  		echo "ZT If you join this or any other public network, make sure your computer is up to date on all security patches and you've stopped, locally firewalled, or password protected all services on your system that listen for outside connections."
	    fi
  
	    echo "ZT $network_id: Joining network... `zerotier-cli join "$network_id"`"

	    # Auto accept the new client
	    if [ $AUTOJOIN == "true"  ]; then
			echo "ZT Auto accept the new client"
			host_id="$(zerotier-cli info -j | jq -r .address)"
			# If ip is provided will be set
			if [ -n "$ZT_IP" ]; then 
				echo "ZT Set ip address to $ZT_IP"
				curl -X POST -H "Authorization: Bearer $ZT_AUTHTOKEN" -d '{"config":{"authorized":true,"ipAssignments":["10.147.19.50"]}}' "https://my.zerotier.com/api/network/$network_id/member/$host_id"
			else
				curl -X POST \
					-H "Authorization: Bearer $ZT_AUTHTOKEN" \
					-d '{"config":{"authorized":true}}' \
					"https://my.zerotier.com/api/network/$network_id/member/$host_id"  
			fi  
			# If hostname is provided will be set
			if [ -n "$ZT_HOSTNAME" ]; then
				echo "ZT Set hostname"
				curl -s -XPOST \
					-H "Authorization: Bearer $ZT_AUTHTOKEN" \
					-d "{\"name\":\"$ZT_HOSTNAME\"}" \
					"https://my.zerotier.com/api/network/$network_id/member/$host_id"
			fi
	    fi

		while ! has_ip $network_id; do
			echo "ZT $network_id: waiting for IP(s)..."
			sleep 2
		done

		ips="`zerotier-cli listnetworks -j | jq -r '.[] | select(.id == "'$network_id'") | .assignedAddresses | join(", ")'`"
		echo "ZT $network_id: has address(es) $ips"
	)&
done

wait

echo "Starting Caddy server..."
exec caddy run --adapter caddyfile --config "$CADDYFILE_PATH"