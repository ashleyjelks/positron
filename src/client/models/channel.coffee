_ = require 'underscore'
Backbone = require 'backbone'
sd = require('sharify').data
async = require 'async'
request = require 'superagent'
artsyXapp = require('artsy-xapp')

module.exports = class Channel extends Backbone.Model

  urlRoot: "#{sd.API_URL}/channels"

  isTeam: ->
    @get('type') is 'team'

  isEditorial: ->
    @get('type') is 'editorial'

  isArtsyChannel: ->
    @get('type') in ['editorial', 'support', 'team']

  hasFeature: (feature) ->
    type = @get('type')
    if type is 'editorial'
      _.contains [
        'header'
        'superArticle'
        'text'
        'artworks'
        'images'
        'image_set'
        'video'
        'embed'
        'callout'
        'follow'
        'layout'
        'postscript'
        'sponsor'
      ], feature
    else if type is 'team'
      _.contains [
        'text'
        'artworks'
        'images'
        'image_set'
        'video'
        'embed'
        'callout'
        'follow'
        'hero'
      ], feature
    else if type is 'support'
      _.contains [
        'text'
        'artworks'
        'images'
        'video'
        'callout'
        'follow'
        'hero'
      ], feature
    else if type is 'partner'
       _.contains [
        'text'
        'artworks'
        'images'
        'video'
      ], feature

  hasAssociation: (association) ->
    type = @get('type')
    if type is 'editorial'
      _.contains [
        'artworks'
        'artists'
        'shows'
        'fairs'
        'partners'
        'auctions'
      ], association
    else if type is 'team'
      false
    else if type is 'support'
      _.contains [
        'artworks'
        'artists'
        'shows'
        'fairs'
        'partners'
        'auctions'
      ], association
    else if type is 'partner'
      _.contains [
        'artworks'
        'artists'
        'shows'
        'fairs'
        'partners'
        'auctions'
      ], association

  fetchChannelOrPartner: (options) ->
    async.parallel [
      (cb) =>
        request.get("#{sd.API_URL}/channels/#{@get('id')}")
          .set('X-Xapp-Token': artsyXapp.token)
          .end (err, res) ->
            if err
              cb null, {}
            else
              cb null, res
      (cb) =>
        request.get("#{sd.ARTSY_URL}/api/v1/partner/#{@get('id')}")
          .set('X-Xapp-Token': artsyXapp.token)
          .end (err, res) ->
            if err
              cb null, {}
            else
              cb null, res
    ], (err, results) ->
      if results[0]?.ok
        options.success new Channel results[0].body
      else if results[1]?.ok
        channel = new Channel(
          name: results[1].body.name
          id: results[1].body._id
          type: 'partner'
        )
        options.success channel
      else
        options.error err

  denormalized: ->
    {
      id: @get('id')
      name: @get('name')
      type: if _.contains ['editorial', 'support', 'team'], @get('type') then @get('type') else 'partner'
    }
