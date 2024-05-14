# Main file for MQTT reporter
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

from machine import Pin, SoftI2C, reset
import network
from umqttsimple import MQTTClient
import time
import framebuf
import ssd1306
import config


# ---------- Connect to the display ----------

i2c = SoftI2C(scl=Pin(5), sda=Pin(4))
oled = ssd1306.SSD1306_I2C(config.oled_width, config.oled_height, i2c)


# ---------- Simplified display interface ----------

def display(ss = None):
    '''Print a string or array of strings on the display.
    Passing None clears the display

    :param ss: a string, or a list or array of strings'''
    if ss is None:
        # clear the display
        oled.fill(0)
    else:
        # expand a single string to an array of length 1
        if isinstance(ss, str):
            ss = [ss]

        # print each line
        x, y = 0, 0
        for line in ss:
            oled.text(line, x, y)
            if y == 0:
                # header
                 y += int(config.oled_lineheight / 2)
            y += config.oled_lineheight

    # update the display
    oled.show()


# ---------- Connect to the internet ----------

wlan = network.WLAN(network.STA_IF)
wlan.active(True)
wlan.connect(config.wifi_ssid, config.wifi_password)

# wait for connection
for _ in range(10):
    if wlan.status() < 0 or wlan.status() >= 3:
        break
    time.sleep(1)
if wlan.status() != 3:
    display("Can't connect to wifi")
    raise RuntimeError("Can't connect to wifi")
else:
    ips = wlan.ifconfig()
    display(f'{ips[0]}')
    time.sleep(2)
    display()

# display a holding message
display()
display(['', 'Waiting', 'for a bird', 'to sing...'])


# ---------- MQTT Messaging loop ----------

def mqtt_connect(id, host, username, password):
    client = MQTTClient(id, host, user=username, password=password, keepalive=60 * 60 * 6)
    client.connect()
    return client


def mqtt_reconnect():
    time.sleep(5)
    reset()


def mqtt_callback(topic, message):
    fields = message.decode('utf-8').split(',')
    lines = []
    lines.append('Bird we heard:')
    lines.append(fields[2])
    lines.append(f'({fields[3]})')
    lines.append('')
    lines.append(fields[1])
    display()
    display(lines)


# hook-up the connection to the correct topic
client = mqtt_connect(config.mqtt_client, config.mqtt_host, config.mqtt_username, config.mqtt_password)
client.set_callback(mqtt_callback)
client.subscribe(config.mqtt_topic.encode('utf-8'))

while(True):
    # run the message loop
    try:
        client.check_msg()
        time.sleep(1)
    except OSError as e:
        mqtt_reconnect()
