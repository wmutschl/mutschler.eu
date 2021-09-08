#!/bin/bash
hugo
rsync -avuP --delete public/ mutschler.eu:/home/wmutschl/docker/swag/www/
