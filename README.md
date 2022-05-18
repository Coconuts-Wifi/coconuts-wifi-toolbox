# coconuts-wifi-toolbox
Coconuts-wifi tools in .lua for openwrt

### Pre requisite

on openWrt edit the `system` file

```
$ vim /etc/config/system
```

add a line `server_toolbox` and `server_stats_key`

```
    option server_toolbox_key 'uuid of the core app server'
    option server_toolbox 'https://xxx.yyy.zzz'
```

### Install

##### inside Openwrt Builder

copy the subfolder `coconuts-wifi-toolbox` in `~/openwrt/files/etc/` folder inside the Openwrt Builder

##### On antenna under Openwrt

copy the subfolder `coconuts-wifi-toolbox` in `/etc/` folder of the antenna under Openwrt

```
$ rm coconuts-wifi-toolbox.tar.gz

$ rm /tmp/coconuts-wifi-toolbox.tar.gz
$ rm /etc/coconuts-wifi-toolbox -R

replace ^M 
$ find ./coconuts-wifi-toolbox/ -type f | xargs -Ix sed -i.bak -r 's/\r//g' x
$ find ./coconuts-wifi-toolbox/ -type f -name '*.bak' | xargs -Ix rm x

Compress
$ cd coconuts-wifi-toolbox
$ tar -czvf ../coconuts-wifi-toolbox.tar.gz ./coconuts-wifi-toolbox/

Send
$ scp ./coconuts-wifi-toolbox.tar.gz root@192.168.21.20:/tmp

Uncompress
$ tar -xzvf /tmp/coconuts-wifi-toolbox.tar.gz -C /etc/

change right
$ chmod +x /etc/coconuts-wifi-toolbox/ccw*
$ chown root:root /etc/coconuts-wifi-toolbox/ccw*


$ /etc/coconuts-wifi-toolbox/ccwStatsAntenne.lua
```

### Cron execution

Edit the cron file on antenna under Openwrt

```
$ vim /etc/crontabs/root
```

And add these lines for an execution every 10 seconds

```
* * * * * ( sleep 10 ; /etc/coconuts-wifi-toolbox/ccwScript10.sh )
* * * * * ( sleep 20 ; /etc/coconuts-wifi-toolbox/ccwScript10.sh )
* * * * * ( sleep 30 ; /etc/coconuts-wifi-toolbox/ccwScript10.sh )
* * * * * ( sleep 40 ; /etc/coconuts-wifi-toolbox/ccwScript10.sh )
* * * * * ( sleep 50 ; /etc/coconuts-wifi-toolbox/ccwScript10.sh )
```