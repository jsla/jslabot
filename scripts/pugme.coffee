# Pugme is the most important thing in your life
#
# pug me - Receive a pug
# pug bomb N - get N pugs

module.exports = (robot) ->

  robot.respond /pug me/i, (msg) ->
    msg.http("http://corgibomb.heroku.com/random")
      .get() (err, res, body) ->
        msg.send body

  robot.respond /pug bomb( (\d+))?/i, (msg) ->
    count = msg.match[2] || 5
    msg.http("http://corgibomb.heroku.com/bomb/" + count)
      .get() (err, res, body) ->
        msg.send corgi for corgi in JSON.parse(body)

  robot.respond /how many pugs are there/i, (msg) ->
    msg.http("http://pugme.herokuapp.com/count")
      .get() (err, res, body) ->
        msg.send "There are #{JSON.parse(body).pug_count} pugs."
    