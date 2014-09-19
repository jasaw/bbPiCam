application=
{
	description="FLV Playback Sample",
	name="flvplayback",
	protocol="dynamiclinklibrary",
	mediaFolder="/var/lib/crtmpserver/mediaFolder",
	aliases=
	{
		"simpleLive",
		"vod",
		"live",
		"WeeklyQuest",
		"SOSample",
		"oflaDemo",
	},
	acceptors =
	{
		{
			ip="0.0.0.0",
			port=6666,
			protocol="inboundLiveFlv",
			waitForMetadata=true,
		},
		{
			ip="0.0.0.0",
			port=9999,
			protocol="inboundTcpTs"
		},
		{
			ip="0.0.0.0",
			port=554,
			protocol="inboundRtsp"
		},
		--[[{
			ip="0.0.0.0",
			port=7654,
			protocol="inboundRawHttpStream",
			crossDomainFile="/tmp/crossdomain.xml"
		},]]--
	},
	externalStreams =
	{
		--[[
		{
			uri="rtsp://fms20.mediadirect.ro/live2/realitatea/realitatea",
			localStreamName="rtsp_test",
			forceTcp=true
		},
		{
			uri="rtmp://edge01.fms.dutchview.nl/botr/bunny",
			localStreamName="rtmp_test",
			swfUrl="http://www.example.com/example.swf";
			pageUrl="http://www.example.com/";
			emulateUserAgent="MAC 10,1,82,76",
		}]]--
	},
	validateHandshake=false,
	keyframeSeek=false,
	seekGranularity=0.1, --in seconds, between 0.1 and 600
	clientSideBuffer=30, --in seconds, between 5 and 30
	--generateMetaFiles=true, --this will generate seek/meta files on application startup
	--renameBadFiles=false,
	--enableCheckBandwidth=true,
	--[[authentication=
	{
		rtmp={
			type="adobe",
			encoderAgents=
			{
				"FMLE/3.0 (compatible; FMSc/1.0)",
				"My user agent",
			},
			usersFile="/etc/crtmpserver/conf.d/users.lua"
		},
		rtsp={
			usersFile="/etc/crtmpserver/conf.d/users.lua"
		}
	}, --]]
}

