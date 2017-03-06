# gr-SynchronousLabs

This project implements RFNoc out-of-tree Module.

The project currently contains the following IP:

  - Fractional Downsampler - This is a rational resampler that allows for decimation rates of 4095/4096 to 4096
  - Fractional Upsampler - This is a rational resampler that allows for interpolation rates of 4095/4096 to 4096

To build the software project:

  **mkdir build**
  **cd build**
  **cmake ../**
  **make**
  **sudo make**
  
Either load the pre-built FPGA images in the ./binaries/ directory or build the FPGA project via:

  **uhd_image_builder.py upSampler -I /home/jason/Documents/nocblocks/rfnoc-SynchronousLabs/rfnoc/fpga-src/  -d x300 -t       X300_RFNOC_HG -m 5 --fill-with-fifos**
  
Run the example GNURadio-Companion applications in the ./examples/ directory  
