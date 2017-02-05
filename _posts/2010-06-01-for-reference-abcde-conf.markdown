--- 
layout: post
mt_id: 79
title: "For Reference: abcde.conf"
---
For reference (and only if for my very own reference), an abcde.conf for flac + space-based filenames:

	PADTRACKS=y
	ACTIONS=default,replaygain
	OUTPUTTYPE=flac
	OUTPUTFORMAT='${ARTISTFILE}/${ALBUMFILE}/${TRACKNUM} - ${ARTISTFILE} - ${TRACKFILE}'
	VAOUTPUTFORMAT='VA/${ALBUMFILE}/${TRACKNUM} - ${ARTISTFILE} - ${TRACKFILE}'
	ONETRACKOUTPUTFORMAT=$OUTPUTFORMAT
	VAONETRACKOUTPUTFORMAT=$VAOUTPUTFORMAT
	MAXPROCS=8
	mungefilename ()
	{
		echo "$@" | sed s,:,\ -,g | tr /\* _+ | tr -d \'\"\?\[:cntrl:\]
	}
	pre_read ()
	{
	  eject -t
	}
	EJECTCD=y

This post is motivated by a once again lost abcde.conf file. 
