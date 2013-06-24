

class AntSim
  constructor: ->
    @layerScale = 4
    @createCanvas()
    @createLayers()
    @createAnts()
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
    @layers.trail = new Trail @w, @h, @layerScale

  createAnts: ->
    @ants = []
    for i in [0...1000]
      @ants.push new Ant @, new Vec(@w/2,@h/2)

  drawLayers: ->
    @a.putImageData @layers.trail.getImageData(), 0, 0
    #scale all the layers. kinda dumb but quick
    @a.drawImage @c, 0, 0, @layerScale*@w, @layerScale*@h

  update: ->

    #@layers.foo.blur 0.001
    layer.update() for k,layer of @layers
    ant.update() for ant in @ants

    @draw()

  draw: ->
    @a.clearRect(0,0,@w,@h)
    @drawLayers()
    #ant.draw @a for ant in @ants

    _raf = window.requestAnimationFrame || window.mozRequestAnimationFrame
    _raf (=> @update())


class Ant
  constructor: (@sim, @pos = new Vec)->
    @angle = Math.random() * Math.PI * 2
    @age = 0

  update: ->
    @age++
    @angle += (Math.random() - 0.5)*0.3
    @pos.x += Math.cos(@angle)
    @pos.y += Math.sin(@angle)
    @pos.bound 0,0,0,@sim.w,@sim.h,0

    @sim.layers.trail.mark(@pos,0.01)

  draw: (a) ->
    a.fillStyle = "#000"
    a.save()
    a.beginPath()
    a.translate @pos.x, @pos.y
    a.arc 0,0,2,0,Math.PI*2
    a.fill()
    a.restore()

class Layer
  constructor: (_w,_h,@scale) ->
    @w = ~~(_w / @scale)
    @h = ~~(_h / @scale)

    @buffer = []
    @buffer.push Math.random()*0.2+0.4 for i in [0...@w*@h]

    # seems to be the only way to make a new imagedata object?
    @imageData = document.createElement('CANVAS').getContext('2d').createImageData(@w,@h)

  update: ->
    
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

  mark: (pos,n) ->
    i = @posToIndex(pos)
    @buffer[i] += n

  posToIndex: (pos) ->
    pos = pos.get().mul 1/@scale
    ~~pos.x + (~~pos.y) * @w


class Trail extends Layer
  update: ->
    @mul 0.999
    @blur 0.01

      

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
