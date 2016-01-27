bbPiCam
=======

Raspberry Pi Baby Monitor.

Features:
* True day and night vision.
* 1280 x 960 HD video quality.
* RGB LED shows temperature at a quick glance.
* RTSP & RTMP audio video stream (playable on web browsers and Android devices).

![Image of bbPiCam](https://github.com/jasaw/bbPiCam/blob/master/docs/bbPiCam_mini.jpg)

![Day view](https://github.com/jasaw/bbPiCam/blob/master/docs/day.jpg)

![Night view](https://github.com/jasaw/bbPiCam/blob/master/docs/night.jpg)

# Hardware

Setting up the hardware requires a fair bit of soldering and drilling. Let's get started ...

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
* 12V DC 1A regulated power adaptor
* Panel Mount Tactile Pushbutton
* Panel Mount 2.5mm Bulkhead Male DC Power Connector
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

The I2S signals are exposed via P5 header, next to the P1 header. Solder a header on it. Refer to [RPi Low-level peripherals](http://elinux.org/RPi_Low-level_peripherals) for pinouts.

As for the audio codec, I used the mbed AudioCodec board based on TI TLV320AIC23B. I had to make a few modifications to the board, which may not suit everyone. Those who are not comfortable with soldering can explore other codecs like the PROTO audio codec board based on WM8731. This [I2S guide](http://blog.koalo.de/2013/05/i2s-support-for-raspberry-pi.html) by Koalo may be helpful.

Modifications made to the mbed AudioCodec board:
* MIC Bias (pin 17) and MIC Input (pin 18) of the IC are not exposed on a connector. Wires were soldered from the 2 MIC and GND pins of the IC to the unused side of the header.

![mbed audio codec mod](https://github.com/jasaw/bbPiCam/blob/master/docs/mbed-codec-mods.jpg)

* The 12MHz crystal was removed and MCLK (pin 25) and wires soldered from the MCLK pin to an unused header pin.

The crystal was removed so GPCLK0 signal can be fed as the MCLK to ensure MCLK and I2S BCLK are synchronous. This was done after I discovered both clocks were drifting, causing clicks on the 1st channel of the audio input. I did not manage to remove the clicking noise completely, so I ended up configuring ffmpeg to only use channel 2 and output mono audio.

Connection between the mbed AudioCodec and the Raspberry Pi B:

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

If using Raspberry Pi B+ or Pi2 B:

```
mbed AudioCodec   |     Raspberry Pi
----------------- +---------------------
    BCLK   (I2S)  |       J8 - 12
    CS            |       3V3
    DIN    (I2S)  |       J8 - 40
    DOUT   (I2S)  |       J8 - 38
    LRCOUT (I2S)  |       J8 - 35
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

You can use this mic resistor network but the input gain is not high enough even with the 20dB gain enabled on the TLV320AIC23B.

![mic resistor network](https://github.com/jasaw/bbPiCam/blob/master/docs/mic_circuit.png)

The components in the grey box can be replaced with a mic pre-amp circuit with automatic gain control.

Adjust the R1 resistor to set the gain.

### RGB Temperature LED

RGB LED is controlled by PCA9635 driver. There are other more suitable LED driver alternatives. I chose this part because I have left over from another project.

![mic resistor network](https://github.com/jasaw/bbPiCam/blob/master/docs/pca9635.png)

### Shutdown Button

The "Shutdown" button does the obvious, shuts down the device when pressed.

Button is connected to P1-11 and pulled up to 3.3V via 10K resistor.

![shutdown button](https://github.com/jasaw/bbPiCam/blob/master/docs/reset_button.png)

# Software

This guide only applies to Raspberry Pi B.

Software modifications I've done so far:
* I2S and rpi_mbed drivers to use GPCLK0 as MCLK.
* Reduced the ffmpeg's default max_interleave_delta value. By default, ffmpeg buffers both audio and video stream in attempt to synchronize them, but ffmpeg is unable to synchronize the streams because raspivid video output does not contain timestamp information. By reducing the max_interleave_delta value, the de-sync between audio and video can be reduced. The only problem is, setting max_interleave_delta from command line did not do anything, so I just changed the default value as a quick workaround.

Before we start, you'll need a Linux based Raspberry Pi Operating System. I strongly recommend Raspbian unless you know what you are doing. I use Raspbian Wheezy 2014-06-20.

_If you're using model B+ or 2 B, I recommend the latest Raspbian Jessie image with device-tree enabled. You can load the I2S driver by adding dtoverlay=i2s-mmap to /boot/config.txt. I haven't got time to migrate this project to the Pi2, so you'll have to figure the rest out yourself. Sorry..._

While waiting for the Raspbian installation onto an SD card, we download the required software on a PC.

```
git clone https://github.com/jasaw/bbPiCam.git
cd bbPiCam
git submodule init
git submodule update
```

This is going to take a while, so go do other things and come back later ...

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

### Install build tools
```
sudo apt-get install build-essential
```

### Kernel and Drivers

The kernel needs to be configured and cross compiled, then transfered to the Pi.

Change into the kernel directory and set things up:
```
cd kernel
mkdir modules
```

**Important**: Edit the build_env file to reflect your directory structure.

Load environment variables:
```
. build_env
```

Clean up
```
cd linux
make mrproper
```

Get kernel config from Pi running Raspbian. On the Pi, run:
```
zcat /proc/config.gz > /tmp/.config
```

Copy .config file to linux directory:
```
scp pi@rpi-cam:/tmp/.config ./.config
```

Restore the kernel config, then configure it:
```
make oldconfig
make menuconfig
```

Enable rpi_mbed under:
```
   Device Drivers
     > Sound card support
       > Advanced Linux Sound Architecture
         > ALSA for SoC audio support
           > SoC Audio support for the Broadcom BCM2708 I2S module
```

Enable PCA9635 LED driver:
```
   Device Drivers
     > LED support
       > LED support for PCA9635 I2C chip
```

Compile kernel
```
make -j4
```

Install kernel modules
```
make modules_install
```

Create kernel.img from zImage (for Pi Model A & B)
```
cd ../tools/mkimage
./imagetool-uncompressed.py ${KERNEL_SRC}/arch/arm/boot/zImage
cd ../..
```

Create kernel7.img from zImage (for Pi Model A+, B+, 2 B)
```
cd ../tools/mkimage
./mkknlimg ${KERNEL_SRC}/arch/arm/boot/zImage kernel7.img
cd ../..
```

Remove symlinks in modules directory:
```
rm modules/lib/modules/3.12.28/build modules/lib/modules/3.12.28/source
tar czf modules.tar.gz modules/
```

Copy kernel.img and modules to the Pi
```
scp tools/mkimage/kernel.img pi@rpi-cam:/tmp
scp modules.tar.gz pi@rpi-cam:/tmp
```

Replace the kernel on the Pi. On the Pi, run:
```
cd /boot
sudo mv kernel.img kernel.img.org
sudo mv /tmp/kernel.img .
cd /tmp
tar xzf modules.tar.gz
cd /lib
sudo mv modules modules_org
sudo mv /tmp/modules/lib/modules /lib
sudo chown -R root:root /lib/modules
```

add below lines to /etc/modules
```
snd_soc_bcm2708
snd_soc_bcm2708_i2s
bcm2708_dmaengine
snd_soc_tlv320aic23
snd_soc_rpi_mbed
```

Reboot the Pi
```
sudo reboot
```

If your Pi survived the reboot, you should be able to see the audio card:
```
arecord -L
```

If you can't see the audio card, try probing it on the I2C bus:
```
sudo modprobe i2c-dev
sudo apt-get install i2c-tools
sudo i2cdetect 1
```
It should have I2C address of 0x1b.

Test to see if it works:
```
alsamixer -c 1
arecord -D hw:1,0 -f DAT -r 8 /tmp/my_record.wav
```

The audio card can also be configured this way:
```
amixer -c 1 sset 'Mic' cap
amixer -c 1 sset 'Mic Input' on
amixer -c 1 sset 'Mic Booster' on
```

### Libraries and Dependencies

We need to set up libraries and dependencies on the Pi. On the Pi, run ...

Install tools and libraries.
```
sudo apt-get install build-essential
sudo apt-get install autotools-dev autoconf automake libtool
sudo apt-get install libasound2-dev
```

**Note**: All libraries and tools can be cross compiled on a PC and transfered to the Pi. For simplicity, we compile them on the Pi.

Build and install x264 library.
```
git clone git://git.videolan.org/x264
cd x264
./configure --disable-asm --enable-shared
make
sudo make install
```

Build and install lame encoder.
```
wget http://downloads.sourceforge.net/project/lame/lame/3.99/lame-3.99.5.tar.gz
tar xzf lame-3.99.5.tar.gz
cd lame-3.99.5
./configure
make
sudo make install
```

Build and install AAC encoder.
```
wget http://downloads.sourceforge.net/project/faac/faac-src/faac-1.28/faac-1.28.tar.gz
tar xzf faac-1.28.tar.gz
cd faac-1.28
./configure
make
sudo make install
```

Build and install the latest ffmpeg. At the time of this writing, the Raspbian version is too old and doesn't support H264.
On PC:
```
scp -r programs/ffmpeg pi@rpi-cam:
```
On Pi:
```
cd ffmpeg
./configure --enable-shared --enable-gpl --prefix=/usr --enable-nonfree --enable-libmp3lame --enable-libfaac --enable-libx264 --enable-version3 --disable-mmx
make
sudo make install
```

### Enable RTSP and RTMP streaming

Install crtmpserver
```
sudo apt-get install crtmpserver
```

Edit the below section of /etc/crtmpserver/applications/flvplayback.lua
```
validateHandshake=false,
keyframeSeek=false,
seekGranularity=0.1
clientSideBuffer=30
```

Restart crtmpserver
```
sudo service crtmpserver restart
```

Install nginx web server
```
sudo apt-get install nginx
sudo server nginx start
```

Copy web server files
On PC:
```
cd programs/crtmpserver
unzip jwplayer-6.10.zip
scp -r jwplayer pi@rpi-cam:/usr/share/nginx/www
scp index.rtsp.html pi@rpi-cam:/usr/share/nginx/www/index.html
```

Restart nginx
```
sudo server nginx restart
```

Copy start up scripts.
On PC:
```
scp programs/bbpicam pi@rpi-cam:
scp programs/bbpicam_stream pi@rpi-cam:
```
On Pi:
```
sudo mkdir /opt/bbpicam
sudo cp -f bbpicam_stream /opt/bbpicam/bbpicam_stream
sudo cp -f bbpicam /etc/init.d/bbpicam
sudo chown root:root /etc/init.d/bbpicam
sudo service bbpicam start
```

Start audio video stream automatically at boot:
```
sudo insserv bbpicam
```

Point your browser to http://rpi-cam. I have tested this on Chrome and Firefox.
If you want to play the stream from an Android device, try "RTSP Player" app.

### RGB Temperature LED

The purpose of this RGB LED is to give a quick visual feedback of the room temperature.
* Blue - lower than 18 degrees Celcius
* Green - 22 degrees Celcius
* Red - higher than 26 degrees Celcius

Transfer required software to the Pi.
On PC:
```
scp -r programs/hidapi pi@rpi-cam:
scp -r programs/TEMPered pi@rpi-cam:
scp programs/temper2led_init pi@rpi-cam:
```

On Pi, install the dependencies.
```
sudo apt-get install libudev-dev libusb-1.0-0-dev libusb-dev
```

add below line to /etc/modules
```
leds-pca9635
```

Build HIDAPI library.
```
cd hidapi
./bootstrap
./configure
make
cd -
```

Build TEMPered.
```
cd TEMPered
cmake .
make
cd -
```

Find the TEMPer device
```
TEMPered/examples/enumerate
```

Install TEMPer 2 LED
```
sudo mkdir /opt/temper2led
sudo cp -f TEMPered/examples/temper2led /opt/temper2led/temper2led
sudo cp -f temper2led_init /etc/init.d/temper2led_init
sudo chown root:root /etc/init.d/temper2led_init
sudo service temper2led_init start
```

Start TEMPer 2 LED automatically at boot:
```
sudo insserv temper2led_init
```

### Shutdown Button watcher

Transfer shutdown_button to the Pi.
On PC:
```
scp -r programs/shutdown_button pi@rpi-cam:
```

Build shutdown_button.
```
cd shutdown_button
make
cd -
```

Install shutdown_button.
```
sudo mkdir /opt/shutdown_button
sudo cp -f shutdown_button/shutdown_button_init /etc/init.d/shutdown_button_init
sudo cp -f shutdown_button/shutdown_button /opt/shutdown_button/shutdown_button
sudo chown root:root /etc/init.d/shutdown_button_init
sudo service shutdown_button_init start
```

Start shutdown_button automatically at boot:
```
sudo insserv shutdown_button_init
```

### HLS (alternative)

HLS is short for HTTP Live Streaming. HLS is implemented by Apple and only works well on Apple devices and Safari browser.

HLS support on non-Apple devices or browsers:
- Android : Broken on most devices. At best unreliable.
- Firefox : Not supported.
- Chrome : Not supported.
- VLC : Works but does not automatically reload the playlist.

HLS also has the disadvantage of high latency, which is unacceptable for a baby monitor.

To switch to HLS protocol, try:
```
cd psips
make
make install
mkfifo /tmp/live.h264
raspivid -w 1280 -h 960 -fps 25 -t 0 -b 2400000 -o - | psips > /tmp/live.h264 &
sudo LD_LIBRARY_PATH=/usr/local/lib ffmpeg -y -re -fflags +nobuffer -i /tmp/live.h264 -fflags +nobuffer -re -f alsa -ar 16000 -ac 2 -i hw:1,0 -map 0:0 -map 1:0 -c:v copy -strict -2 -c:a aac -b:a 32k -ac 1 -af "pan=1c|c0=c1" -f ssegment -segment_time 5 -segment_format mpegts -segment_list "/usr/share/nginx/www/live.m3u8" -segment_wrap 2 -segment_list_size 2 -segment_list_entry_prefix "live/" -segment_list_flags live -segment_list_type m3u8 "live/%08d.ts"
```

You also need to adjust /usr/share/nginx/www/index.html to serve the m3u8 playlist.

### Multicast (alternative)

Be very careful when multicasting. If your switch does **not** support IGMP snooping, it **will** flood your network and may cause significant impact on your throughput.

If you still want to try multicasting:
```
cd psips
make
make install
mkfifo /tmp/live.h264
raspivid -w 1280 -h 960 -fps 25 -t 0 -b 2400000 -o - | psips > live.h264 &
LD_LIBRARY_PATH=/usr/local/lib ffmpeg -y -v debug -re -fflags +nobuffer -r 25.126 -i /home/pi/live.h264 -fflags +nobuffer -re -f alsa -ar 16000 -ac 2 -i hw:1,0 -map 0:0 -map 1:0 -c:v copy -strict -2 -c:a aac -b:a 32k -ac 1 -af "pan=1c|c0=c1" -f mpegts 'udp://239.255.255.100:1234?ttl=4&pkt_size=1400'
```

### Motion (alternative for running security camera with motion detection)

[Motion](http://www.lavrsen.dk/foswiki/bin/view/Motion/WebHome) is a program that monitors the video signal from cameras and detect motion. It includes a web server that serves the video feed as MJPEG and able to capture and save images when motion is detected.

Install motion dependencies
```
sudo apt-get install libav-tools libavcodec54 libavdevice53 libavfilter2 libavfilter3 libavformat54 libavresample1 libavutil52 libdc1394-22 libmysqlclient18 libopencore-amrnb0 libopencore-amrwb0 libopencv-core2.3 libopencv-core2.4 libopencv-imgproc2.3 libopencv-imgproc2.4 libopus0 libpq5 libraw1394-11 libvo-aacenc0 libvo-amrwbenc0 libx264-130 mysql-common
```

Get pre-compiled motion binary and sample configuration file from programs/motion-mmal-opt.tar.gz

Run motion and point your browser to http://rpi-cam:8081

If you want to compile your own motion software, install devel libraries, git clone the Raspberry Pi motion-mmal repository:
```
sudo apt-get install libjpeg62 libjpeg62-dev libavformat53 libavformat-dev libavcodec53 libavcodec-dev libavutil51 libavutil-dev libc6-dev zlib1g-dev libmysqlclient18 libmysqlclient-dev libpq5 libpq-dev
git clone https://github.com/dozencrows/motion.git motion-mmal
cd motion-mmal
git checkout mmal-test
```
Please refer to its BUILD-HOWTO file for build instructions.

# Improvements?

This is very much a prototype with breakout boards stuck together using cable ties and sticky tape. The enclosure is way too big as well.
If I have more time, I certainly would like to improve a few things:
* Add a speaker for playing lullabies and enable 2-way audio comms.
* Bigger IR Light board. The current circular IR Light board is slightly too small and blocking the corners of the view.
* Custom designed PCB that plugs onto the Pi's P1 and P5 headers, to replace all the breakout boards.
* 3D printed enclosure.

