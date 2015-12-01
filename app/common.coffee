@Bridges = new Meteor.Collection "Bridges"
@Modes = new Meteor.Collection "Modes"

modeSchema = 
	name: 
		type: String
		label: "Name"
	state:
		type: Boolean
		label: "On"
	mode:
		type: String
		label: "Mode"
		allowedValues: ["grabber", "test"]


buildModeOption = (mode, options) ->
	
	for key, value of options
		modeSchema["options.#{mode}.#{key}"] = value
		modeSchema["options.#{mode}.#{key}"].autoform ?= {}
		modeSchema["options.#{mode}.#{key}"].autoform.class =  "mode-#{mode}"

buildModeOption "grabber", 
	width: type: Number
	height: type: Number
	fps: type: String
	lights: type: [Object]
	minSat: 
		type: Number
		min: 0
		max: 254
	"lights.$.id": 
		type: String
		autoform: 
			options: -> Lights.find().map (light) -> {value: light._id, label: light.name}
	"lights.$.hueGroup": type: Number
	hueGroupAngle: 
		type: Number
		min: 0
		max: 360

	
buildModeOption "test", 
	test: type: String


@Modes.attachSchema new SimpleSchema modeSchema

@Lights = new Meteor.Collection "Lights"
@Lights.attachSchema new SimpleSchema
	"state.sat": 
		type: Number
		optional: yes
		min: 0
		max: 254
	
	"state.bri": 
		type: Number
		optional: yes
		min: 0
		max: 254
	"state.ct": 
		type: Number
		optional: yes
		min: 153
		max: 500
	"state.effect": 
		type: String
		allowedValues: ["none", "colorloop"]
		optional: yes
	"state.hue": 
		type: Number
		optional: yes
		min: 0
		max: 65535
	"state.on": 
		type: Boolean
		optional: yes
	"state.alert": 
		type: String
		optional: yes
		allowedValues:["none", "select", "lselect"]




