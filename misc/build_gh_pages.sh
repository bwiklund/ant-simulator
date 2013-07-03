#!/bin/bash

wget \
  --recursive \
  --page-requisites \
  --convert-links \
  --domains localhost \
  http://localhost:8765/
