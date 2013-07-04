ns = @antsimulator

class ns.Layer
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


class ns.NestTrail extends ns.Layer
  update: ->
    @mul 1-@sim.CONFIG.NEST_TRAIL_FADE_RATE
    #@blur 0.001
    @buffer[@w/2 + @h/2 * @w] = 1000


class ns.FoodTrail extends ns.Layer
  update: ->
    @mul 1-@sim.CONFIG.FOOD_TRAIL_FADE_RATE
    #@blur 0.001


class ns.Food extends ns.Layer
  initCell: (x,y) ->
    if Math.random() < 0.0002 then 100 else 0
  update: ->
    # blurring is expensive, we don't have to do it every frame
    if @sim.frame % 10 == 0
      @blur 0.002
    if Math.random() < 0.01
      @mark new ns.Vec( Math.random() * @w*@sim.layerScale, Math.random() * @h*@sim.layerScale), 100


class ns.LayerCompositor
  constructor: (@sim) ->
    @w = ~~ (@sim.w / @sim.layerScale)
    @h = ~~ (@sim.h / @sim.layerScale)
    # seems to be the only way to make a new ns.imagedata object?
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
