request   = require 'request'
md5       = require 'md5'
async     = require 'async'
semver    = require 'semver'
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
    @authenticated = false

    if semver.lt '3.1.8', @version
      @apiVersion = 'API2'
    else
      @apiVersion = 'API1'

  _makeRequest: (method = 'GET', api = '', form = null, callback) ->
    if typeof form == 'function'
      callback = form
      form = null

    log.debug "#{method} http://#{@host}:#{@port}#{api} #{form or ''}"

    client = this
    async.waterfall [

      # Authenticate
      (wcb) ->
        return wcb() if client.authenticated
        client.login wcb

      # Prepare Request
      (wcb) ->
        options =
          method: method
          url: "http://#{client.host}:#{client.port}#{api}"
          headers:
            'content-type': 'application/json'
            cookie: client.cookie or null

        options.headers['content-type'] = 'application/x-www-form-urlencoded' if method == 'POST'
        options.form = form if form

        if client.apiVersion == 'API1'

          auth =
            realm: 'Web UI Access'
            username: client.username
            nonce: client.nonce or null
            uri: api

          options.headers.authorization = 'Digest '
          auth.response = md5( md5(client.username + ':' + auth.realm + ':' + client.password) + ':' + client.nonce + ':' + md5(method + ':' + api) ) if client.nonce

          for key, val of auth
            options.headers.authorization += "#{key}=\"#{val}\", "

          options.headers.authorization = options.headers.authorization.replace(/, $/,'')

        wcb null, options

      # Perform request
      (options, wcb) ->
        log options
        request options,  (err, res, body) ->
          log.debug 'REQUEST ERROR: ' + err if err
          wcb err, res, body

    ], (err, res, body) ->

      callback err, body

  _functionName = (fn) ->
    ret = fn.toString()
    ret = ret.substr('function '.length)
    return ret.substr(0, ret.indexOf('('))

  shutdown: (callback) ->
    log.debug 'Executing shutdown'
    @_makeRequest 'GET', "/command/shutdown", callback


class API1 extends qBittorrent
  login: (cb) ->
    log.debug 'Authenticating via API1'
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
        client.authenticated = true
        return cb() if cb
      else
        return cb() if cb

  getTorrents: (callback) ->
    log.debug 'Executing getTorrents'
    @_makeRequest 'GET', "/json/torrents", callback

  getTorrent: (hash, callback) ->
    log.debug 'Executing getTorrent'
    @_makeRequest 'GET', "/json/propertiesGeneral/#{hash}", callback

  getTorrentTrackers: (hash, callback) ->
    log.debug 'Executing getTorrentTrackers'
    @_makeRequest 'GET', "/json/propertiesTrackers/#{hash}", callback

  getTorrentContents: (hash, callback) ->
    log.debug 'Executing getTorrentContents. : ' + hash
    @_makeRequest 'GET', "/json/propertiesFiles/#{hash}", callback

  getGlobalTransferInfo: (callback) ->
    log.debug 'Executing getGlobalTransferInfo'
    @_makeRequest 'GET', "/json/transferInfo", callback

  getPreferences: (callback) ->
    log.debug 'Executing getPreferences'
    @_makeRequest 'GET', "/json/preferences", callback

  addTorrentFromURL: (url, callback) ->
    log.debug 'Executing addTorrentFromURL'
    @_makeRequest 'POST', "/command/download", urls: url, callback

  uploadFromDisk: (callback) ->
    log.debug 'Executing uploadFromDisk'
    #TODO: uploadFromDisk support
    callback 'This feature is not yet supported'

  addTrackers: (hash, urls, callback) ->
    log.debug 'Executing addTrackers'
    #@_makeRequest 'POST', "/command/addTrackers", callback
    callback 'This feature is not yet supported'

  pauseTorrent: (hash, callback) ->
    log.debug 'Executing pauseTorrent'
    @_makeRequest 'POST', "/command/pause", hash: hash, callback

  pauseAllTorrents: (callback) ->
    log.debug 'Executing pauseAllTorrents'
    @_makeRequest 'POST', "/command/pauseall", callback

  resumeTorrent: (hash, callback) ->
    log.debug 'Executing resumeTorrent'
    @_makeRequest 'POST', "/command/resume", hash: hash , callback

  resumeAllTorrents: (callback) ->
    log.debug 'Executing resumeAllTorrents'
    @_makeRequest 'POST', "/command/resumeall", callback

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
    @_makeRequest 'POST', "/command/getGlobalDlLimit", callback

  setGlobalDownloadLimit: (limit, callback) ->
    log.debug 'Executing setGlobalDownloadLimit'
    @_makeRequest 'POST', "/command/setGlobalDlLimit", limit: limit, callback

  getGlobalUploadLimit: (callback) ->
    log.debug 'Executing getGlobalUploadLimit'
    @_makeRequest 'POST', "/command/getGlobalUpLimit", callback

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

class API2 extends API1
  login: (cb) ->
    log.debug 'Authenticating via API2 (Using Cookies)'
    client = this
    options =
      method: 'POST'
      url: "http://#{@host}:#{@port}/login"
      headers:
        'content-type': 'application/x-www-form-urlencoded'
      json: true
      form:
        username: @username
        password: @password

    request options,  (err, res, body) ->
      if body == 'Ok.' && res.headers['set-cookie']
        client.authenticated = true
        client.cookie = res.headers['set-cookie'][0]?.match(/.*; /)[0]?.replace(/; $/,'')
      return cb err

  logout: (callback) ->
    @_makeRequest 'POST', "/logout", callback

  getMinimumApiVersion: (callback) ->
    log.debug 'Executing getMinimumApiVersion'
    @_makeRequest 'GET', "/version/api_min", callback

  getqBittorrentVersion: (callback) ->
    log.debug 'Executing getqBittorrentVersion'
    @_makeRequest 'GET', "/version/qbittorrent", callback

  getTorrents: (params, callback) ->
    log.debug 'Executing getTorrents'
    if typeof params == 'function'
      callback = params
      params = null

    @_makeRequest 'GET', "/query/torrents", params, callback

  getTorrent: (hash, callback) ->
    log.debug 'Executing getTorrent'
    @_makeRequest 'GET', "/query/propertiesGeneral/#{hash}", callback

  getTorrentTrackers: (hash, callback) ->
    log.debug 'Executing getTorrentTrackers'
    @_makeRequest 'GET', "/query/propertiesTrackers/#{hash}", callback

  getTorrentContents: (hash, callback) ->
    log.debug 'Executing getTorrentContents. : ' + hash
    @_makeRequest 'GET', "/query/propertiesFiles/#{hash}", callback

  getGlobalTransferInfo: (callback) ->
    log.debug 'Executing getGlobalTransferInfo'
    @_makeRequest 'GET', "/query/transferInfo", callback

  getPreferences: (callback) ->
    log.debug 'Executing getPreferences'
    @_makeRequest 'GET', "/query/preferences", callback

  addTorrentFromURL: (url, callback) ->
    log.debug 'Executing addTorrentFromURL'
    @_makeRequest 'POST', "/command/download", urls: url, callback

  uploadFromDisk: (callback) ->
    log.debug 'Executing uploadFromDisk'
    #TODO: uploadFromDisk support
    callback 'This feature is not yet supported'

  addTrackers: (hash, urls, callback) ->
    log.debug 'Executing addTrackers'
    #@_makeRequest 'POST', "/command/addTrackers", callback
    callback 'This feature is not yet supported'

  pauseTorrent: (hash, callback) ->
    log.debug 'Executing pauseTorrent'
    @_makeRequest 'POST', "/command/pause", hash: hash, callback

  pauseAllTorrents: (callback) ->
    log.debug 'Executing pauseAllTorrents'
    @_makeRequest 'POST', "/command/pauseall", callback

  resumeTorrent: (hash, callback) ->
    log.debug 'Executing resumeTorrent'
    @_makeRequest 'POST', "/command/resume", hash: hash , callback

  resumeAllTorrents: (callback) ->
    log.debug 'Executing resumeAllTorrents'
    @_makeRequest 'POST', "/command/resumeall", callback

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
    @_makeRequest 'POST', "/command/getGlobalDlLimit", callback

  setGlobalDownloadLimit: (limit, callback) ->
    log.debug 'Executing setGlobalDownloadLimit'
    @_makeRequest 'POST', "/command/setGlobalDlLimit", limit: limit, callback

  getGlobalUploadLimit: (callback) ->
    log.debug 'Executing getGlobalUploadLimit'
    @_makeRequest 'POST', "/command/getGlobalUpLimit", callback

  setGlobalUploadLimit: (limit, callback) ->
    log.debug 'Executing setGlobalUploadLimit'
    @_makeRequest 'POST', "/command/setGlobalUpLimit", limit: limit, callback

  getTorrentDownloadLimit: (hash, callback) ->
    log.debug 'Executing getTorrentDownloadLimit'
    @_makeRequest 'POST', "/command/getTorrentsDlLimit", hashes: hash, callback

  setTorrentDownloadLimit: (hash, limit, callback) ->
    log.debug 'Executing setTorrentDownloadLimit'
    @_makeRequest 'POST', "/command/setTorrentsDlLimit", { hashes: hash, limit: limit }, callback

  getTorrentUploadLimit: (hash, callback) ->
    log.debug 'Executing getTorrentUploadLimit'
    @_makeRequest 'POST', "/command/getTorrentsUpLimit", hashes: hash, callback

  setTorrentUploadLimit: (hash, limit, callback) ->
    log.debug 'Executing setTorrentUploadLimit'
    @_makeRequest 'POST', "/command/setTorrentsUpLimit", { hash: hash, limit: limit }, callback

  setPreferences: (preferences = {}, callback) ->
    log.debug 'Executing setPreferences'
    @_makeRequest 'POST', "/command/setTorrentUpLimit", json: JSON.stringify(preferences), callback

class API3 extends API2
  getTorrentWebSeeds: (hash, callback) ->
    log.debug 'Executing getTorrentWebSeeds'
    @_makeRequest 'GET', "/query/propertiesWebSeeds/#{hash}", callback

module.exports =
  API1: API1
  API2: API2
  API3: API3

