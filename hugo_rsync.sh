#!/bin/bash
hugo
rsync -avuP --delete public/ fifei:/home/wmutschl/docker/container/swag/www/
