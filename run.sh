#!/bin/bash

docker run --rm -it -p4000:4000 --volume="$PWD:/srv/jekyll" jekyll/jekyll:3.6 jekyll serve
