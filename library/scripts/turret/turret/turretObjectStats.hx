{
	// states and sprite info
	spriteContent: self.getResource().getContent("boxviewerTurret"),
	stateTransitionMapOverrides: [
		PState.ACTIVE => {
			animation: "turret_idle"
		},
		PState.DESTROYING => {
			animation: "turret_idle"
		}
	],
	// physics
	gravity: 0,
	shadows: false,
	metadata: {
		lastToggledBy: null,
	},
}
