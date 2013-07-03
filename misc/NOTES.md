# Some imagemagick tricks to save for later.

For making the animated gif for the README:

```
convert -crop 512x512+156+117 +repage -resize 50% -loop 0 -delay 7 *.png sample_cropped.gif
```