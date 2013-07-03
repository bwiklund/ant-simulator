(function() {
  var Ant, AntSim, CONFIG, Food, FoodTrail, HomeTrail, Layer, LayerCompositor, Vec, _ref, _ref1, _ref2,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  CONFIG = {
    SCALE: 4,
    NUM_ANTS: 1000,
    STEPS_PER_FRAME: 5,
    ANT_TURN_SPEED: 0.7
  };

  AntSim = (function() {
    function AntSim() {
      this.layerScale = CONFIG.SCALE;
      this.createCanvas();
      this.createLayers();
      this.createAnts();
      this.update();
    }

    AntSim.prototype.createCanvas = function() {
      this.b = document.body;
      this.c = document.getElementsByTagName('canvas')[0];
      this.a = this.c.getContext('2d');
      this.w = this.c.width = this.c.clientWidth;
      this.h = this.c.height = this.c.clientHeight;
      return document.body.clientWidth;
    };

    AntSim.prototype.createLayers = function() {
      this.layers = {};
      this.layers.hometrail = new HomeTrail(this.w, this.h, this.layerScale);
      this.layers.foodtrail = new FoodTrail(this.w, this.h, this.layerScale);
      this.layers.food = new Food(this.w, this.h, this.layerScale);
      return this.compositor = new LayerCompositor(this.w, this.h, this.layerScale);
    };

    AntSim.prototype.createAnts = function() {
      var i, _i, _ref, _results;
      this.ants = [];
      _results = [];
      for (i = _i = 0, _ref = CONFIG.NUM_ANTS; 0 <= _ref ? _i < _ref : _i > _ref; i = 0 <= _ref ? ++_i : --_i) {
        _results.push(this.ants.push(new Ant(this, new Vec(Math.random() * this.w, Math.random() * this.h))));
      }
      return _results;
    };

    AntSim.prototype.drawLayers = function() {
      this.a.putImageData(this.compositor.getImageData(this.layers), 0, 0);
      return this.a.drawImage(this.c, 0, 0, this.layerScale * this.w, this.layerScale * this.h);
    };

    AntSim.prototype.update = function() {
      var ant, i, k, layer, _i, _j, _len, _ref, _ref1, _ref2;
      for (i = _i = 0, _ref = CONFIG.STEPS_PER_FRAME; 0 <= _ref ? _i < _ref : _i > _ref; i = 0 <= _ref ? ++_i : --_i) {
        _ref1 = this.layers;
        for (k in _ref1) {
          layer = _ref1[k];
          layer.update();
        }
        _ref2 = this.ants;
        for (_j = 0, _len = _ref2.length; _j < _len; _j++) {
          ant = _ref2[_j];
          ant.update();
        }
      }
      return this.draw();
    };

    AntSim.prototype.draw = function() {
      var _raf,
        _this = this;
      this.a.clearRect(0, 0, this.w, this.h);
      this.drawLayers();
      _raf = window.requestAnimationFrame || window.mozRequestAnimationFrame;
      return _raf((function() {
        return _this.update();
      }));
    };

    return AntSim;

  })();

  Ant = (function() {
    function Ant(sim, pos) {
      this.sim = sim;
      this.pos = pos != null ? pos : new Vec;
      this.angle = Math.random() * Math.PI * 2;
      this.speed = (Math.random() * 0.2 + 0.8) * this.sim.layerScale * 0.4;
      this.stomach = 0;
      this.homeRecency = 0;
      this.age = 0;
    }

    Ant.prototype.sniff = function(layer) {
      var antennaAngle, antennaDist, antennaLeftPos, antennaRightPos, leftSample, rightSample;
      antennaDist = 3 * this.sim.layerScale;
      antennaAngle = Math.PI / 4;
      antennaLeftPos = this.pos.get().add(Vec.fromAngleDist(this.angle + antennaAngle, antennaDist));
      antennaRightPos = this.pos.get().add(Vec.fromAngleDist(this.angle - antennaAngle, antennaDist));
      leftSample = layer.sample(antennaLeftPos);
      rightSample = layer.sample(antennaRightPos);
      if (leftSample < 0.01) {
        leftSample = 0;
      }
      if (rightSample < 0.01) {
        rightSample = 0;
      }
      return leftSample - rightSample;
    };

    Ant.prototype.update = function() {
      var jitterAmount, newStomach, reading;
      this.age++;
      this.stomach *= 0.99;
      this.homeRecency *= 0.99;
      if (this.isInNest()) {
        this.stomach = 0;
        this.homeRecency = 1;
      }
      newStomach = this.stomach + this.sim.layers.food.take(this.pos, 1);
      this.stomach = newStomach;
      if (this.isHunting()) {
        reading = this.sniff(this.sim.layers.food);
        if (reading === 0) {
          reading = this.sniff(this.sim.layers.foodtrail);
        }
      } else {
        reading = this.sniff(this.sim.layers.hometrail);
      }
      this.sim.layers.foodtrail.mark(this.pos, this.stomach * 0.01);
      this.sim.layers.hometrail.mark(this.pos, this.homeRecency * 0.1);
      if (reading > 0) {
        this.angle += CONFIG.ANT_TURN_SPEED;
      }
      if (reading < 0) {
        this.angle -= CONFIG.ANT_TURN_SPEED;
      }
      jitterAmount = Math.max(0, 1 - this.sim.layers.foodtrail.sample(this.pos));
      this.angle += (Math.random() - 0.5) * jitterAmount;
      this.pos.add(Vec.fromAngleDist(this.angle, this.speed));
      return this.pos.bound(0, 0, 0, this.sim.w, this.sim.h, 0);
    };

    Ant.prototype.isInNest = function() {
      return this.pos.y > this.sim.h * 0.95;
    };

    Ant.prototype.isHunting = function() {
      return this.stomach < 0.1 && this.homeRecency > 0.01;
    };

    Ant.prototype.draw = function(a) {
      a.fillStyle = "#fff";
      a.save();
      a.beginPath();
      a.translate(this.pos.x, this.pos.y);
      a.arc(0, 0, 0.25 * this.sim.layerScale, 0, Math.PI * 2);
      a.fill();
      return a.restore();
    };

    return Ant;

  })();

  Layer = (function() {
    function Layer(_w, _h, scale) {
      var i, _i, _ref;
      this.scale = scale;
      this.w = ~~(_w / this.scale);
      this.h = ~~(_h / this.scale);
      this.buffer = [];
      for (i = _i = 0, _ref = this.w * this.h; 0 <= _ref ? _i < _ref : _i > _ref; i = 0 <= _ref ? ++_i : --_i) {
        this.buffer.push(this.initCell(i % this.w, Math.floor(i / this.h)));
      }
    }

    Layer.prototype.initCell = function(x, y) {
      return 0;
    };

    Layer.prototype.update = function() {};

    Layer.prototype.mul = function(n) {
      var i, v, _i, _len, _ref, _results;
      _ref = this.buffer;
      _results = [];
      for (i = _i = 0, _len = _ref.length; _i < _len; i = ++_i) {
        v = _ref[i];
        _results.push(this.buffer[i] = v * n);
      }
      return _results;
    };

    Layer.prototype.add = function(n) {
      var i, v, _i, _len, _ref, _results;
      _ref = this.buffer;
      _results = [];
      for (i = _i = 0, _len = _ref.length; _i < _len; i = ++_i) {
        v = _ref[i];
        _results.push(this.buffer[i] = v - n);
      }
      return _results;
    };

    Layer.prototype.blur = function(n) {
      var i, newBuffer, sumNeighbors, v, x, y, _i, _j, _k, _len, _ref, _ref1, _ref2, _ref3, _ref4, _x, _y;
      newBuffer = [];
      _ref = this.buffer;
      for (i = _i = 0, _len = _ref.length; _i < _len; i = ++_i) {
        v = _ref[i];
        x = i % this.w;
        y = (i - x) / this.h;
        sumNeighbors = 0;
        for (_x = _j = _ref1 = Math.max(0, x - 1), _ref2 = Math.min(this.w - 1, x + 1); _ref1 <= _ref2 ? _j <= _ref2 : _j >= _ref2; _x = _ref1 <= _ref2 ? ++_j : --_j) {
          for (_y = _k = _ref3 = Math.max(0, y - 1), _ref4 = Math.min(this.h - 1, y + 1); _ref3 <= _ref4 ? _k <= _ref4 : _k >= _ref4; _y = _ref3 <= _ref4 ? ++_k : --_k) {
            sumNeighbors += this.buffer[_x + _y * this.w] * n;
          }
        }
        sumNeighbors += v * (1 - n);
        newBuffer[i] = sumNeighbors / (9 * n + (1 - n)) || 0;
      }
      return this.buffer = newBuffer;
    };

    Layer.prototype.mark = function(pos, n) {
      var i;
      i = this.posToIndex(pos);
      if (this.buffer[i] != null) {
        return this.buffer[i] += n;
      }
    };

    Layer.prototype.sample = function(pos) {
      var i;
      i = this.posToIndex(pos);
      return this.buffer[i] || 0;
    };

    Layer.prototype.take = function(pos, max) {
      var i, takeAmount;
      i = this.posToIndex(pos);
      if (this.buffer[i] != null) {
        takeAmount = Math.min(this.buffer[i], max);
        this.buffer[i] -= takeAmount;
        return takeAmount;
      } else {
        return 0;
      }
    };

    Layer.prototype.posToIndex = function(pos) {
      pos = pos.get().mul(1 / this.scale);
      return Math.floor(pos.x) + Math.floor(pos.y) * this.w;
    };

    return Layer;

  })();

  HomeTrail = (function(_super) {
    __extends(HomeTrail, _super);

    function HomeTrail() {
      _ref = HomeTrail.__super__.constructor.apply(this, arguments);
      return _ref;
    }

    HomeTrail.prototype.update = function() {
      this.mul(0.99);
      return this.buffer[this.w / 2 + this.h / 2 * this.w] = 1000;
    };

    return HomeTrail;

  })(Layer);

  FoodTrail = (function(_super) {
    __extends(FoodTrail, _super);

    function FoodTrail() {
      _ref1 = FoodTrail.__super__.constructor.apply(this, arguments);
      return _ref1;
    }

    FoodTrail.prototype.update = function() {
      return this.mul(0.995);
    };

    return FoodTrail;

  })(Layer);

  Food = (function(_super) {
    __extends(Food, _super);

    function Food() {
      _ref2 = Food.__super__.constructor.apply(this, arguments);
      return _ref2;
    }

    Food.prototype.initCell = function(x, y) {
      if (Math.random() < 0.0002) {
        return 100;
      } else {
        return 0;
      }
    };

    Food.prototype.update = function() {
      this.blur(0.0002);
      if (Math.random() < 0.01) {
        return this.mark(new Vec(Math.random() * this.w * this.scale, Math.random() * this.h * this.scale), 100);
      }
    };

    return Food;

  })(Layer);

  LayerCompositor = (function() {
    function LayerCompositor(_w, _h, scale) {
      this.scale = scale;
      this.w = ~~(_w / this.scale);
      this.h = ~~(_h / this.scale);
      this.imageData = document.createElement('CANVAS').getContext('2d').createImageData(this.w, this.h);
    }

    LayerCompositor.prototype.getImageData = function(layers) {
      var b, d, g, i, j, r, _i, _ref3;
      d = this.imageData.data;
      for (i = _i = 0, _ref3 = this.w * this.h; 0 <= _ref3 ? _i < _ref3 : _i > _ref3; i = 0 <= _ref3 ? ++_i : --_i) {
        j = i * 4;
        r = g = b = 0;
        r += 0.5 * layers.hometrail.buffer[i];
        g += 0.1 * layers.hometrail.buffer[i];
        g += 1.0 * layers.food.buffer[i];
        r += 0.3 * layers.food.buffer[i];
        b += 1.5 * layers.foodtrail.buffer[i];
        g += 1.0 * layers.foodtrail.buffer[i];
        d[j + 0] = 255 * r;
        d[j + 1] = 255 * g;
        d[j + 2] = 255 * b;
        d[j + 3] = 255;
      }
      return this.imageData;
    };

    return LayerCompositor;

  })();

  Vec = (function() {
    function Vec(x, y, z) {
      this.x = x != null ? x : 0;
      this.y = y != null ? y : 0;
      this.z = z != null ? z : 0;
    }

    Vec.prototype.set = function(x, y, z) {
      this.x = x != null ? x : 0;
      this.y = y != null ? y : 0;
      this.z = z != null ? z : 0;
      return this;
    };

    Vec.prototype.get = function() {
      return new Vec(this.x, this.y, this.z);
    };

    Vec.prototype.add = function(o) {
      this.x += o.x;
      this.y += o.y;
      this.z += o.z;
      return this;
    };

    Vec.prototype.sub = function(o) {
      this.x -= o.x;
      this.y -= o.y;
      this.z -= o.z;
      return this;
    };

    Vec.prototype.mul = function(n) {
      this.x *= n;
      this.y *= n;
      this.z *= n;
      return this;
    };

    Vec.prototype.div = function(n) {
      this.x /= n;
      this.y /= n;
      this.z /= n;
      return this;
    };

    Vec.prototype.mag = function(n) {
      return Math.sqrt(this.x * this.x + this.y * this.y + this.z * this.z);
    };

    Vec.prototype.normalize = function() {
      var mag;
      mag = this.mag();
      this.x /= mag;
      this.y /= mag;
      this.z /= mag;
      return this;
    };

    Vec.prototype.bound = function(x1, y1, z1, x2, y2, z2) {
      this.x = Math.min(x2, Math.max(x1, this.x));
      this.y = Math.min(y2, Math.max(y1, this.y));
      this.z = Math.min(z2, Math.max(z1, this.z));
      return this;
    };

    return Vec;

  })();

  Vec.fromAngleDist = function(angle, dist) {
    return new Vec(dist * Math.cos(angle), dist * Math.sin(angle));
  };

  window.addEventListener('load', function() {
    return new AntSim;
  });

}).call(this);
