

updateBridges = ->
	console.log "update bridges"
	{data:bridges} = HTTP.get "http://www.meethue.com/api/nupnp"
	for bridge in bridges
		_id = bridge.id
		delete bridge.id
		Bridges.upsert _id, $set: bridge

_isUpdatingLightsFromBridge = no
updateLights = (bridgeId)->
	_isUpdatingLightsFromBridge = yes
	for idOnBridge, light of HueApi.getLights bridgeId
		light.bridgeId = bridgeId
		light.idOnBridge = idOnBridge
		Lights.upsert light.uniqueid, $set: light
	_isUpdatingLightsFromBridge = no

Meteor.publish "config", ->
	Config.find()

Meteor.publish "bridges", ->
	updateBridges()
	Bridges.find()

_isSettingLightState = no
Meteor.startup ->
	# normally observeChanges would be sufficient, but the autoform to update the lights
	# will trigger the full document
	Lights.find().observe 
		changed: (doc, oldDoc) ->
			lightId = doc._id
			changes = _.diff doc, oldDoc

			unless _isUpdatingLightsFromBridge or _isSettingLightState
				_isSettingLightState = yes
				HueApi.setLightState lightId, changes.state
				_isSettingLightState = no




getAllConnectedBridges = -> Bridges.find(username: $exists: yes).fetch()

Meteor.methods "updateLights": updateLights

Meteor.publish "lights", ->
	for bridge in getAllConnectedBridges()
		updateLights bridge._id
	Lights.find()


_hueCall = (bridgeId, method, path = "", options = {}) ->
	{internalipaddress} = Bridges.findOne bridgeId
	HTTP[method] "http://#{internalipaddress}/api/#{path}", options
@HueApi = 

	setLightState: (lightID, state) ->
		light = Lights.findOne lightID
		bridge = Bridges.findOne light.bridgeId
		console.log "setting #{light.name}", state
		
		_hueCall light.bridgeId, "put", "#{bridge.username}/lights/#{light.idOnBridge}/state", data: state, 
		
	getLights: (bridgeId) ->
		bridge = Bridges.findOne bridgeId
		{data} = _hueCall bridgeId, "get", "#{bridge.username}/lights"
		data
	hasUser: (bridgeId) ->
		
		{data:[error:error]} = _hueCall bridgeId, "get", "#{HueUser}"
		if error? and error.type is 1
			return no
		else 
			return yes
	createUser: (bridgeId) ->
		call = -> _hueCall bridgeId, "post", "", data: devicetype: "furbius"

		tryCall = ->
			{data} = call()
			[error:error] = data
			if error?.type is 101
				console.log "link button not pressed"
				Meteor.setTimeout tryCall, 1000
			else
				[success:username:username] = data
				return username
		return tryCall()


Meteor.methods
	"connectBridge": (bridgeId) ->
		bridge = Bridges.findOne bridgeId
		Config.upsert "selectedBridge", $set: {bridgeId}
		# check if bridge has user
		if bridge.username?
			console.log "has already a user"
		else
			username = HueApi.createUser bridgeId
			Bridges.update bridgeId, $set: {username}
	