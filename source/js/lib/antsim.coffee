ns = @antsimulator

DEFAULT_CONFIG =
  SCALE: 4
  NUM_ANTS: 1000
  STEPS_PER_FRAME: 1
  ANT_TURN_SPEED: 0.7
  SHOW_ANTS: 1
  JITTER_MAGNITUDE: 0.5
  NEST_FALLOFF_RATE: 0.01
  FOOD_TRAIL_FALLOFF_RATE: 0.01
  NEST_TRAIL_FADE_RATE: 0.01
  FOOD_TRAIL_FADE_RATE: 0.005

class ns.AntSim
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
    @layers.nesttrail = new ns.NestTrail @
    @layers.foodtrail = new ns.FoodTrail @
    @layers.food = new ns.Food @

    @compositor = new ns.LayerCompositor @

  # quick and dirty way to change the population of ants
  createAndRemoveAnts: ->
    while @ants.length < @CONFIG.NUM_ANTS
      @ants.push new ns.Ant @, new ns.Vec @w/2,@h
      #new ns.Vec(Math.random()*@w,Math.random()*@h)
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
    
    parseInt( @CONFIG.SHOW_ANTS ) && ant.draw @a for ant in @ants

    _raf = window.requestAnimationFrame || window.mozRequestAnimationFrame || window.msRequestAnimationFrame || window.oRequestAnimationFrame
    _raf (=> @update())

