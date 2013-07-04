#!/bin/bash

wget \
  --recursive \
  --page-requisites \
  --convert-links \
  --domains localhost \
  http://localhost:8765/

git checkout gh-pages
mv localhost\:8765 build
rsync -a build/* ./
rm -rf build
git add -A .
git commit -m "updated gh-pages build"
git push origin gh-pages
git checkout master
echo "Done"