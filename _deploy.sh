#!/usr/bin/env bash

jekyll build

#scp -rp _site/* allenfai@allenfair.com:www/tennisfriend/
rsync  -av _site/* allenfai@allenfair.com:www/girders/
