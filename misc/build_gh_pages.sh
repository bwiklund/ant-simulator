#!/bin/bash

wget \
  --recursive \
  --page-requisites \
  --convert-links \
  --domains localhost \
  http://localhost:8765/

mv localhost\:8765 build
git checkout gh-pages
mv build/* .
rm -rf build
gac "updated gh-pages build"
git push origin gh-pages
git checkout master
echo "Done"