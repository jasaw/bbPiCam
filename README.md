bbPiCam
=======

Raspberry Pi Baby Monitor.

Features:
* True day and night vision.
* HD video quality.
* RGB LED shows temperature at a quick glance.
* RTSP & RTMP audio video stream.

![Image of bbPiCam](https://github.com/jasaw/bbPiCam/blob/master/docs/bbPiCam_mini.png)

![Day view](https://github.com/jasaw/bbPiCam/blob/master/docs/day.jpg)

![Night view](https://github.com/jasaw/bbPiCam/blob/master/docs/night.jpg)

## Hardware

### Bill of Materials

* Raspberry Pi Model B (rev 2)
* SD card
* Pi NoIR camera board - http://www.adafruit.com/products/1567
* AudioCODEC for mbed - RS Components part number: 754-1974
* RDing TEMPer2 Temperature sensor
* Diffused RGB (tri-color) LED - http://www.adafruit.com/products/159
* 5V 1A DC voltage regulator (e.g. LM7805) or DC-DC converter
* Electret Microphone Amplifier - MAX9814 with Auto Gain Control - http://www.adafruit.com/products/1713
* CS Mount Dual IR-Cut Optical Filter for CCTV CMOS Board Camera - http://www.camera2000.com/en/cs-mount-dual-ir-cut-optical-filter-for-cctv-cmos-board-camera.html
* IR Light Board for CCTV Camera Housing - http://www.camera2000.com/en/24-leds-45deg-25m-view-ir-light-board-for-dia-60mm-camera-housing.html
* PCA9635 LED controller
* 12V DC power supply
* Tactile button
* Mountable DC barrel connector
* Enclosure
* Heatshrink







```
J1 (Power input):
  pin 1: 12V
  pin 2: GND
J2 (Power output):
  pin 1: 12V
  pin 2: GND
  pin 3: Day/Night control signal input (solder to photovaristor switch IC output of the IR board)
  pin 4: Standard power level output (under IR-CUT condition)
J3: IR-CUT connection
```











## Software

Before we start, you'll need a Linux based Raspberry Pi Operating System. I strongly recommend Raspbian unless you know what you are doing. I use Raspbian Wheezy 2014-06-20.

While waiting for the Raspbian installation onto the SD card, we download the required software on a PC.

```
git clone https://github.com/jasaw/bbPiCam.git
cd bbPiCam
git submodule init
git submodule update
```

This is going to take a while, so go do other things and come back later...

Now apply patches.

```
patch -p1 -d kernel/linux < kernel/add-rpi-mbed.patch
patch -p1 -d kernel/linux < kernel/add-leds-pca9635.patch
patch -p1 -d programs/ffmpeg < programs/ffmpeg-reduce-max-interleave-delta.patch
patch -p1 -d programs/TEMPered < programs/TEMPered-fix-broken-cmakelists.patch
patch -p1 -d programs/TEMPered < programs/TEMPered-add-temper2led.patch
```

### Configure the Pi

Enable I2C and Camera on the Pi. On the Pi, run:
```
sudo raspi-config
```

