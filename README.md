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

Setting up the hardware requires a fair bit of soldering and drilling. Let's get started...

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

### Pi NoIR Camera, IR Light and IR-Cut Controller

There are 3 headers on the IR-Cut Controller board:

**J1** (Power input):
 - pin 1: 12V
 - pin 2: GND

**J2** (Power output):
 - pin 1: 12V
 - pin 2: GND
 - pin 3: Day/Night control signal input (solder to photovaristor switch IC output of the IR board)
 - pin 4: Standard power level output (under IR-CUT condition)

**J3** (IR-CUT connection)

Pin 3 of J2 (yellow wire) needs to be soldered to the output of the 3-pin photovaristor switch IC on the IR Light board. I recommend soldering it via a 1-pin connector so it can be disconnected when mounting to an enclosure.

Connect the J2 12V output connector (pin 1 & 2) to the IR Light board 12V input. **Warning:** My 12V connector had the wrong polarity. Make sure you check it and switch the wires on the connector if required.

Remove the protective tapes on the Pi camera and IR filter.

Now we just need to line up the 3 components this way:
Pi Camera --- 3mm Spacer --- IR Filter --- Spacer --- IR Light Board

The IR LEDs emit IR light mostly at the front, but some light are reflected back through the LED plastic case. This reflection is strong enough to interfere with the Pi camera if you don't have a something to block the light from the sides. I used heatshrink on the IR LEDs to stop the light reflection.

### I2S Audio Codec

A reliable way to enable audio input on the Pi is via the I2S interface. I2S is short for Inter-IC Sound. Only the Rev 2 and Model B+ Pi expose the I2S signals.

The I2S signals are exposed via P5 header, next to the P1 header. Solder a header on it.

Refer to [RPi Low-level peripherals](http://elinux.org/RPi_Low-level_peripherals) for pinouts.

As for the audio codec, I used the mbed AudioCodec board based on TI TLV320AIC23B. I had to make a few modifications to the board, which may not suit everyone. Those who are not comfortable with soldering can explore other codecs like the PROTO audio codec board based on WM8731. This [I2S guide](http://blog.koalo.de/2013/05/i2s-support-for-raspberry-pi.html) by Koalo may be helpful.

Modifications to the mbed AudioCodec board:
* MIC Bias (pin 17) and MIC Input (pin 18) of the IC are not exposed on a connector. Wires were soldered from the 2 MIC and GND pins of the IC to the unused side of the header.
* The 12MHz crystal was removed and MCLK (pin 25) and wires soldered from the MCLK pin to an unused header pin.

The crystal was removed so GPCLK0 signal can be fed as the MCLK to ensure MCLK and I2S BCLK are synchronous. This was done after I discovered both clocks were drifting, causing clicks on the audio input.

Connect the mbed AudioCodec to the Pi I2S header:

```
mbed AudioCodec   |     Raspberry Pi
----------------- +---------------------
    BCLK   (I2S)  |       P5 - 03
    CS            |       3V3
    DIN    (I2S)  |       P5 - 06
    DOUT   (I2S)  |       P5 - 05
    LRCOUT (I2S)  |       P5 - 04
    MODE          |       GND
                  |
    SCLK   (I2C)  |       P1 - 05
    SDIN   (I2C)  |       P1 - 03
                  |
    MCLK          |       GPCLK0
```

The 4 I2S wires and MCLK wire have to be kept as short as possible to reduce electrical interference as they will be carrying high speed signals.

![mbed AudioCodec I2S Connection](https://github.com/jasaw/bbPiCam/blob/master/docs/mbed_audio_codec_i2s.jpg)

The I2C pins are used for configuring the codec.

### MIC Input

I made my own mic front-end circuit, but I recommend one with automatic gain.

This is my mic resistor network.

![mic resistor network](https://github.com/jasaw/bbPiCam/blob/master/docs/mic_circuit.png)

The components in the grey box can be replaced with a mic pre-amp circuit with automatic gain control.

Adjust the R1 resistor to set the gain.

### RGB Temperature LED

RGB LED is controlled by PCA9635 driver.

![mic resistor network](https://github.com/jasaw/bbPiCam/blob/master/docs/pca9635.png)

## Software

Before we start, you'll need a Linux based Raspberry Pi Operating System. I strongly recommend Raspbian unless you know what you are doing. I use Raspbian Wheezy 2014-06-20.

While waiting for the Raspbian installation onto an SD card, we download the required software on a PC.

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


