#!/bin/bash

sudo useradd -m cmto
sudo usermod -aG sudo cmto
sudo usermod --shell /bin/bash cmto
sudo passwd cmto


