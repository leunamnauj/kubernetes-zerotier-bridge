#!/usr/bin/env sh

set -e

: "${ZT_NETWORK_ID?"Need to set ZT_NETWORK_ID"}"

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

if [ ! -f /var/lib/zerotier-one/identity.public ]; then
	echo "/var/lib/zerotier-one/identity.public not found!"
	exit 1
fi

if [ ! -f /var/lib/zerotier-one/identity.secret ]; then
	echo "/var/lib/zerotier-one/identity.secret not found!"
	exit 1
fi

if [ ! -f "$CADDYFILE_PATH" ]; then
	echo "$CADDYFILE_PATH not found!"
	exit 1
fi

if [ "$ZT_NETWORK_ID" = "8056c2e21c000001" ]; then
	echo "WARNING! You are connecting to ZeroTier's Earth network!"
	echo "If you join this or any other public network, make sure your computer is up to date on all security patches and you've stopped, locally firewalled, or password protected all services on your system that listen for outside connections."
fi

# start zerotier and daemonize
zerotier-one -d -p0

# let zerotier daemon startup
sleep 1

echo "ZeroTier identity: $(zerotier-cli info -j | jq -r .address)"

has_ip() {
	zerotier-cli listnetworks -j | jq -er '.[] | select(.id == "'$1'") | .assignedAddresses | length > 0' &>/dev/null
}

for network_id in $ZT_NETWORK_ID; do
	(
	  echo "ZT $network_id: Joining network... `zerotier-cli join "$network_id"`"

		while ! has_ip $network_id; do
			echo "ZT $network_id: waiting for IP(s)..."
			sleep 2
		done

		ips="`zerotier-cli listnetworks -j | jq -r '.[] | select(.id == "'$network_id'") | .assignedAddresses | join(", ")'`"
		echo "ZT $network_id: has address(es) $ips"
	)&
done

wait

echo "starting Caddy server..."
exec caddy run --adapter caddyfile --config "$CADDYFILE_PATH"