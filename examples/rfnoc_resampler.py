#!/usr/bin/env python2
# -*- coding: utf-8 -*-
##################################################
# GNU Radio Python Flow Graph
# Title: Rfnoc Resampler
# Generated: Fri Mar  3 14:31:44 2017
##################################################

if __name__ == '__main__':
    import ctypes
    import sys
    if sys.platform.startswith('linux'):
        try:
            x11 = ctypes.cdll.LoadLibrary('libX11.so')
            x11.XInitThreads()
        except:
            print "Warning: failed to XInitThreads()"

from PyQt4 import Qt
from gnuradio import analog
from gnuradio import blocks
from gnuradio import eng_notation
from gnuradio import gr
from gnuradio import qtgui
from gnuradio import uhd
from gnuradio.eng_option import eng_option
from gnuradio.filter import firdes
from gnuradio.qtgui import Range, RangeWidget
from math import floor
from optparse import OptionParser
import SynchronousLabs
import ctypes
import ettus
import sip
import sys
from gnuradio import qtgui


class rfnoc_resampler(gr.top_block, Qt.QWidget):

    def __init__(self):
        gr.top_block.__init__(self, "Rfnoc Resampler")
        Qt.QWidget.__init__(self)
        self.setWindowTitle("Rfnoc Resampler")
        qtgui.util.check_set_qss()
        try:
            self.setWindowIcon(Qt.QIcon.fromTheme('gnuradio-grc'))
        except:
            pass
        self.top_scroll_layout = Qt.QVBoxLayout()
        self.setLayout(self.top_scroll_layout)
        self.top_scroll = Qt.QScrollArea()
        self.top_scroll.setFrameStyle(Qt.QFrame.NoFrame)
        self.top_scroll_layout.addWidget(self.top_scroll)
        self.top_scroll.setWidgetResizable(True)
        self.top_widget = Qt.QWidget()
        self.top_scroll.setWidget(self.top_widget)
        self.top_layout = Qt.QVBoxLayout(self.top_widget)
        self.top_grid_layout = Qt.QGridLayout()
        self.top_layout.addLayout(self.top_grid_layout)

        self.settings = Qt.QSettings("GNU Radio", "rfnoc_resampler")
        self.restoreGeometry(self.settings.value("geometry").toByteArray())

        ##################################################
        # Variables
        ##################################################
        self.samp_rate = samp_rate = 200e6
        self.interp = interp = 2
        self.dec = dec = 1
        self.wave_freq = wave_freq = samp_rate/10
        self.wave_amp = wave_amp = 0.9
        self.device3 = variable_uhd_device3_0 = ettus.device3(uhd.device_addr_t( ",".join(('type=x300', '')) ))
        self.variable_qtgui_label_0_0 = variable_qtgui_label_0_0 = float(interp)/dec
        self.variable_qtgui_label_0 = variable_qtgui_label_0 = samp_rate*float(dec)/interp
        self.noise_amp = noise_amp = .01

        ##################################################
        # Blocks
        ##################################################
        self._wave_freq_range = Range(-samp_rate/2, samp_rate/2, samp_rate/100, samp_rate/10, 200)
        self._wave_freq_win = RangeWidget(self._wave_freq_range, self.set_wave_freq, 'Wave Freq', "counter_slider", float)
        self.top_layout.addWidget(self._wave_freq_win)
        self._wave_amp_range = Range(0, 1, 0.1, 0.9, 200)
        self._wave_amp_win = RangeWidget(self._wave_amp_range, self.set_wave_amp, 'Wave Amplitude', "counter_slider", float)
        self.top_layout.addWidget(self._wave_amp_win)
        self._noise_amp_range = Range(0, 1, 0.0001, .01, 200)
        self._noise_amp_win = RangeWidget(self._noise_amp_range, self.set_noise_amp, 'Noise Amplitude', "counter_slider", float)
        self.top_layout.addWidget(self._noise_amp_win)
        self._interp_range = Range(0, 4096, 1, 2, 200)
        self._interp_win = RangeWidget(self._interp_range, self.set_interp, 'Decimation Numerator', "counter_slider", int)
        self.top_grid_layout.addWidget(self._interp_win, 0,0)
        self._dec_range = Range(0, 4096, 1, 1, 200)
        self._dec_win = RangeWidget(self._dec_range, self.set_dec, 'Decimation Denominator', "counter_slider", int)
        self.top_grid_layout.addWidget(self._dec_win, 0,1)
        self._variable_qtgui_label_0_0_tool_bar = Qt.QToolBar(self)

        if None:
          self._variable_qtgui_label_0_0_formatter = None
        else:
          self._variable_qtgui_label_0_0_formatter = lambda x: x

        self._variable_qtgui_label_0_0_tool_bar.addWidget(Qt.QLabel('The Decimation Rate '+": "))
        self._variable_qtgui_label_0_0_label = Qt.QLabel(str(self._variable_qtgui_label_0_0_formatter(self.variable_qtgui_label_0_0)))
        self._variable_qtgui_label_0_0_tool_bar.addWidget(self._variable_qtgui_label_0_0_label)
        self.top_layout.addWidget(self._variable_qtgui_label_0_0_tool_bar)

        self._variable_qtgui_label_0_tool_bar = Qt.QToolBar(self)

        if None:
          self._variable_qtgui_label_0_formatter = None
        else:
          self._variable_qtgui_label_0_formatter = lambda x: x

        self._variable_qtgui_label_0_tool_bar.addWidget(Qt.QLabel('Decimated Sample Rate'+": "))
        self._variable_qtgui_label_0_label = Qt.QLabel(str(self._variable_qtgui_label_0_formatter(self.variable_qtgui_label_0)))
        self._variable_qtgui_label_0_tool_bar.addWidget(self._variable_qtgui_label_0_label)
        self.top_layout.addWidget(self._variable_qtgui_label_0_tool_bar)

        self.uhd_rfnoc_streamer_fifo_0 = ettus.rfnoc_generic(
            self.device3,
            uhd.stream_args( # TX Stream Args
                cpu_format="fc32",
                otw_format="sc16",
                args="gr_vlen={0},{1}".format(1, "" if 1 == 1 else "spp={0}".format(1)),
            ),
            uhd.stream_args( # RX Stream Args
                cpu_format="fc32",
                otw_format="sc16",
                args="gr_vlen={0},{1}".format(1, "" if 1 == 1 else "spp={0}".format(1)),
            ),
            "FIFO", -1, -1,
        )
        self.qtgui_freq_sink_x_0 = qtgui.freq_sink_c(
        	8192, #size
        	firdes.WIN_HAMMING, #wintype
        	0, #fc
        	samp_rate*float(dec)/interp, #bw
        	"", #name
        	1 #number of inputs
        )
        self.qtgui_freq_sink_x_0.set_update_time(0.10)
        self.qtgui_freq_sink_x_0.set_y_axis(-140, 10)
        self.qtgui_freq_sink_x_0.set_y_label('Relative Gain', 'dB')
        self.qtgui_freq_sink_x_0.set_trigger_mode(qtgui.TRIG_MODE_FREE, 0.0, 0, "")
        self.qtgui_freq_sink_x_0.enable_autoscale(False)
        self.qtgui_freq_sink_x_0.enable_grid(True)
        self.qtgui_freq_sink_x_0.set_fft_average(1.0)
        self.qtgui_freq_sink_x_0.enable_axis_labels(True)
        self.qtgui_freq_sink_x_0.enable_control_panel(False)

        if not True:
          self.qtgui_freq_sink_x_0.disable_legend()

        if "complex" == "float" or "complex" == "msg_float":
          self.qtgui_freq_sink_x_0.set_plot_pos_half(not True)

        labels = ['', '', '', '', '',
                  '', '', '', '', '']
        widths = [1, 1, 1, 1, 1,
                  1, 1, 1, 1, 1]
        colors = ["blue", "red", "green", "black", "cyan",
                  "magenta", "yellow", "dark red", "dark green", "dark blue"]
        alphas = [1.0, 1.0, 1.0, 1.0, 1.0,
                  1.0, 1.0, 1.0, 1.0, 1.0]
        for i in xrange(1):
            if len(labels[i]) == 0:
                self.qtgui_freq_sink_x_0.set_line_label(i, "Data {0}".format(i))
            else:
                self.qtgui_freq_sink_x_0.set_line_label(i, labels[i])
            self.qtgui_freq_sink_x_0.set_line_width(i, widths[i])
            self.qtgui_freq_sink_x_0.set_line_color(i, colors[i])
            self.qtgui_freq_sink_x_0.set_line_alpha(i, alphas[i])

        self._qtgui_freq_sink_x_0_win = sip.wrapinstance(self.qtgui_freq_sink_x_0.pyqwidget(), Qt.QWidget)
        self.top_layout.addWidget(self._qtgui_freq_sink_x_0_win)
        self.blocks_throttle_0 = blocks.throttle(gr.sizeof_gr_complex*1, samp_rate,True)
        self.blocks_add_xx_0 = blocks.add_vcc(1)
        self.analog_sig_source_x_0 = analog.sig_source_c(samp_rate, analog.GR_COS_WAVE, wave_freq, wave_amp, 0)
        self.analog_fastnoise_source_x_0 = analog.fastnoise_source_c(analog.GR_GAUSSIAN, noise_amp, 0, 8192)
        self.SynchronousLabs_downSampler_0 = SynchronousLabs.downSampler(
                  self.device3,
                  uhd.stream_args( # TX Stream Args
                        cpu_format="fc32",
                        otw_format="sc16",
                        args="",
                  ),
                  uhd.stream_args( # RX Stream Args
                        cpu_format="fc32",
                        otw_format="sc16",
                        args="",
                  ),
                  -1,
                  -1
          )

        self.SynchronousLabs_downSampler_0.set_arg("sr_n", interp)
        self.SynchronousLabs_downSampler_0.set_arg("sr_m", dec)


        ##################################################
        # Connections
        ##################################################
        self.connect((self.analog_fastnoise_source_x_0, 0), (self.blocks_add_xx_0, 1))
        self.connect((self.analog_sig_source_x_0, 0), (self.blocks_add_xx_0, 0))
        self.connect((self.blocks_add_xx_0, 0), (self.blocks_throttle_0, 0))
        self.connect((self.blocks_throttle_0, 0), (self.uhd_rfnoc_streamer_fifo_0, 0))
        self.connect((self.SynchronousLabs_downSampler_0, 0), (self.qtgui_freq_sink_x_0, 0))
        self.device3.connect(self.uhd_rfnoc_streamer_fifo_0.get_block_id(), 0, self.SynchronousLabs_downSampler_0.get_block_id(), 0)

    def closeEvent(self, event):
        self.settings = Qt.QSettings("GNU Radio", "rfnoc_resampler")
        self.settings.setValue("geometry", self.saveGeometry())
        event.accept()

    def get_samp_rate(self):
        return self.samp_rate

    def set_samp_rate(self, samp_rate):
        self.samp_rate = samp_rate
        self.set_wave_freq(self.samp_rate/10)
        self.set_variable_qtgui_label_0(self._variable_qtgui_label_0_formatter(self.samp_rate*float(self.dec)/self.interp))
        self.qtgui_freq_sink_x_0.set_frequency_range(0, self.samp_rate*float(self.dec)/self.interp)
        self.blocks_throttle_0.set_sample_rate(self.samp_rate)
        self.analog_sig_source_x_0.set_sampling_freq(self.samp_rate)

    def get_interp(self):
        return self.interp

    def set_interp(self, interp):
        self.interp = interp
        self.set_variable_qtgui_label_0_0(self._variable_qtgui_label_0_0_formatter(float(self.interp)/self.dec))
        self.set_variable_qtgui_label_0(self._variable_qtgui_label_0_formatter(self.samp_rate*float(self.dec)/self.interp))
        self.qtgui_freq_sink_x_0.set_frequency_range(0, self.samp_rate*float(self.dec)/self.interp)
        self.SynchronousLabs_downSampler_0.set_arg("sr_n", self.interp)

    def get_dec(self):
        return self.dec

    def set_dec(self, dec):
        self.dec = dec
        self.set_variable_qtgui_label_0_0(self._variable_qtgui_label_0_0_formatter(float(self.interp)/self.dec))
        self.set_variable_qtgui_label_0(self._variable_qtgui_label_0_formatter(self.samp_rate*float(self.dec)/self.interp))
        self.qtgui_freq_sink_x_0.set_frequency_range(0, self.samp_rate*float(self.dec)/self.interp)
        self.SynchronousLabs_downSampler_0.set_arg("sr_m", self.dec)

    def get_wave_freq(self):
        return self.wave_freq

    def set_wave_freq(self, wave_freq):
        self.wave_freq = wave_freq
        self.analog_sig_source_x_0.set_frequency(self.wave_freq)

    def get_wave_amp(self):
        return self.wave_amp

    def set_wave_amp(self, wave_amp):
        self.wave_amp = wave_amp
        self.analog_sig_source_x_0.set_amplitude(self.wave_amp)

    def get_variable_uhd_device3_0(self):
        return self.variable_uhd_device3_0

    def set_variable_uhd_device3_0(self, variable_uhd_device3_0):
        self.variable_uhd_device3_0 = variable_uhd_device3_0

    def get_variable_qtgui_label_0_0(self):
        return self.variable_qtgui_label_0_0

    def set_variable_qtgui_label_0_0(self, variable_qtgui_label_0_0):
        self.variable_qtgui_label_0_0 = variable_qtgui_label_0_0
        Qt.QMetaObject.invokeMethod(self._variable_qtgui_label_0_0_label, "setText", Qt.Q_ARG("QString", eng_notation.num_to_str(self.variable_qtgui_label_0_0)))

    def get_variable_qtgui_label_0(self):
        return self.variable_qtgui_label_0

    def set_variable_qtgui_label_0(self, variable_qtgui_label_0):
        self.variable_qtgui_label_0 = variable_qtgui_label_0
        Qt.QMetaObject.invokeMethod(self._variable_qtgui_label_0_label, "setText", Qt.Q_ARG("QString", eng_notation.num_to_str(self.variable_qtgui_label_0)))

    def get_noise_amp(self):
        return self.noise_amp

    def set_noise_amp(self, noise_amp):
        self.noise_amp = noise_amp
        self.analog_fastnoise_source_x_0.set_amplitude(self.noise_amp)


def main(top_block_cls=rfnoc_resampler, options=None):

    from distutils.version import StrictVersion
    if StrictVersion(Qt.qVersion()) >= StrictVersion("4.5.0"):
        style = gr.prefs().get_string('qtgui', 'style', 'raster')
        Qt.QApplication.setGraphicsSystem(style)
    qapp = Qt.QApplication(sys.argv)

    tb = top_block_cls()
    tb.start()
    tb.show()

    def quitting():
        tb.stop()
        tb.wait()
    qapp.connect(qapp, Qt.SIGNAL("aboutToQuit()"), quitting)
    qapp.exec_()


if __name__ == '__main__':
    main()
