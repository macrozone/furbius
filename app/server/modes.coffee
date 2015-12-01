Meteor.startup ->
	Modes.find({}, fields: {mode: yes, state:yes}).observe 
		changed: ({_id, state, mode}) ->
			if state is on
				Modes.update {_id:{"$ne": _id}, mode: mode}, $set: state: off


	
Meteor.publish "modes", -> Modes.find()