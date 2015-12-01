Router.route "screen", 
	waitOn: -> 
		(Meteor.subscribe s for s in ["lights", "modes"])

	data:
		modes: -> Modes.find()



showMode = (template, mode) ->
	template.$("[class^='mode']:not(.mode-#{mode})").closest(".panel").hide()
	template.$(".mode-#{mode}").closest(".panel").show()

for template in [Template.modes_newMode, Template.modes_oneMode]
	template.rendered = -> showMode @, @data.mode
	template.events
		'change [name="mode"]': (event, template) ->
			mode = $(event.currentTarget).val()
			showMode template, mode