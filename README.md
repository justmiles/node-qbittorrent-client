# qBittorrent Client 

Node.js client for qBittorrent

## Requirements

At this time, this has only been tested with version 3.1.8 of the qbittorrent-nox release. 

## Installation

If you have the node package manager, npm, installed:

```shell
npm install --save qbittorrent-client
```

## Getting Started
Examples below.
###getTorrents
```coffee-script
qBittorrent = require 'qbtorrent-client'

client = new qBittorrent
  username: 'admin'
  password: 'adminadmin'
  host: 'localhost'
  port: 8080

client.getTorrents (err, torrents) ->
  console.log err if err
  console.log torrents if torrents
```
