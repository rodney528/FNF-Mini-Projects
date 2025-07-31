function onCreatePost()
	makeCharacter('mom', 'pico-player', {defaultBoyfriendX + 350, defaultBoyfriendY}, true, {{'No Animation', true}, {'Hurt Note', false}})
	addCharacter('mom', true)
	removeCharacter('mom', false)
	setCharNoteTypes('mom', {'Extra Sing', nil}, 'add')
	shouldNotePlayAnim('Extra Sing', false, true)
end