

class AntSim
  constructor: ->
    @createCanvas()
    @update()

  createCanvas: ->
    @b = document.body
    @c = document.getElementsByTagName('canvas')[0]
    @a = @c.getContext('2d')
    @c.width = @c.clientWidth
    @c.height = @c.clientHeight
    document.body.clientWidth

  update: ->
    @a.clearRect()
    @a.fillStyle = "black"
    @a.arc 100,100,10,0,Math.PI*2
    @a.fill()


window.addEventListener 'load', ->
  new AntSim
