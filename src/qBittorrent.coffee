request   = require 'request'
md5       = require 'md5'
async     = require 'async'
log       = require('debug-logger')('qBittorrent')

class qBittorrent
  constructor: (properties) ->
    log.debug 'Instantiating qBittorrent Instance'

    @username = properties['username'] or 'admin'
    @password =  properties['password'] or 'adminadmin'
    @host = properties['host'] or 'localhost'
    @port = properties['port'] or 8080
    @version = properties['version'] or '3.1.8'
    @ssl = properties['ssl'] or false
    @nonce = properties['nonce'] or null

  login: (cb) ->
    log.debug 'Authenticating'
    switch @version
      when "3.1.8" then @_loginV1(cb) # https://github.com/qbittorrent/qBittorrent/wiki/WebUI-API-Documentation-(qBittorrent-v3.1.x)
      else @_loginV1(cb)

  _loginV1: (cb) ->
    log.debug 'Authenticating using V1'
    client = this
    options =
      method: 'GET'
      url: "http://#{@host}:#{@port}"
      headers:
        'content-type': 'application/json'
      json: true

    request options,  (err, res, body) ->
      if res.headers['www-authenticate']
        auth = {}
        res.headers['www-authenticate'].split(',').map((x)->
          opts = x.split('=').map (x)->
            x.replace(/"/g,'').replace(/\s/g,'')
          auth[opts[0]] = opts[1]
        )[0]
        client.nonce = auth.nonce if auth.nonce
        return cb() if cb
      else
        return cb() if cb

  _makeRequest: (method = 'GET', api = '', form = null, callback) ->
    log.debug "#{method} http://#{@host}:#{@port}#{api} #{form or ''}"

    client = this
    async.waterfall [

      # Authenticate
      (wcb) ->
        return wcb() if client.nonce
        client.login wcb

      # Prepare Request
      (wcb) ->
        options =
          method: method
          url: "http://#{client.host}:#{client.port}#{api}"
          headers:
            authorization: 'Digest '
            'content-type': 'application/json'

        options.headers['content-type'] = 'application/x-www-form-urlencoded' if method == 'POST'
        options.form = form if form

        auth =
          realm: 'Web UI Access'
          username: client.username
          nonce: client.nonce or ''
          uri: api

        auth.response = md5( md5(client.username + ':' + auth.realm + ':' + client.password) + ':' + client.nonce + ':' + md5(method + ':' + api) )

        for key, val of auth
          options.headers.authorization += "#{key}=\"#{val}\", "

        options.headers.authorization = options.headers.authorization.replace(/, $/,'')

        wcb null, options

      # Perform request
      (options, wcb) ->
        request options,  (err, res, body) ->
          log.debug 'REQUEST ERROR: ' + err if err
          wcb err, res, body

    ], (err, res, body) ->

      callback err, body

  _functionName = (fn) ->
    ret = fn.toString()
    ret = ret.substr('function '.length)
    return ret.substr(0, ret.indexOf('('))

  ## Available methods
  shutdown: (callback) ->
    @_makeRequest 'GET', "/command/shutdown", null, callback

  getTorrents: (callback) ->
    log.debug 'Executing getTorrents'
    @_makeRequest 'GET', "/json/torrents", null, callback

  getTorrent: (hash, callback) ->
    log.debug 'Executing getTorrent'
    @_makeRequest 'GET', "/json/propertiesGeneral/#{hash}", null, callback

  getTorrentTrackers: (hash, callback) ->
    log.debug 'Executing getTorrentTrackers'
    @_makeRequest 'GET', "/json/propertiesTrackers/#{hash}", null, callback

  getTorrentContents: (hash, callback) ->
    log.debug 'Executing getTorrentContents. : ' + hash
    @_makeRequest 'GET', "/json/propertiesFiles/#{hash}", null, callback

  getGlobalTransferInfo: (callback) ->
    log.debug 'Executing getGlobalTransferInfo'
    @_makeRequest 'GET', "/json/transferInfo", null, callback

  getPreferences: (callback) ->
    log.debug 'Executing getPreferences'
    @_makeRequest 'GET', "/json/preferences", null, callback

  addTorrentFromURL: (url, callback) ->
    log.debug 'Executing addTorrentFromURL'
    @_makeRequest 'POST', "/command/download", urls: url, callback

  uploadFromDisk: (callback) ->
    log.debug 'Executing uploadFromDisk'
    #TODO: uploadFromDisk support
    callback 'This feature is not yet supported'

  addTrackers: (hash, urls, callback) ->
    log.debug 'Executing addTrackers'
    #@_makeRequest 'POST', "/command/addTrackers", null, callback
    callback 'This feature is not yet supported'

  pauseTorrent: (hash, callback) ->
    log.debug 'Executing pauseTorrent'
    @_makeRequest 'POST', "/command/pause", hash: hash, callback

  pauseAllTorrents: (callback) ->
    log.debug 'Executing pauseAllTorrents'
    @_makeRequest 'POST', "/command/pauseall", null, callback

  resumeTorrent: (hash, callback) ->
    log.debug 'Executing resumeTorrent'
    @_makeRequest 'POST', "/command/resume", hash: hash , callback

  resumeAllTorrents: (callback) ->
    log.debug 'Executing resumeAllTorrents'
    @_makeRequest 'POST', "/command/resumeall", null, callback

  deleteTorrent: (hash, callback) ->
    log.debug 'Executing deleteTorrent'
    @_makeRequest 'POST', "/command/delete", hash: hash, callback

  deleteTorrentAndData: (hashes, callback) ->
    log.debug 'Executing deleteTorrentAndData'
    @_makeRequest 'POST', "/command/deletePerm", hashes: hash, callback

  recheckTorrent: (hash, callback) ->
    log.debug 'Executing recheckTorrent'
    @_makeRequest 'POST', "/command/recheck", hash: hash, callback

  increaseTorrentPriority: (hashes, callback) ->
    log.debug 'Executing increaseTorrentPriority'
    @_makeRequest 'POST', "/command/increasePrio", hashes: hash, callback

  decreaseTorrentPriority: (hashes, callback) ->
    log.debug 'Executing decreaseTorrentPriority'
    @_makeRequest 'POST', "/command/decreasePrio", hashes: hash, callback

  maximalTorrentPriority: (hashes, callback) ->
    log.debug 'Executing maximalTorrentPriority'
    @_makeRequest 'POST', "/command/topPrio", hashes: hash, callback

  manimalTorrentPriority: (hashes, callback) ->
    log.debug 'Executing manimalTorrentPriority'
    @_makeRequest 'POST', "/command/bottomPrio", hashes: hash, callback

  setFilePriority: (hash, id, priority, callback) ->
    log.debug 'Executing setFilePriority'
    @_makeRequest 'POST', "/command/bottomPrio", { hash: hash, id: id, priority: priority }, callback

  getGlobalDownloadLimit: (callback) ->
    log.debug 'Executing getGlobalDownloadLimit'
    @_makeRequest 'POST', "/command/getGlobalDlLimit", null, callback

  setGlobalDownloadLimit: (limit, callback) ->
    log.debug 'Executing setGlobalDownloadLimit'
    @_makeRequest 'POST', "/command/setGlobalDlLimit", limit: limit, callback

  getGlobalUploadLimit: (callback) ->
    log.debug 'Executing getGlobalUploadLimit'
    @_makeRequest 'POST', "/command/getGlobalUpLimit", null, callback

  setGlobalUploadLimit: (limit, callback) ->
    log.debug 'Executing setGlobalUploadLimit'
    @_makeRequest 'POST', "/command/setGlobalUpLimit", limit: limit, callback

  getTorrentDownloadLimit: (hash, callback) ->
    log.debug 'Executing getTorrentDownloadLimit'
    @_makeRequest 'POST', "/command/getTorrentDlLimit", hash: hash, callback

  setTorrentDownloadLimit: (hash, limit, callback) ->
    log.debug 'Executing setTorrentDownloadLimit'
    @_makeRequest 'POST', "/command/setTorrentDlLimit", { hash: hash, limit: limit }, callback

  getTorrentUploadLimit: (hash, callback) ->
    log.debug 'Executing getTorrentUploadLimit'
    @_makeRequest 'POST', "/command/getTorrentUpLimit", hash: hash, callback

  setTorrentUploadLimit: (hash, limit, callback) ->
    log.debug 'Executing setTorrentUploadLimit'
    @_makeRequest 'POST', "/command/setTorrentUpLimit", { hash: hash, limit: limit }, callback

  setPreferences: (preferences = {}, callback) ->
    log.debug 'Executing setPreferences'
    @_makeRequest 'POST', "/command/setTorrentUpLimit", json: JSON.stringify(preferences), callback

module.exports = qBittorrent

