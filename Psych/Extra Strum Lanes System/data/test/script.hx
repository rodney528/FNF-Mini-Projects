function onStrumLaneCreation(laneTag:String) {
	if (laneTag == 'gf') {
		for (i in 0...4) {
			var strumLane = getVar(laneTag + 'Strums');
			strumLane.members[i].y = playerStrums.members[i].y - 50 * (ClientPrefs.data.downScroll ? 1 : -1);
			strumLane.members[i].alpha = 0.7;
			strumLane.members[i].x += (FlxG.width / 7.5) * (strumLane.members[i].noteData > 1 ? 1 : -1);
		}
	}
}