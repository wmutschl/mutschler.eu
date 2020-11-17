#!/bin/bash
rsync -avuP --delete public/ fifei:$HOME/docker/container/swag/www/
