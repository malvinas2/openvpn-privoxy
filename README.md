# OpenVPN Privoxy Docker

Docker container for setting up a [Privoxy](https://www.privoxy.org/) proxy that pushes traffic over an
[OpenVPN](https://openvpn.net/) connection.

Build Docker image:
```
docker build -t malvinas2/openvpn-privoxy .
```

Run Docker container:

```
docker run -d \
     --device=/dev/net/tun --cap-add=NET_ADMIN \
     -v /etc/localtime:/etc/localtime:ro \
     -p 8888:8118 \
	 -e PROVIDER=my_vpn_provider \
     -e SERVER=my_vpn_server \
     -e USERNAME=my_vpn_username \
     -e PASSWORD=my_vpn_password \
	 --restart unless-stopped \
     --name openvpn-privoxy malvinas2/openvpn-privoxy
```

Or with this `docker-compose.yml`:

```yaml
---
version: "3"
services:
  openvpn-privoxy:
    image: malvinas2/openvpn-privoxy
    container_name: openvpn-privoxy
    environment:
      - PROVIDER=xxxxxxxxxxxxxxxxxxxxxxxx
      - SERVER=xxxxxxxxxxxxxxxxxxxxxxxx
      - USERNAME=xxxxxxxxxxxxxxxxxxxxxxxx
      - PASSWORD=xxxxxxxxxxxxxxxxxxxxxxxx
    volumes:
      - /etc/localtime:/etc/localtime:ro
    ports:
      - 8888:8118
    restart: unless-stopped
    devices:
      - /dev/net/tun
    cap_add:
      - NET_ADMIN
```

This will start a Docker container that

1. initializes a `OpenVPN` CLI configuration
2. sets up an OpenVPN connection to your VPN Provider with your VPN account details, and
3. starts a Privoxy server, accessible at http://127.0.0.1:8888, that directs traffic over your VPN connection.

Test:

```
curl --proxy http://127.0.0.1:8888 https://ipinfo.io/country
```


## Features

### Multiple VPN connections on the same machine

While not impossible, it is quite the networking feat to route traffic over specific VPN connections. 
With this Docker image you can run multiple containers, each setting up a different VPN connection _which doesn't affect 
your host's networking_. Routing traffic over a specific VPN connection is then
as simple as configuring a target application's proxy server.

### Share a VPN connection between devices on your LAN

Run a container on one machine, and configure multiple devices on your network
to connect to its proxy server. All connections that use that proxy server will
be routed over the same VPN connection.

### Free privacy filtering, courtesy of [Privoxy](https://www.privoxy.org/)

Why did I choose Privoxy? Mostly because it's the simplest HTTP proxy to
configure, that I've used before.

### ProtonVPN's DNS leak protection

In case you're using ProtonVPN as VPN provider `/etc/resolv.conf` 
will be updated while a container is running. It's recreated
by Docker on container restart, but that doesn't matter, since 
the script will modify it during startup.

## Configuration

You can set any of the following container environment variables with
`docker run`'s `-e` options.

### `PROVIDER`

**Required.** This is the name of your VPN service. Must match the folder in the `services` directory, e.g. `proton` 

Default: `proton`

### `PROTOCOL`

The protocol that the OpenVPN tunnel will use: `udp` or `tcp`. 

Default: `udp`

### `SERVER`

**Required.** Which VPN endpoint to connect to. Must match a `services/VPN_SERVICE/PROTOCOL` file, without the extension, e.g. `de-11` 

Default: _empty_

### `USERNAME` and `PASSWORD`

**Required.** This is your VPN service account username and password. 

### `HOST_NETWORK`

If you want to expose your proxy server to your local network, you need to
specify that network in `HOST_NETWORK`, so that it can be routed back through
your Docker network. E.g. if your LAN uses the 192.168.1.0/24 network, add
`-e HOST_NETWORK=192.168.1.0/24` to your `docker run` command.

Default: _empty_ (no network is routed)

### `DNS_SERVERS_OVERRIDE`

Comma-separated list of DNS servers to use, overriding whatever was set by
OpenVPN. For example, to use Quad9 DNS servers, set
`DNS_SERVERS_OVERRIDE=9.9.9.9,149.112.112.112`. 
In case you prefer Cloudfare use `1.1.1.1` or `8.8.8.8` for Google. 

Default: _empty_ 

## What VPN services are supported?

The following is a list of currently supported VPN services. This image is designed to be easily expandable, and new VPN services can be easily added. 

List of services currently supported:

| Service | VPN_SERVICE value |
| --- | --- |
| [TunnelBear](https://www.tunnelbear.com) | tunnelbear |
| [Private Internet Access (PIA)](https://www.privateinternetaccess.com) | pia |
| [Proton VPN](https://protonvpn.com) | proton |

## How to add support for a new VPN service

Adding support for a new VPN service is generall accomplished by copying in the `*.ovpn` files to the service's folder.

Lets walk through an example of adding support for PIA.

* Under the `services` folder, create a new folder for the service. In this case, name it `pia`.
* Create two sub-folders, named `udp` and `tcp`. 
* Add the `*.ovpn` and supporting files from your VPN service.
* Edit the `*.ovpn` files to ensure file system paths point properly to other files, such as key files.
* E.G: `ca CACertificate.crt` becomes `/services/pia/ca CACertificate.crt`
