Router.route "lights", 
	waitOn: -> 
		Meteor.subscribe "lights"

	data:
		lights: -> Lights.find()

