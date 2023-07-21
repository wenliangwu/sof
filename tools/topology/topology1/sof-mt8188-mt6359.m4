#
# Topology for MT8188 board with mt6359
#

# Include topology builder
include(`utils.m4')
include(`dai.m4')
include(`pipeline.m4')
include(`afe.m4')
include(`pcm.m4')
include(`buffer.m4')

# Include TLV library
include(`common/tlv.m4')

# Include Token library
include(`sof/tokens.m4')

# Include DSP configuration
include(`platform/mediatek/mt8188.m4')

#
# Define the pipelines
#
# PCM16 ---> AFE (Speaker - rt1019)
# PCM17 ---> AFE (Headset playback - rt5682)
# PCM18 <--- AFE (DMIC - MT6365)
# PCM19 <--- AFE (Headset record - rt5682)

ifdef(`SMART_AMP',`
# Smart amplifier related
define(`SMART_AFE_PLAYBACK_INDEX', 0)
define(`SMART_AFE_CAPTURE_INDEX', 4)
define(`SMART_AFE_PLAYBACK_NAME', `AFE_SOF_DL2')
define(`SMART_AFE_CAPTURE_NAME', `AFE_SOF_UL10')

# Playback related
define(`SMART_PB_PPL_ID', 1)
define(`SMART_PB_CH_NUM', 2)
define(`SMART_TX_CHANNELS', 2)
define(`SMART_RX_CHANNELS', 2)
define(`SMART_FB_CHANNELS', 2)
# Ref capture related
define(`SMART_REF_PPL_ID', 5)
define(`SMART_REF_CH_NUM', 2)
# PCM related
define(`SMART_PCM_ID', 16)
define(`SMART_PCM_NAME', `SOF_DL2')
define(`SMART_PCM_REF_ID', 20)
define(`SMART_PCM_REF_NAME', `SOF_UL10')

include(`sof-smart-amplifier-mtk.m4')
',`')

dnl PIPELINE_PCM_ADD(pipeline,
dnl     pipe id, pcm, max channels, format,
dnl     period, priority, core,
dnl     pcm_min_rate, pcm_max_rate, pipeline_rate,
dnl     time_domain, sched_comp)

# Low Latency playback pipeline 1 on PCM 16 using max 2 channels of s16le
# Set 1000us deadline with priority 0 on core 0
ifdef(`SMART_AMP',,
`PIPELINE_PCM_ADD(sof/pipe-passthrough-playback.m4,
	1, 16, 2, s16le,
	1000, 0, 0,
	48000, 48000, 48000)')

# Low Latency playback pipeline 2 on PCM 17 using max 2 channels of s16le
# Set 1000us deadline with priority 0 on core 0
PIPELINE_PCM_ADD(sof/pipe-passthrough-playback.m4,
	2, 17, 2, s16le,
	1000, 0, 0,
	48000, 48000, 48000)

# Low Latency capture pipeline 3 on PCM 18 using max 2 channels of s16le
# Set 2000us deadline with priority 0 on core 0
PIPELINE_PCM_ADD(sof/pipe-passthrough-capture.m4,
	3, 18, 2, s16le,
	2000, 0, 0,
	48000, 48000, 48000)

# Low Latency capture pipeline 4 on PCM 19 using max 2 channels of s16le
# Set 2000us deadline with priority 0 on core 0
PIPELINE_PCM_ADD(sof/pipe-passthrough-capture.m4,
	4, 19, 2, s16le,
	2000, 0, 0,
	48000, 48000, 48000)

# Low Latency capture pipeline 5 on PCM 20 using max 2 channels of s16le
# Set 2000us deadline with priority 0 on core 0
ifdef(`SMART_AMP',,
`PIPELINE_PCM_ADD(sof/pipe-passthrough-capture.m4,
	5, 20, 2, s16le,
	2000, 0, 0,
	48000, 48000, 48000)')

#
# DAIs configuration
#

dnl DAI_ADD(pipeline,
dnl     pipe id, dai type, dai_index, dai_be,
dnl     buffer, periods, format,
dnl     deadline, priority, core)


# playback DAI is AFE using 2 periods
# Buffers use s16le format, with 48 frame per 1000us on core 0 with priority 0
ifdef(`SMART_AMP',,
`DAI_ADD(sof/pipe-dai-playback.m4,
	1, AFE, 0, AFE_SOF_DL2,
	PIPELINE_SOURCE_1, 2, s16le,
	1000, 0, 0, SCHEDULE_TIME_DOMAIN_TIMER)')

# playback DAI is AFE using 2 periods
# Buffers use s16le format, with 48 frame per 1000us on core 0 with priority 0
DAI_ADD(sof/pipe-dai-playback.m4,
	2, AFE, 1, AFE_SOF_DL3,
	PIPELINE_SOURCE_2, 2, s16le,
	1000, 0, 0, SCHEDULE_TIME_DOMAIN_TIMER)

# capture DAI is AFE using 2 periods
# Buffers use s16le format, with 48 frame per 2000us on core 0 with priority 0
DAI_ADD(sof/pipe-dai-capture.m4,
	3, AFE, 2, AFE_SOF_UL4,
	PIPELINE_SINK_3, 2, s16le,
	2000, 0, 0, SCHEDULE_TIME_DOMAIN_TIMER)

# capture DAI is AFE using 2 periods
# Buffers use s16le format, with 48 frame per 2000us on core 0 with priority 0
DAI_ADD(sof/pipe-dai-capture.m4,
	4, AFE, 3, AFE_SOF_UL5,
	PIPELINE_SINK_4, 2, s16le,
	2000, 0, 0, SCHEDULE_TIME_DOMAIN_TIMER)

ifdef(`SMART_AMP',,
`DAI_ADD(sof/pipe-dai-capture.m4,
	5, AFE, 4, AFE_SOF_UL10,
	PIPELINE_SINK_5, 2, s16le,
	2000, 0, 0, SCHEDULE_TIME_DOMAIN_TIMER)')

#SCHEDULE_TIME_DOMAIN_DMA
dnl PCM_PLAYBACK_ADD(name, pcm_id, playback)

# PCM Low Latency, id 0
ifdef(`SMART_AMP',,
`PCM_PLAYBACK_ADD(SOF_DL2, 16, PIPELINE_PCM_1)')
PCM_PLAYBACK_ADD(SOF_DL3, 17, PIPELINE_PCM_2)
PCM_CAPTURE_ADD(SOF_UL4, 18, PIPELINE_PCM_3)
PCM_CAPTURE_ADD(SOF_UL5, 19, PIPELINE_PCM_4)
ifdef(`SMART_AMP',,
`PCM_CAPTURE_ADD(SOF_UL10, 20, PIPELINE_PCM_5)')

dnl DAI_CONFIG(type, dai_index, link_id, name, afe_config)

ifdef(`SMART_AMP',,
`DAI_CONFIG(AFE, 0, 0, AFE_SOF_DL2,
	AFE_CONFIG(AFE_CONFIG_DATA(AFE, 0, 48000, 2, s16le)))')

DAI_CONFIG(AFE, 1, 0, AFE_SOF_DL3,
	AFE_CONFIG(AFE_CONFIG_DATA(AFE, 1, 48000, 2, s16le)))

DAI_CONFIG(AFE, 2, 0, AFE_SOF_UL4,
	AFE_CONFIG(AFE_CONFIG_DATA(AFE, 2, 48000, 2, s16le)))

DAI_CONFIG(AFE, 3, 0, AFE_SOF_UL5,
	AFE_CONFIG(AFE_CONFIG_DATA(AFE, 3, 48000, 2, s16le)))

ifdef(`SMART_AMP',,
`DAI_CONFIG(AFE, 4, 0, AFE_SOF_UL10,
	AFE_CONFIG(AFE_CONFIG_DATA(AFE, 4, 48000, 2, s16le)))')
