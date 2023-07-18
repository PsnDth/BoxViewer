var BASE_FIREBALL_STATS = {
	hitbox0: {
		damage: 5,
		knockbackGrowth: 20,
		baseKnockback: 5,
		angle: 35,
		reversibleAngle: false
	},
};
{
	fireball: BASE_FIREBALL_STATS,
	fireball_base: BASE_FIREBALL_STATS,
	fireball_absorbable: {
		hitbox0: {
			damage: 5,
			knockbackGrowth: 40,
			baseKnockback: 65,
			angle: 65,
			reversibleAngle: false,
			directionalInfluence: false,
			stackKnockback: false,
			absorbable: true
		},
	},
	fireball_reflectable: {
		hitbox0: {
			damage: 5,
			knockbackGrowth: 1,
			baseKnockback: 1,
			angle: 180,
			reversibleAngle: false,
			directionalInfluence: false,
			tumbleType: TumbleType.ALWAYS,
			stackKnockback: false,
			reflectable: true
		},
	},
	fireball_hit: {},
}
