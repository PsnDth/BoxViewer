// Animation stats for Hitbox Debug Buttons
{
	// states and sprite info
	spriteContent: self.getResource().getContent("boxviewerButton"),
	stateTransitionMapOverrides: [
		PState.ACTIVE => {
			animation: "on"
		},
		PState.DESTROYING => {
			animation: "off"
		}
	],
	// no physics or aerial info necessary
	solid: false,
	immovable: true,
	ghost: false,
	shadows: false,
	// floor ecb
	floorHeadPosition: 15,
	floorHipWidth: 86.5,
	floorHipXOffset: -1.5,
	floorHipYOffset: 7.5,
	floorFootPosition: 0,
	metadata: {
		lastToggledBy: null
	},
}
