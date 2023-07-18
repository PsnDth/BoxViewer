// Animation stats for Assist Template Projectile
{
	// states and sprite info
	spriteContent: self.getResource().getContent("boxviewerDummy"),
	stateTransitionMapOverrides: [
		PState.ACTIVE => {
			animation: "idle"
		},
		PState.DESTROYING => {
			animation: "death"
		}
	],
	// physics
	gravity: 0,
	weight: 85,
	friction: 0.2,
	groundSpeedCap: 11,
	aerialSpeedCap: 11,
	aerialFriction: 0,
	terminalVelocity: 11,
	ghost: true,
	// floor ecb
	floorHeadPosition: 40,
	floorHipWidth: 25,
	floorHipXOffset: 0,
	floorHipYOffset: 0,
	floorFootPosition: 0,
	// aerial ecb
	aerialHeadPosition: 40,
	aerialHipWidth: 25,
	aerialHipXOffset: 0,
	aerialHipYOffset: 0,
	aerialFootPosition: 0,
}
