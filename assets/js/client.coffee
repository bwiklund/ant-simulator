

class AntSim
  constructor: ->
    @layerScale = 3
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
    @layers.hometrail = new HomeTrail @w, @h, @layerScale
    @layers.foodtrail = new FoodTrail @w, @h, @layerScale
    @layers.food = new Food @w, @h, @layerScale

    @compositor = new LayerCompositor @w, @h, @layerScale

  createAnts: ->
    @ants = []
    for i in [0...500]
      @ants.push new Ant @, new Vec(@w/2,@h/2)

  drawLayers: ->
    # @a.putImageData @layers.hometrail.getImageData(), 0, 0
    # @a.putImageData @layers.foodtrail.getImageData(), 0, 0
    #scale all the layers. kinda dumb but quick
    @a.putImageData @compositor.getImageData(@layers), 0, 0
    @a.drawImage @c, 0, 0, @layerScale*@w, @layerScale*@h

  update: ->

    #@layers.foo.blur 0.001
    layer.update() for k,layer of @layers
    ant.update() for ant in @ants

    @draw()

  draw: ->
    @a.clearRect(0,0,@w,@h)
    @drawLayers()
    ant.draw @a for ant in @ants

    _raf = window.requestAnimationFrame || window.mozRequestAnimationFrame
    _raf (=> @update())


class Ant
  constructor: (@sim, @pos = new Vec)->
    @angle = Math.random() * Math.PI * 2
    @speed = Math.random()*0.2 + 0.8
    @stomach = 0
    @homeRecency = 1
    @age = 0

  sniff: (layer) ->
    antennaDist = 3
    antennaAngle = Math.PI / 8

    antennaLeftPos  = @pos.get().add( Vec.fromAngleDist(@angle+antennaAngle,antennaDist) )
    antennaRightPos = @pos.get().add( Vec.fromAngleDist(@angle-antennaAngle,antennaDist) )

    leftSample  = layer.sample antennaLeftPos
    rightSample = layer.sample antennaRightPos

    if leftSample < 0.01  then leftSample = 0
    if rightSample < 0.01 then rightSample = 0

    leftSample - rightSample

  update: ->
    @age++
    @stomach *= 0.992
    @homeRecency *= 0.99
    # @angle += (Math.random() - 0.5)*0.3
    @pos.add Vec.fromAngleDist @angle, @speed
    @pos.bound 0,0,0,@sim.w,@sim.h,0

    #@sim.layers.hometrail.mark(@pos,0.03)
    #@sim.layers.foodtrail.mark(@pos,0.03)
    
    # spit out food in the nest
    if @sim.layers.hometrail.sample(@pos) > 0.95
      @stomach = 0
      @homeRecency = 1

    @stomach += @sim.layers.food.take @pos, 1

    isHungry = @stomach < 0.5

    if isHungry
      reading = @sniff @sim.layers.foodtrail
      @sim.layers.hometrail.mark(@pos,@homeRecency*0.1)
    else
      reading = @sniff @sim.layers.hometrail
      @sim.layers.foodtrail.mark(@pos,@stomach * 0.1)

    if reading > 0 then @angle += 0.5
    if reading < 0 then @angle -= 0.5
    @angle += (Math.random() - 0.5)*0.6

  draw: (a) ->
    a.fillStyle = "#fff"
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
    @buffer.push @initCell(i%@w,Math.floor(i/@h)) for i in [0...@w*@h]

  initCell: (x,y) -> 0

  update: ->

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
    if @buffer[i]?
      @buffer[i] += n

  sample: (pos) ->
    i = @posToIndex(pos)
    @buffer[i] || 0

  take: (pos,max) ->
    i = @posToIndex(pos)
    if @buffer[i]?
      takeAmount = Math.min @buffer[i], max
      @buffer[i] -= takeAmount
      takeAmount
    else
      0



  posToIndex: (pos) ->
    pos = pos.get().mul 1/@scale
    Math.floor(pos.x) + Math.floor(pos.y) * @w


class HomeTrail extends Layer
  # initCell: (x,y) ->
  #   y/@h

  update: ->
    @mul 0.996
    @blur 0.002


class FoodTrail extends Layer
  update: ->
    @mul 0.996
    @blur 0.002


class Food extends Layer
  initCell: (x,y) ->
    if Math.random() < 0.0001 then 50 else 0
  update: ->
    @blur 0.002
    if Math.random() < 0.001
      @mark new Vec( Math.random() * @w*@scale, Math.random() * @h*@scale), 100


class LayerCompositor
  constructor: (_w,_h,@scale) ->
    @w = ~~ (_w / @scale)
    @h = ~~ (_h / @scale)
    # seems to be the only way to make a new imagedata object?
    @imageData = document.createElement('CANVAS').getContext('2d').createImageData(@w,@h)
    
  getImageData: (layers) ->
    d = @imageData.data
    for i in [0...@w*@h]
      j = i*4
      d[j+0] = 127 * layers.hometrail.buffer[i]
      d[j+1] = 255 * layers.foodtrail.buffer[i]
      d[j+2] = 255 * layers.food.buffer[i]
      d[j+3] = 255
    @imageData
      

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

Vec.fromAngleDist = (angle,dist) ->
  new Vec dist*Math.cos(angle), dist*Math.sin(angle)



window.addEventListener 'load', ->
  new AntSim
