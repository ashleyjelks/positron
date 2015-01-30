_ = require 'underscore'
Backbone = require 'backbone'
request = require 'superagent'
async = require 'async'
featuredListTemplate = -> require('./featured_list.jade') arguments...
sd = require('sharify').data
Autocomplete = require '../../../../components/autocomplete/index.coffee'
AutocompleteSelect = require '../../../../components/autocomplete_select/index.coffee'

module.exports = class EditAdmin extends Backbone.View

  initialize: ({ @article }) ->
    @article.on 'open:tab2', @onOpen
    @article.on 'change:fair_id', @renderFairInput
    @setupAuthorAutocomplete()
    @setupFairAutocomplete()

  setupAuthorAutocomplete: ->
    new Autocomplete
      el: @$('#edit-admin-change-author input')
      url: "#{sd.API_URL}/users?q=%QUERY"
      filter: (res) -> for r in res.results
        { id: r.id, value: r.user.name + ', ' + (r.details?.email or '') }
      selected: (e, item) =>
        return unless confirm "Are you sure you want to change the author?"
        @article.trigger('finished').save(author_id: item.id)

  setupFairAutocomplete: ->
    window.select = AutocompleteSelect @$('#edit-admin-fair .edit-admin-right')[0],
      url: "#{sd.ARTSY_URL}/api/v1/match/fairs?term=%QUERY"
      filter: (res) -> for r in res
        { id: r._id, value: r.name }
      selected: (e, item) =>
        @article.save fair_id: item.id
      cleared: =>
        @article.save fair_id: null
    if id = @article.get 'fair_id'
      request
        .get("#{sd.ARTSY_URL}/api/v1/fair/#{id}")
        .set('X-Access-Token': sd.USER.access_token).end (err, res) ->
          select.setState value: res.body.name, loading: false
    else
      select.setState loading: false

  onOpen: =>
    async.parallel [
      (cb) => @article.fetchFeatured success: -> cb()
      (cb) => @article.fetchMentioned success: -> cb()
    ], =>
      @renderFeatured()
      @article.featuredPrimaryArtists.on 'add remove', @renderFeatured
      @article.featuredArtists.on 'add remove', @renderFeatured
      @article.featuredArtworks.on 'add remove', @renderFeatured

  renderFeatured: =>
    @$('#eaf-primary-artists li:not(.eaf-input-li)').remove()
    @$('#eaf-primary-artists .eaf-input-li').before $(
      featuredListTemplate list: @article.featuredList('Artists', 'PrimaryArtists')
    )
    @$('#eaf-artists li:not(.eaf-input-li)').remove()
    @$('#eaf-artists .eaf-input-li').before $(
      featuredListTemplate list: @article.featuredList('Artists')
    )
    @$('#eaf-artworks li:not(.eaf-input-li)').remove()
    @$('#eaf-artworks .eaf-input-li').before $(
      featuredListTemplate list: @article.featuredList('Artworks')
    )

  events:
    'change #eaf-primary-artists .eaf-artist-input': (e) ->
      @featureFromInput('PrimaryArtists') e
    'change #eaf-artists .eaf-artist-input': (e) ->
      @featureFromInput('Artists') e
    'change .eaf-artwork-input': (e) ->
      @featureFromInput('Artworks') e
    'click #eaf-artists .eaf-featured': (e)-> @unfeature('Artists') e
    'click #eaf-artworks .eaf-featured': (e)-> @unfeature('Artworks') e
    'click #eaf-artists .eaf-mentioned': (e) -> @featureMentioned('Artists') e
    'click #eaf-artworks .eaf-mentioned': (e) -> @featureMentioned('Artworks') e

  featureFromInput: (resource) => (e) =>
    $t = $ e.currentTarget
    id = _.last $t.val().split('/')
    $t.parent().addClass 'bordered-input-loading'
    @article['featured' + resource].getOrFetchIds [id],
      complete: -> $t.val('').parent().removeClass 'bordered-input-loading'

  featureMentioned: (resource) => (e) =>
    @article['featured' + resource].add(
      @article['mentioned' + resource].get $(e.currentTarget).attr 'data-id'
    )

  unfeature: (resource) => (e) =>
    id = $(e.currentTarget).attr 'data-id'
    @article['featured' + resource].remove id
