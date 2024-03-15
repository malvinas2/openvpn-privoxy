#!/bin/sh

# Create the necessary file structure for /dev/net/tun
# required to run on docker swarm, as there are no devices available
if [ ! -c /dev/net/tun ]; then
  if [ ! -d /dev/net ]; then
    mkdir -m 755 /dev/net
  fi
  mknod /dev/net/tun c 10 200
  chmod 0755 /dev/net/tun
  echo "Created /dev/net/tun."
fi


# VPN Provider
VPN_PROVIDER_FOLDER="/etc/openvpn/$PROVIDER"
# VPN protocol
VPN_PROTOCOL_FOLDER="$VPN_PROVIDER_FOLDER/$PROTOCOL"
# VPN server configuration file
VPN_OVPN="$VPN_PROTOCOL_FOLDER/$SERVER.ovpn"

# Extra params passed to openvpn client. Here: Firewall Setup, see https://community.openvpn.net/openvpn/wiki/Openvpn23ManPage
VPN_EXTRAS="--ping 15"

# Setup the user/pass login file
rm -f /etc/openvpn/credentials
touch /etc/openvpn/credentials
# VPN user/pass file
VPN_AUTH_FILE="/etc/openvpn/credentials"
echo "$USERNAME" >> $VPN_AUTH_FILE
echo "$PASSWORD" >> $VPN_AUTH_FILE
# Debugging
echo "--- VPN Configuration ---"
echo "    OVPN configuration file: $VPN_OVPN"
echo "    VPN auth file: $VPN_AUTH_FILE"

# Verify the vpn provider exists
if [ ! -d "$VPN_PROVIDER_FOLDER" ]; then
  echo "Invalid VPN provider: $PROVIDER"
  exit 1
fi

# Verify the vpn service file exists
if [ ! -d "$VPN_PROTOCOL_FOLDER" ]; then
  echo "Invalid VPN service: $PROTOCOL"
  exit 1
fi

# Verify the vpn config file exists
if [ ! -f "$VPN_OVPN" ]; then
  echo "Unable to find VPN server: $SERVER"
  exit 1
fi

# Verify if vpn provider is proton to modify resolv.conf
if [ "$PROVIDER" = "proton" ]; then
  cp /etc/openvpn/update-resolv-conf_proton /etc/openvpn/update-resolv-conf
fi


# Start the connection as background service
echo "--- Starting VPN Client ---"
# See https://community.openvpn.net/openvpn/wiki/Openvpn23ManPage
# shellcheck disable=SC2086
openvpn $VPN_EXTRAS --config "$VPN_OVPN" --auth-user-pass $VPN_AUTH_FILE --daemon


# Manually update DNS server
# This needs to run at this point, because OpenVPN may have changed the
# DNS servers in /etc/resolv.conf.
if [ -n "$DNS_SERVERS_OVERRIDE" ]; then
  echo "--- Setup DNS server manually ---"
  echo "$DNS_SERVERS_OVERRIDE" | sed -e 's/^/nameserver /' -e 's/,/\nnameserver /' > /etc/resolv.conf
fi


# Setup route for host network
if [ -n "$HOST_NETWORK" ]; then
  echo "--- Setup route for host network ---"
  gw=$(ip route | awk '$1 == "default" { print $3 }')
  ip route add "$HOST_NETWORK" via "$gw"
fi


# echo "--- Verfiy location ---"
# sleep 2
# curl -s https://ipinfo.io/city


# Setup and start Privoxy 
CONFFILE="/etc/privoxy/config"
PIDFILE="/var/run/privoxy.pid"
if [ ! -f "$CONFFILE" ]; then
  echo "Configuration file $CONFFILE not found!"
  exit 1
fi
echo "--- Starting Privoxy ---"
/usr/sbin/privoxy --no-daemon --pidfile "$PIDFILE" "$CONFFILE"

# END
