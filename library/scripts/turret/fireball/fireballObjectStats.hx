{
	// states and sprite info
	spriteContent: self.getResource().getContent("boxviewerTurret"),
	stateTransitionMapOverrides: [
		PState.ACTIVE => {
			animation: "fireball"
		},
		PState.DESTROYING => {
			animation: "fireball_hit"
		}
	],
	// physics
	gravity: 0,
	// aerial ecb
	aerialHeadPosition: 15,
	aerialHipWidth: 52,
	aerialHipXOffset: 1,
	aerialHipYOffset: 0,
	aerialFootPosition: 0,
}
