# Example initialization
# ArticleList {
#   selected: () ->
#   checkable: true
#   articles: []
# }

_ = require 'underscore'
React = require 'react'
{ input, div, a, h1, h2 } = React.DOM
moment = require 'moment'
icons = -> require('./icons.jade') arguments...

module.exports = ArticleList = React.createClass

  render: ->
    div { className: 'article-list__results' },
      (@props.articles.map (result) =>
        div { className: 'article-list__result paginated-list-item' },
          if @props.checkable
            div {
              className: 'article-list__checkcircle'
              dangerouslySetInnerHTML: __html: $(icons()).filter('.check-circle').html()
              onClick: => @props.selected(result)
            }
          div { className: 'article-list__article' },
            div { className: 'article-list__image paginated-list-img', style: backgroundImage: "url(#{result.thumbnail_image})" }
            div { className: 'article-list__title paginated-list-text-container' },
              h1 {}, result.thumbnail_title
              h2 {}, "Published #{moment(result.published_at).fromNow()}"
          a { className: 'paginated-list-preview avant-garde-button', href: "#{sd.FORCE_URL}/article/#{result.slug}", target: '_blank' }, "Preview"
      )