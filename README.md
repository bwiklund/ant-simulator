[<img src="https://raw.github.com/bwiklund/ant-simulator/master/misc/sample.gif">](http://bwiklund.github.io/ant-simulator/)

# ant simulator

simulating ant food gathering using scent trails

check out the [live demo](http://bwiklund.github.io/ant-simulator/)

# how it works

The ants' logic has no way of knowing where the food or nest are. The only input they have is their antennae, literally two data points in front of them, left and right, that they can sample. 

To follow a trail, sample the left and right antennae, and turn in the direction with a stronger signal.

The rules are fairly simple:

- if you're leaving the nest, drop a trail of 'nest trail' pheromone. Try to follow the 'food trail' pheromone.
- if you've just eaten, drop a trail of 'food trail' pheromone. Try to follow the 'home trail' pheromone.
- in either case, if you've lost the scent, wander randomly until you find it again.

If the values are tweaked right, both the foraging ants, and the ants returning home, will converge on a (fairly) optimal trail.