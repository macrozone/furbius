spawn = Meteor.npmRequire("child_process").spawn
getPixels = Meteor.npmRequire "get-pixels"
rgb2hsl = Meteor.npmRequire("color-convert").rgb2hsl


colorSpline = new MonotonicCubicSpline([0,57, 240,360], [0,16002, 47111, 65535])
satSpline = new MonotonicCubicSpline([0,22, 44,255], [0,200, 254, 255])

convertColor = (hue) ->
	Math.round colorSpline.interpolate hue
convertSat = (sat) ->
	Math.round satSpline.interpolate sat
avg = (a) ->
	sum = _.reduce a, (x,y) -> x+y
	sum / a.length

grabbers = {}

Meteor.startup ->
	Modes.find mode: "grabber"
	.observe 
		changed: (mode) ->
			unless grabbers[mode._id]?
				grabbers[mode._id] = new Grabber mode
			else
				grabbers[mode._id].update mode
			Meteor.defer ->
				grabbers[mode._id].init()
			


Grabber = class
	constructor: (@mode) ->

	update: (@mode) ->

	init: ->
		@stop()
		if @mode.state is on
			@start()


	stop: ->
		@ffmpeg?.kill()
	start: ->
		@stop()

		{width, height, fps, hueGroupAngle, lights, minSat} = @mode.options.grabber 
		
		rowOffset = width % 4
	
		@ffmpeg = spawn "ffmpeg","-f avfoundation -i 1 -filter:v scale=#{width}:#{height},fps=#{fps} -c:v bmp -f image2pipe -".split " "
		@ffmpeg.stdout.on "data", Meteor.bindEnvironment (buffer) ->
			grabberConfig = Modes.findOne "grabber"
			hues = {}
			pointer = 0
			pixelData = buffer.slice(54)
			lightningSum = 0
			for y in [1..height]
				for x in [1..width]
					b = pixelData.readUInt8 pointer
					pointer++
					g = pixelData.readUInt8 pointer
					pointer++
					r = pixelData.readUInt8 pointer
					pointer++
					[hue,lightning,sat] =  rgb2hsl r,g,b
					lightningSum+= lightning
					# round
					hueGroup = hueGroupAngle*(hue//hueGroupAngle)
					if sat > minSat
						unless hues[hueGroup]?
							hues[hueGroup] =
								count: 0
								hues: []
								hueGroup: hueGroup
								sats: []

						hues[hueGroup].count++
						hues[hueGroup].hues.push hue
						hues[hueGroup].sats.push sat
				pointer+= rowOffset
			avgLightning = Math.round lightningSum / (height*width)
			
			hueGroups = []
			for hueGroup, group of hues
				hueGroups.push group
			hueGroups = _(hueGroups).sortBy (group) -> -group.count
			
			for {id, hueGroup} in lights
			
				group = hueGroups[Math.min(hueGroups.length-1, hueGroup-1)]
				
				if group and avgLightning > 0
					state = 
						on: on
						hue: convertColor avg group.hues
						bri: avgLightning
						sat: convertSat avg group.sats

					HueApi.setLightState id, state
						
				else
					HueApi.setLightState id, on: off


		


