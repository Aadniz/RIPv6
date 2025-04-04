# RIPv6 (Random IPv6)
**`RIPv6`** circumvents restrictive IP address-based filter and blocking rules

## How it works

RIPv6 uses multiple IP addresses simultaneously. The implementation is based on the rollover concept of the Pre-publish model of DNSSEC keys (ZSK).

A precondition for RIPv6 is an existing gateway that carries out the routing of the IPv6 network. The specific address range and this gateway are currently defined in the script itself in the Variables section. This section can also be used to define the time value for the rotation of IP addresses. In a later version these values can also be defined using parameters.

IP addresses in the network range are randomly generated by the GenerateAddress() function, which currently generates addresses for a /64 subnet. Support for /48 networks is planned. The original function itself comes from Vladislav V. Prodan.

For the rollover concept I establish an endless while loop. The IP addresses generated are assigned to or removed from the network adapter using the ip command.

## Usage

To start the script, you are required to provide 3 environment variables. `INTERFACE`, `NETWORK_ADDR` and `GATEWAY_ADDR`. Otherwise, there are optional environment variables `SLEEP_TIME` and `MAX_IPS`.

```
[user@host ~]# INTERFACE=eth0 \
    NETWORK_ADDR=2a0d:6116:cafe:1337 \
    GATEWAY_ADDR=2a0d:6116:cafe::1 \
    ./ripv6.sh 
[*] Configuration:
  Interface: eth0
  Network: 2a0d:6116:cafe:1337
  Gateway: 2a0d:6116:cafe::1
  Max IPs: 5
  Sleep Time: 5m
[*] Using existing default route via 2a0d:6116:cafe::1
[+] Adding IP: 2a0d:6116:cafe:1337:b867:905b:7469:c5b9
[+] Adding IP: 2a0d:6116:cafe:1337:b867:905b:7469:c5b9
[+] Adding IP: 2a0d:6116:cafe:1337:a542:9bd7:4da4:9053
[+] Adding IP: 2a0d:6116:cafe:1337:6ee5:3c44:394e:df70
[+] Adding IP: 2a0d:6116:cafe:1337:fbab:44f4:c95a:4491
[+] Adding IP: 2a0d:6116:cafe:1337:b58b:216e:cf75:e807
[+] Adding IP: 2a0d:6116:cafe:1337:5119:78de:04af:d008
[-] Removing IP: 2a0d:6116:cafe:1337:b867:905b:7469:c5b9
[+] Adding IP: 2a0d:6116:cafe:1337:9fa6:bd9b:4641:eb05
[-] Removing IP: 2a0d:6116:cafe:1337:a542:9bd7:4da4:9053
[+] Adding IP: 2a0d:6116:cafe:1337:17b0:9551:452e:d792
[-] Removing IP: 2a0d:6116:cafe:1337:6ee5:3c44:394e:df70
...
```

Once terminated, the created ipv6 addresses will be deleted.

No further modification to the system is required. The web scanner and other applications can be used as normal. The only difference is that requests are now sent with alternating IP addresses. This means that IP-based blocking should not present an obstacle in the future – provided the website can be accessed through IPv6.

## Example systemd setup

Since we configure the script variables with environment variables, this can easily be integrated with systemd.

Create a new file in `/etc/systemd/system/`, called `ripv6.service` for example with the following content:

```
[Unit]
Description=IPv6 Address Rotator
After=network.target
Wants=network.target

[Service]
Type=simple
Environment="INTERFACE=eth0"
Environment="NETWORK_ADDR=2a0d:6116:cafe:1337"
Environment="GATEWAY_ADDR=2a0d:6116:cafe::1"
Environment="SLEEP_TIME=5m"
Environment="MAX_IPS=5"
ExecStart=/path/to/RIPv6/ripv6.sh
Restart=on-failure
RestartSec=30

[Install]
WantedBy=multi-user.target
```

## Planned features

The current version is still in the proof-of-concept phase and will receive a number of improvements in future. Plans include use of parameters for the configuration and support of /48 subnets. Any feedback, changes or additions are appreciated.
