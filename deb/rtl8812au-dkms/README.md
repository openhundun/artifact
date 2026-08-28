# rtl8812au-dkms

## Build

```sh
./build.sh
```

## Install

```sh
sudo apt install --reinstall ./rtl8812au-dkms_5.6.4.2-1_all.deb
```

## Use as client

#### 1. Dependencies

```sh
sudo apt install dhcpcd wpa_supplicant
```

#### 2. Mode (managed)

```sh
sudo ip link set wlx<mac> down
sudo iw dev wlx<mac> set type managed
sudo ip link set wlx<mac> up
```

#### 3. Config

```sh
sudo tee /etc/wpa_supplicant/wpa_supplicant.conf > /dev/null << EOF
ctrl_interface=/run/wpa_supplicant
network={
    ssid="<ssid>"
    psk="<password>"
}
EOF
```

#### 4. Connect

```sh
sudo wpa_supplicant -B -i wlx<mac> -c /etc/wpa_supplicant/wpa_supplicant.conf -D nl80211
```

```sh
sudo dhcpcd wlx<mac>
```

## Use as AP

#### 1. Dependencies

```sh
sudo apt install hostapd dnsmasq nftables iw
```

#### 2. Mode (AP)

```sh
sudo ip link set wlx<mac> down
sudo iw dev wlx<mac> set type ap
sudo ip link set wlx<mac> up
```

#### 3. Network

```sh
sudo tee /etc/sysctl.d/99-forward.conf > /dev/null << EOF
net.ipv4.ip_forward = 1
net.ipv6.conf.all.forwarding = 1
net.ipv6.conf.all.accept_dad = 0
net.ipv6.conf.default.accept_dad = 0
EOF
```

```sh
sudo sysctl --system
```

```sh
sudo iw reg set CN
```

```sh
sudo ip addr add 192.168.50.1/24 dev wlx<mac>
```

#### 4. NAT & DHCP & DNS

```sh
sudo tee /etc/nftables.conf > /dev/null << EOF
#!/usr/sbin/nft -f
table inet nat
delete table inet nat
table inet nat {
    chain postrouting {
        type nat hook postrouting priority srcnat; policy accept;
        ip saddr 192.168.50.0/24 masquerade
    }
}
EOF
```

```sh
sudo tee /etc/dnsmasq.d/ap.conf > /dev/null << EOF
interface=wlx<mac>
bind-dynamic
no-resolv
server=119.29.29.29
dhcp-authoritative
dhcp-range=192.168.50.2,192.168.50.254,24h
dhcp-option=option:router,192.168.50.1
dhcp-option=option:dns-server,192.168.50.1
EOF
```

#### 5. AP

```sh
sudo tee /etc/hostapd/hostapd.conf > /dev/null << EOF
interface=wlx<mac>
driver=nl80211
ssid=<ssid>
hw_mode=a
channel=149
country_code=CN
ieee80211n=1
ht_capab=[HT40+][SHORT-GI-20][SHORT-GI-40][RX-STBC1]
ieee80211ac=1
vht_oper_chwidth=0
wpa=2
wpa_passphrase=<passwd>
EOF
```
