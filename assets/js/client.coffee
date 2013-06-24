

class AntSim
  constructor: ->
    @layerScale = 4
    @createCanvas()
    @createLayers()
    @update()


  createCanvas: ->
    @b = document.body
    @c = document.getElementsByTagName('canvas')[0]
    @a = @c.getContext('2d')
    @w = @c.width = @c.clientWidth
    @h = @c.height = @c.clientHeight
    document.body.clientWidth

  createLayers: ->
    @layers = {}
    @layers.foo = new Layer ~~@w / @layerScale, ~~@h / @layerScale

  drawLayers: ->
    @a.putImageData @layers.foo.getImageData(), 0, 0
    #scale all the layers. kinda dumb but quick
    @a.drawImage @c, 0, 0, @layerScale*@w, @layerScale*@h

  update: ->

    @layers.foo.blur 0.99

    @draw()

  draw: ->
    @a.clearRect(0,0,@w,@h)

    @drawLayers()

    @a.fillStyle = "#fff"
    @a.arc 100,100,10,0,Math.PI*2
    @a.fill()

    _raf = window.requestAnimationFrame || window.mozRequestAnimationFrame
    _raf (=> @update()) 


class Layer
  constructor: (@w,@h) ->
    @buffer = []
    @buffer.push Math.random() for i in [0...@w*@h]

    # seems to be the only way to make a new imagedata object?
    @imageData = document.createElement('CANVAS').getContext('2d').createImageData(@w,@h)
    
  getImageData: ->
    d = @imageData.data
    for v,i in @buffer
      j = i*4
      d[j+0] = v*255
      d[j+1] = v*255
      d[j+2] = v*255
      d[j+3] = 255
    @imageData

  mul: (n) -> @buffer[i] = v*n for v,i in @buffer

  add: (n) -> @buffer[i] = v-n for v,i in @buffer

  blur: (n) ->
    newBuffer = []
    for v,i in @buffer
      x = i%@w
      y = (i-x)/@h
      sumNeighbors = 0
      for _x in [Math.max(0,x-1)..Math.min(@w-1,x+1)]
        for _y in [Math.max(0,y-1)..Math.min(@h-1,y+1)]
          sumNeighbors += @buffer[_x+_y*@w]
      newBuffer[i] = sumNeighbors / 9 || 0
    @buffer = newBuffer
      




window.addEventListener 'load', ->
  new AntSim
