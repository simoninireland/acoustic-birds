# Makefile for acoustic bird counting experiment
#
# Copyright (C) 2024 Simon Dobson
#
# This file is part of acoustic-birds, an experiment in bird abundance
# sampling using acoustic sensors
#
# This is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This software is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this software. If not, see <http://www.gnu.org/licenses/gpl.html>.

# Puffin icons created by Amethyst prime - Flaticon - https://www.flaticon.com/free-icons/puffin


# ---------- Sources ----------

REPORTER_SOURCES = \
	reporter/config.py \
	reporter/main.py
REPORTER_LIBS = \
	$(SSD1306) \
	$(MQTT)


# ---------- Device ----------

PORT = /dev/ttyACM0


# ---------- Downloads ----------

# MicroPython firmware
MICROPYTHON_UF2_URL = https://micropython.org/download/rp2-pico-w/rp2-pico-w-latest.uf2
MICROPYTHON_UF2 = rp2-pico-w-latest.uf2

# SSD1306 display driver from Adafruit (technically deprecated)
SSD1306_URL = https://raw.githubusercontent.com/adafruit/micropython-adafruit-ssd1306/master/ssd1306.py
SSD1306 = ssd1306.py

# MQTT client
MQTT_URL = https://peppe8o.com/download/micropython/w5100s-evb-pico/umqttsimple.py
MQTT = umqttsimple.py


# ----- Tools -----

# Root directory
ROOT = $(shell pwd)

# Base commands
PYTHON = python3
PIP = pip
WGET = wget
AMPY = ampy
CHDIR = cd
MKDIR = mkdir -p
RM = rm -fr
CP = cp
CAT = cat
WGET = wget
VIRTUALENV = $(PYTHON) -m venv
ACTIVATE = . $(VENV)/bin/activate

# Makefile environment
SHELL := bash
.SHELLFLAGS := -eu -o pipefail -c
MAKEFLAGS += --warn-undefined-variables
MAKEFLAGS += --no-builtin-rules

# Downloads directory
LIB = lib

# Development tools
VENV = venv3
REQUIREMENTS = requirements.txt


# ----- Top-level targets -----

# Default prints a help message
help:
	@make usage


# Deploy to the Pico
.PHONY: reporter
reporter: env
	for lib in $(REPORTER_LIBS); do  $(AMPY) --port $(PORT) put $(LIB)/$$lib; done
	for f in $(REPORTER_SOURCES); do $(AMPY) --port $(PORT) put $$f; done


# Build a development venv from the requirements in the repo
.PHONY: env
env: $(VENV) downloads

$(VENV):
	$(VIRTUALENV) $(VENV)
	$(ACTIVATE) && $(PIP) install -U pip wheel && $(PIP) install -r $(REQUIREMENTS)


# Download extra files
downloads: $(LIB) $(LIB)/$(MICROPYTHON_UF2) $(LIB)/$(SSD1306) $(LIB)/$(MQTT)

$(LIB):
	$(MKDIR) $(LIB)

$(LIB)/$(MICROPYTHON_UF2):
	$(WGET) -O $(LIB)/$(MICROPYTHON_UF2) $(MICROPYTHON_UF2_URL)

$(LIB)/$(SSD1306):
	$(WGET) -O $(LIB)/$(SSD1306) $(SSD1306_URL)

$(LIB)/$(MQTT):
	$(WGET) -O $(LIB)/$(MQTT) $(MQTT_URL)


# Clean up the build
clean:

# Clean up everything, including the downloads
reallyclean: clean
	$(RM) $(VENV) $(LIB)


# ----- Usage -----

define HELP_MESSAGE
   make env          build the development environment
   make reporter     deploy the Reporter
   make clean        clean-up the build
   make reallyclean  clean-up the downloads as well

endef
export HELP_MESSAGE

usage:
	@echo "$$HELP_MESSAGE"
