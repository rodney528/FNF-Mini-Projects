var char;
function onCreatePost() {
	char = importCharacter('pico', new Character(game.boyfriendGroup.x - 350, game.boyfriendGroup.y, 'pico-player', true), [['', true]]);
	game.addBehindBF(char.self);
	char.self.x += char.self.positionArray[0];
	char.self.y += char.self.positionArray[1];
	shouldNotePlayAnim('', false, true);
}