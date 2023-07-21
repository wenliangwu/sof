#
# Unified topology for smart amplifier implementation.
#

# Include topology builder
include(`utils.m4')
include(`dai.m4')
include(`pipeline.m4')

# Include Token library
include(`sof/tokens.m4')

DEBUG_START

# define the default macros.
# define them in your specific platform .m4 if needed.

# define(`SMART_AMP_CORE', 1) define the DSP core that the DSM pipeline will be run on, if not done yet
ifdef(`SMART_AMP_CORE',`',`define(`SMART_AMP_CORE', 0)')

dnl define smart amplifier AFE index

# AFE related
# define(`SMART_AFE_PLAYBACK_INDEX', 1) define smart amplifier AFE index
ifdef(`SMART_AFE_PLAYBACK_INDEX',`',`fatal_error(note: Need to define AFE playback index for sof-smart-amplifier
)')
ifdef(`SMART_AFE_CAPTURE_INDEX',`',`fatal_error(note: Need to define AFE caputre index for sof-smart-amplifier
)')
ifdef(`SMART_AFE_PLAYBACK_NAME',`',`fatal_error(note: Need to define AFE BE dai_link name for sof-smart-amplifier
)')
ifdef(`SMART_AFE_CAPTURE_NAME',`',`fatal_error(note: Need to define AFE BE dai_link name for sof-smart-amplifier
)')


# Playback related
# define(`SMART_PB_PPL_ID', 1)
ifdef(`SMART_PB_PPL_ID',`',`fatal_error(note: Need to define playback pipeline ID for sof-smart-amplifier
)')
# define(`SMART_PB_CH_NUM', 2)
ifdef(`SMART_PB_CH_NUM',`',`fatal_error(note: Need to define playback channel number for sof-smart-amplifier
)')
define(`SMART_PIPE_SOURCE', concat(`PIPELINE_SOURCE_', SMART_PB_PPL_ID))
# define(`SMART_TX_CHANNELS', 4)
ifdef(`SMART_TX_CHANNELS',`',`fatal_error(note: Need to define DAI TX channel number for sof-smart-amplifier
)')
# define(`SMART_RX_CHANNELS', 8)
ifdef(`SMART_RX_CHANNELS',`',`fatal_error(note: Need to define DAI RX channel number for sof-smart-amplifier
)')
# define(`SMART_FB_CHANNELS', 4)
ifdef(`SMART_FB_CHANNELS',`',`fatal_error(note: Need to define feedback channel number for sof-smart-amplifier
)')
define(`SMART_PB_PPL_NAME', concat(`PIPELINE_PCM_', SMART_PB_PPL_ID))
# Ref capture related
# define(`SMART_REF_PPL_ID', 11)
ifdef(`SMART_REF_PPL_ID',`',`fatal_error(note: Need to define Echo Ref pipeline ID for sof-smart-amplifier
)')
# define(`SMART_REF_CH_NUM', 4)
ifdef(`SMART_REF_CH_NUM',`',`fatal_error(note: Need to define Echo Ref channel number for sof-smart-amplifier
)')
define(`SMART_PIPE_SINK', concat(`PIPELINE_SINK_', SMART_REF_PPL_ID))
# define(`N_SMART_DEMUX', `MUXDEMUX'SMART_REF_PPL_ID`.'$1)
define(`SMART_REF_PPL_NAME', concat(`PIPELINE_PCM_', SMART_REF_PPL_ID))
# PCM related
# define(`SMART_PCM_ID', 0)
ifdef(`SMART_PCM_ID',`',`fatal_error(note: Need to define PCM ID for sof-smart-amplifier
)')
ifdef(`SMART_PCM_NAME',`',`fatal_error(note: Need to define Speaker PCM name for sof-smart-amplifier
)')
ifdef(`SMART_PCM_REF_ID',`',`fatal_error(note: Need to define PCM ID for the Spaeker reference data of sof-smart-amplifier
)')
ifdef(`SMART_PCM_REF_NAME',`',`fatal_error(note: Need to define Speaker reference PCM name for sof-smart-amplifier
)')

#The long process time (aprox. 8ms) and process length (16ms in 16k sample rate) of igo_nr starve
#the scheduler and results in SMART_AMP underflow, ending up with smart_amp component reset and close.
#So increase the buffer size of SMART_AMP is necessary.
ifdef(`IGO', `define(`SMART_AMP_PERIOD', 16000)', `define(`SMART_AMP_PERIOD', 1000)')

#
# Define the pipelines
#
# PCM2 ----> smart_amp ----> AFE(AFE_PLAYBACK_INDEX)
#             ^
#             |
#             |
# PCM3 <---- demux <----- AFE(AFE_CAPTURE_INDEX)
#

dnl PIPELINE_PCM_ADD(pipeline,
dnl     pipe id, pcm, max channels, format,
dnl     period, priority, core,
dnl     pcm_min_rate, pcm_max_rate, pipeline_rate,
dnl     time_domain, sched_comp)

# Demux pipeline 1 on PCM 0 using max 2 channels of s32le.
# Set 1000us deadline with priority 0 on core 0
PIPELINE_PCM_ADD(sof/pipe-smart-amplifier-playback.m4,
	SMART_PB_PPL_ID, SMART_PCM_ID, SMART_PB_CH_NUM, s16le,
	SMART_AMP_PERIOD, 0, SMART_AMP_CORE,
	48000, 48000, 48000)
# Low Latency capture pipeline 2 on PCM 0 using max 2 channels of s32le.
# Set 1000us deadline with priority 0 on core 0

PIPELINE_PCM_ADD(sof/pipe-amp-ref-capture.m4,
        SMART_REF_PPL_ID, SMART_PCM_REF_ID, SMART_REF_CH_NUM, s16le,
        SMART_AMP_PERIOD, 0, 0,
        48000, 48000, 48000)

#
# DAIs configuration
#

dnl DAI_ADD(pipeline,
dnl     pipe id, dai type, dai_index, dai_be,
dnl     buffer, periods, format,
dnl     deadline, priority, core, time_domain)


# playback DAI is AFE(AFE_PLAYBACK_INDEX) using 2 periods
# Buffers use s32le format, 1000us deadline with priority 0 on core 0
DAI_ADD(sof/pipe-dai-playback.m4,
        SMART_PB_PPL_ID, AFE, SMART_AFE_PLAYBACK_INDEX, SMART_AFE_PLAYBACK_NAME,
        SMART_PIPE_SOURCE, 2, s16le,
        SMART_AMP_PERIOD, 0, 0, SCHEDULE_TIME_DOMAIN_TIMER)

# capture DAI is AFE(AFE_CAPTURE_INDEX) using 2 periods
# Buffers use s32le format, 1000us deadline with priority 0 on core 0
DAI_ADD(sof/pipe-dai-capture.m4,
        SMART_REF_PPL_ID, AFE, SMART_AFE_CAPTURE_INDEX, SMART_AFE_CAPTURE_NAME,
        SMART_PIPE_SINK, 2, s16le,
        SMART_AMP_PERIOD, 0, 0, SCHEDULE_TIME_DOMAIN_TIMER)

# Connect demux to smart_amp
ifdef(`N_SMART_REF_BUF',`',`fatal_error(note: Need to define ref buffer name for connection
)')
ifdef(`N_SMART_DEMUX',`',`fatal_error(note: Need to define demux widget name for connection
)')
SectionGraph."PIPE_SMART_AMP" {
	index "0"

	lines [
		# demux to smart_amp
		dapm(N_SMART_REF_BUF, N_SMART_DEMUX)
	]
}

# PCM for SMART_AMP Playback and EchoRef.

PCM_PLAYBACK_ADD(SMART_PCM_NAME, SMART_PCM_ID, SMART_PB_PPL_NAME)
PCM_CAPTURE_ADD(SMART_PCM_REF_NAME, SMART_PCM_REF_ID, SMART_REF_PPL_NAME)

#
# BE configurations - overrides config in ACPI if present
#

DAI_CONFIG(AFE, SMART_AFE_PLAYBACK_INDEX, 0, SMART_AFE_PLAYBACK_NAME,
	AFE_CONFIG(AFE_CONFIG_DATA(AFE, SMART_AFE_PLAYBACK_INDEX, 48000, SMART_TX_CHANNELS, s16le)))

DAI_CONFIG(AFE, SMART_AFE_CAPTURE_INDEX, 0, SMART_AFE_CAPTURE_NAME,
	AFE_CONFIG(AFE_CONFIG_DATA(AFE, SMART_AFE_CAPTURE_INDEX, 48000, SMART_RX_CHANNELS, s16le)))

DEBUG_END
