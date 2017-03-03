/* -*- c++ -*- */

#define SYNCHRONOUSLABS_API
#define ETTUS_API

%include "gnuradio.i"/*			*/// the common stuff

//load generated python docstrings
%include "SynchronousLabs_swig_doc.i"
//Header from gr-ettus
%include "ettus/device3.h"
%include "ettus/rfnoc_block.h"
%include "ettus/rfnoc_block_impl.h"

%{
#include "ettus/device3.h"
#include "ettus/rfnoc_block_impl.h"
#include "SynchronousLabs/downSampler.h"
#include "SynchronousLabs/upSampler.h"
%}

%include "SynchronousLabs/downSampler.h"
GR_SWIG_BLOCK_MAGIC2(SynchronousLabs, downSampler);
%include "SynchronousLabs/upSampler.h"
GR_SWIG_BLOCK_MAGIC2(SynchronousLabs, upSampler);
