

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

    @layers.foo.blur 0.001

    @draw()

  draw: ->
    @a.clearRect(0,0,@w,@h)

    @drawLayers()

    @a.fillStyle = "#fff"
    @a.arc 100,100,10,0,Math.PI*2
    @a.fill()

    _raf = window.requestAnimationFrame || window.mozRequestAnimationFrame
    _raf (=> @update()) 


class Ant
  constructor: (@pos = new Vec)->


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

  # n = blur amount. 0 = no blur, 1 = pretty blurry, dude
  blur: (n) ->
    newBuffer = []
    for v,i in @buffer
      x = i%@w
      y = (i-x)/@h
      sumNeighbors = 0
      for _x in [Math.max(0,x-1)..Math.min(@w-1,x+1)]
        for _y in [Math.max(0,y-1)..Math.min(@h-1,y+1)]
          sumNeighbors += @buffer[_x+_y*@w] * n
      sumNeighbors += v * (1-n)
      newBuffer[i] = sumNeighbors / (9*n+(1-n)) || 0
    @buffer = newBuffer
      

class Vec
  constructor: (@x=0,@y=0,@z=0) ->
  set: (@x=0,@y=0,@z=0) -> @
  get: -> new Vec @x, @y, @z
  add: (o) -> @x+=o.x; @y+=o.y; @z+=o.z; @
  sub: (o) -> @x-=o.x; @y-=o.y; @z-=o.z; @
  mul: (n) -> @x*=n; @y*=n; @z*=n; @
  div: (n) -> @x/=n; @y/=n; @z/=n; @
  mag: (n) -> Math.sqrt( @x*@x + @y*@y + @z*@z )
  normalize: -> mag = @mag(); @x/=mag; @y/=mag; @z/=mag; @
  bound: (x1,y1,z1,x2,y2,z2) ->
    @x = Math.min x2, Math.max(x1, @x)
    @y = Math.min y2, Math.max(y1, @y)
    @z = Math.min z2, Math.max(z1, @z)
    @



window.addEventListener 'load', ->
  new AntSim
