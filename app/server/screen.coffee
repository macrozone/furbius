spawn = Meteor.npmRequire("child_process").spawn
getPixels = Meteor.npmRequire "get-pixels"
rgb2hsl = Meteor.npmRequire("color-convert").rgb2hsl
ffmpeg = null

spline = new MonotonicCubicSpline([0,240,360], [0,47111, 65535])
convertColor = (hue) ->
	Math.round spline.interpolate hue

convertColorGroup = (group) ->
	# get avg color
	sum = _(group.hues).reduce (x,y) -> x+y
	convertColor sum/group.hues.length

@grabber = 
	start: ->
		@stop()
		ffmpeg = spawn "ffmpeg","-f avfoundation -i 0 -filter:v scale=2:1,fps=8 -c:v png -f image2pipe -".split " "
		ffmpeg.stdout.on "data", (data) ->
			getPixels data, "image/png", (error, pixels) ->
				unless error?
					#console.log "got pixels", pixels
					console.log "rgba(#{pixels.data[0]}, #{pixels.data[1]}, #{pixels.data[2]}, 1)"
				else
					console.error error

	test: ->
		@stop()
		width = 10
		rowOffset = width % 4
		height = 10
		sameHueTolerance = 20
		fps = 2
		ffmpeg = spawn "ffmpeg","-f avfoundation -i 0 -filter:v scale=#{width}:#{height},fps=#{fps} -c:v bmp -f image2pipe -".split " "
		ffmpeg.stdout.on "data", Meteor.bindEnvironment (buffer) ->
			hues = {}
			pointer = 0
			pixelData = buffer.slice(54)
			for y in [1..height]
				for x in [1..width]
					b = pixelData.readUInt8 pointer
					pointer++
					g = pixelData.readUInt8 pointer
					pointer++
					r = pixelData.readUInt8 pointer
					pointer++
					[hue,l,s] =  rgb2hsl r,g,b
					# round
					hueGroup = sameHueTolerance*(hue//sameHueTolerance)
					unless hues[hueGroup]?
						hues[hueGroup] =
							count: 0
							hues: []
							hueGroup: hueGroup

					hues[hueGroup].count++
					hues[hueGroup].hues.push hue
				pointer+= rowOffset
			hueArray = []
			for hueGroup, group of hues
				hueArray.push group
			hueArray = _(hueArray).sortBy (group) -> -group.count
			topColorGroup = hueArray[0]
			secondColorGroup = hueArray[1] ? topColorGroup
			#console.log topColorGroup, convertColorGroup topColorGroup
			#console.log secondColorGroup, convertColorGroup secondColorGroup
			#console.log hueArray

			Lights.update "00:17:88:01:00:c3:c5:84-0b", $set: state: hue: convertColorGroup topColorGroup
			Lights.update "00:17:88:01:00:bc:e5:95-0b", $set: state: hue: convertColorGroup secondColorGroup





	stop: ->
		ffmpeg.kill() if ffmpeg?


