# Raspi-FPV

Combines wifibroadcast and some cheap sensors to create a ground station for DIY HD FPV drone flying. 

## Tx

Ran on a Raspberry Pi Zero w with a raspi-cam and the envirophat sensor suite. 

The Tx monitors bluetooth and, when it receives a request, sends a config file to the ground station. This allows for different configurations between drones, and can later be used to change settings on the fly. 

Following the initialization, it uses the [wifibroadcast library](https://befinitiv.wordpress.com/wifibroadcast-analog-like-transmission-of-live-video-data/) to send telelmetry like altitude, attitude, OAT, and other data to the ground station for low-latency rendering. 

## Rx

Ran on a Raspberry Pi 3 with an elecrow monitor attatched, but can obvioulsy be used with other monitors. 

Following the bluetooth exchange discribed above, we receive the data over wifibroadcast and pipe it to a rendering application written on the latest version of [processing](processing.org) (as of writing.) The software can be expanded to fit any special purposes a user might have. 

### Parts list:
#### Rx
 - [Raspberry Pi Zero W](https://www.adafruit.com/product/3400)
 - [Envirophat sensor](https://www.adafruit.com/product/3194)
 - [Camera (the one I used, anything that works with raspicam will do just fine)](https://www.amazon.com/gp/product/B01LY05LOE/ref=oh_aui_detailpage_o04_s00?ie=UTF8&psc=1)
 - Wifi antenna (For wifibroadcast, see [this](https://befinitiv.wordpress.com/wifibroadcast-analog-like-transmission-of-live-video-data/) page for details and good cards. I haven't tested the built-in wifi, and I'm not sure it would even work.)
 - For power supply and cases, it will depend highly on your needs for your specific situation.
 
 #### Tx
  - [Raspberry Pi 3 (Model B)](https://www.adafruit.com/product/3055)
  - [Display (again, the one I used, but anything touchscreen should work well)](https://www.amazon.com/gp/product/B013JECYF2/ref=oh_aui_search_detailpage?ie=UTF8&psc=1)
  - Wifi antenna (For wifibroadcast, see [this](https://befinitiv.wordpress.com/wifibroadcast-analog-like-transmission-of-live-video-data/) page for details and good cards. I haven't tested the built-in wifi, and I'm not sure it would even work.)
