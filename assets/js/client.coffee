DEFAULT_CONFIG =
  SCALE: 4
  NUM_ANTS: 1000
  STEPS_PER_FRAME: 5
  ANT_TURN_SPEED: 0.7
  SHOW_ANTS: true
  JITTER_MAGNITUDE: 0.5
  NEST_FALLOFF_RATE: 0.01
  FOOD_TRAIL_FALLOFF_RATE: 0.01
  NEST_TRAIL_FADE_RATE: 0.01
  FOOD_TRAIL_FADE_RATE: 0.005

class AntSim
  constructor: ->
    @CONFIG = DEFAULT_CONFIG # to expose it to our test ui. janky
    @frame = 0
    @layerScale = @CONFIG.SCALE
    @createCanvas()
    @createLayers()
    @ants = []
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
    @layers.nesttrail = new NestTrail @
    @layers.foodtrail = new FoodTrail @
    @layers.food = new Food @

    @compositor = new LayerCompositor @

  # quick and dirty way to change the population of ants
  createAndRemoveAnts: ->
    while @ants.length < @CONFIG.NUM_ANTS
      @ants.push new Ant @, new Vec @w/2,@h
      #new Vec(Math.random()*@w,Math.random()*@h)
    if @ants.length > @CONFIG.NUM_ANTS
      @ants = @ants.slice 0, @CONFIG.NUM_ANTS

  drawLayers: ->
    # cheap (?) canvas resizing
    @a.putImageData @compositor.getImageData(@layers), 0, 0
    @a.drawImage @c, 0, 0, @layerScale*@w, @layerScale*@h

  update: ->
    @createAndRemoveAnts()
    for i in [0...@CONFIG.STEPS_PER_FRAME]
      layer.update() for k,layer of @layers
      ant.update() for ant in @ants

    @draw()

    @frame++

  draw: ->
    @a.clearRect(0,0,@w,@h)
    @drawLayers()
    
    @CONFIG.SHOW_ANTS && ant.draw @a for ant in @ants

    _raf = window.requestAnimationFrame || window.mozRequestAnimationFrame || window.msRequestAnimationFrame || window.oRequestAnimationFrame
    _raf (=> @update())


class Ant
  constructor: (@sim, @pos = new Vec)->
    @angle = Math.random() * Math.PI * 2
    @speed = (Math.random() * 0.2 + 0.8) * @sim.layerScale * 0.4
    @stomach = 0
    @homeRecency = 0
    @age = 0

  sniff: (layer) ->
    antennaDist = 3 * @sim.layerScale
    antennaAngle = Math.PI / 4

    antennaLeftPos  = @pos.get().add( Vec.fromAngleDist(@angle+antennaAngle,antennaDist) )
    antennaRightPos = @pos.get().add( Vec.fromAngleDist(@angle-antennaAngle,antennaDist) )

    leftSample  = layer.sample antennaLeftPos
    rightSample = layer.sample antennaRightPos

    if leftSample < 0.01  then leftSample = 0
    if rightSample < 0.01 then rightSample = 0

    leftSample - rightSample

  update: ->
    
    @age++
    @stomach *= 1 - @sim.CONFIG.FOOD_TRAIL_FALLOFF_RATE
    @homeRecency *= 1 - @sim.CONFIG.NEST_FALLOFF_RATE
    
    if @isInNest()
      @stomach = 0
      @homeRecency = 1

    # gobble up whatever food is underneath
    newStomach = @stomach + @sim.layers.food.take @pos, 1

    # turn around if you just ate a bunch of food
    # if newStomach > @stomach * 2
    #   @angle += Math.PI
    @stomach = newStomach

    # if empty stomach or away from home too long, follow the home trail
    # else, try to sniff out food directly
    # if no food to sniff, follow the food scent trail
    if @isHunting()
      reading = @sniff @sim.layers.food
      if reading == 0
        reading = @sniff @sim.layers.foodtrail
    else
      reading = @sniff @sim.layers.nesttrail

    # mark trails
    @sim.layers.foodtrail.mark(@pos,@stomach * 0.01)
    @sim.layers.nesttrail.mark(@pos,@homeRecency * 0.1)

    # turn
    if reading > 0 then @angle += @sim.CONFIG.ANT_TURN_SPEED
    if reading < 0 then @angle -= @sim.CONFIG.ANT_TURN_SPEED

    # don't jitter the angle if you're on the trail.
    jitterAmount = Math.max(0,1-@sim.layers.foodtrail.sample( @pos ))
    @angle += (Math.random() - 0.5)*2*jitterAmount*@sim.CONFIG.JITTER_MAGNITUDE

    # apply changes
    @pos.add Vec.fromAngleDist @angle, @speed

    # simulation boundaries
    boundPos = @pos.get().bound 0,0,0,@sim.w,@sim.h,0
    if !boundPos.eq @pos
      @angle = Math.random() * Math.PI * 2
      @pos = boundPos

  isInNest: ->
    new Vec(@sim.w/2,@sim.h).sub(@pos).mag() < 10

  isHunting: ->
    @stomach < 0.1 && @homeRecency > 0.01

  draw: (a) ->
    a.fillStyle = "#fff"
    a.save()
    a.beginPath()
    a.translate @pos.x, @pos.y
    a.arc 0,0,0.25*@sim.layerScale,0,Math.PI*2
    a.fill()
    a.restore()


class Layer
  constructor: (@sim) ->
    @w = ~~(@sim.w / @sim.layerScale)
    @h = ~~(@sim.h / @sim.layerScale)

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
    pos = pos.get().mul 1 / @sim.layerScale
    Math.floor(pos.x) + Math.floor(pos.y) * @w


class NestTrail extends Layer
  update: ->
    @mul 1-@sim.CONFIG.NEST_TRAIL_FADE_RATE
    #@blur 0.001
    @buffer[@w/2 + @h/2 * @w] = 1000


class FoodTrail extends Layer
  update: ->
    @mul 1-@sim.CONFIG.FOOD_TRAIL_FADE_RATE
    #@blur 0.001


class Food extends Layer
  initCell: (x,y) ->
    if Math.random() < 0.0002 then 100 else 0
  update: ->
    # blurring is expensive, we don't have to do it every frame
    if @sim.frame % 10 == 0
      @blur 0.002
    if Math.random() < 0.01
      @mark new Vec( Math.random() * @w*@sim.layerScale, Math.random() * @h*@sim.layerScale), 100


class LayerCompositor
  constructor: (@sim) ->
    @w = ~~ (@sim.w / @sim.layerScale)
    @h = ~~ (@sim.h / @sim.layerScale)
    # seems to be the only way to make a new imagedata object?
    @imageData = document.createElement('CANVAS').getContext('2d').createImageData(@w,@h)
    
  getImageData: (layers) ->
    d = @imageData.data
    for i in [0...@w*@h]
      j = i*4

      #r = g = b = 0

      # base color
      r = 0.13
      g = 0.11
      b = 0.10
      
      # blend our trails together
      
      r += 0.5 * layers.nesttrail.buffer[i]
      g += 0.1 * layers.nesttrail.buffer[i]
      # b
      
      r += 0.65*layers.food.buffer[i]
      g += 1.0*layers.food.buffer[i]
      # b
      
      # r
      b += 2.5*layers.foodtrail.buffer[i]
      g += 1.7*layers.foodtrail.buffer[i]

      d[j+0] = 255*r
      d[j+1] = 255*g
      d[j+2] = 255*b
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
  eq: (o) -> o.x==@x && o.y==@y && o.z==@z

Vec.fromAngleDist = (angle,dist) ->
  new Vec dist*Math.cos(angle), dist*Math.sin(angle)



@AntSim = AntSim
