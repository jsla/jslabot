# Logs Chat Activity
qs       = require 'querystring'
mongoose = require "mongoose"

Schema = mongoose.Schema
mongoose.connect "mongodb://localhost/jslabot"

MessageSchema = new Schema
  time: {type: Date, index: true}
  user: {type: String, index: true}
  body: String

Message = mongoose.model "Message", MessageSchema

module.exports = (robot) ->

  robot.hear /.*/, (data) ->
    body = data.message.text
    user = data.message.user.name
    time = new Date

    msg = new Message
      body: body
      user: user
      time: time

    msg.save()

  robot.router.get "/logger", (req, res) ->
    params = qs.parse (req.url.replace /^\/logger\??/, '')
    
    now = new Date
    tweleveHoursAgo = new Date (now - 12*3600*1000)

    if params.timeMin
      timeMin = new Date params.timeMin
    else
      timeMin = tweleveHoursAgo

    if params.timeMax
      timeMax = new Date params.timeMax
    else
      timeMax = now

    conditions =
      time:
        $gte: timeMin
        $lte: timeMax
    
    conditions.user = params.user if params.user?

    messages = Message.find conditions, (err, docs) ->
      res.end JSON.stringify docs