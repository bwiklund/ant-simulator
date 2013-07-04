ns = @ns

class ns.Ant
  constructor: (@sim, @pos = new ns.Vec)->
    @angle = Math.random() * Math.PI * 2
    @speed = (Math.random() * 0.2 + 0.8) * @sim.layerScale * 0.4
    @stomach = 0
    @homeRecency = 0
    @age = 0

  sniff: (layer) ->
    antennaDist = 3 * @sim.layerScale
    antennaAngle = Math.PI / 4

    antennaLeftPos  = @pos.get().add( ns.Vec.fromAngleDist(@angle+antennaAngle,antennaDist) )
    antennaRightPos = @pos.get().add( ns.Vec.fromAngleDist(@angle-antennaAngle,antennaDist) )

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
    @pos.add ns.Vec.fromAngleDist @angle, @speed

    # simulation boundaries
    boundPos = @pos.get().bound 0,0,0,@sim.w,@sim.h,0
    if !boundPos.eq @pos
      @angle = Math.random() * Math.PI * 2
      @pos = boundPos

  isInNest: ->
    new ns.Vec(@sim.w/2,@sim.h).sub(@pos).mag() < 10

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