
Router.route "setup",
	waitOn: ->
		[Meteor.subscribe("bridges"), Meteor.subscribe("modes"), Meteor.subscribe("lights")]
	data: ->
		bridges: -> Bridges.find()
		lights: -> Lights.find()
		modes: -> Modes.find()

Template.setup_oneBridge.events
	'click .btn-connect': (event, template) ->
		console.log template
		Meteor.call "connectBridge", template.data._id