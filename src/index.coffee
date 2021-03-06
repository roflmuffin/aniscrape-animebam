Promise = require 'bluebird'
needle = Promise.promisifyAll(require 'needle')
cheerio = require 'cheerio'
_ = require 'lodash'

needle.defaults
  follow_max: 5

module.exports =
  name: 'animebam'

  http_options:
    follow_max: 5

  initialize: ->
    console.log "[#{@name}] loaded successfully."

  search:
    page: {url: 'http://animebam.net/search', param: 'search'}

    list: '.mse'

    row:
      name: (el) ->
        el.find("h2").text()
      url: (el) ->
        "http://animebam.net" + el.attr('href')

  series:
    list: '.newmanga li'
    row:
      name: (el) ->
        el.find(".anititle").text()
      url: (el) ->
        "http://animebam.net" + el.find("a").attr("href")

  episode: ($, body) ->
    videoFrames = $('.tab-pane iframe').get().map (item) ->
      item = $(item)
      type: item.parent().attr('id')
      frameUrl: 'http://animebam.net' + item.attr('src')

    Promise.map videoFrames, (frame) =>
      needle.getAsync(frame.frameUrl).then (resp) =>
        $ = cheerio.load(resp.body)
        sources = eval($("script:contains('videoSources')").html().match(/\[.+\]/)[0])
        options =
            follow_max: 0
            headers:
              'Referer': 'http://animebam.net/'

          Promise.map sources, (video) =>
            needle.headAsync(video.file, options).then (resp) =>
              return {
                label: frame.type + '-' + video.label
                url: resp.headers.location
              }
    .then(_.flatten)
