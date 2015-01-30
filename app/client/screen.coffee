Router.route "screen", 
	waitOn: -> Meteor.subscribe "lights"
