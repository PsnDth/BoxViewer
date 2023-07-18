var FireballTypes = {
	NONE: -1,
	BASE: 0,
	ABSORBABLE: 1,
	REFLECTABLE: 2,
	UNKNOWN_1: 3,
	UNKNOWN_2: 4
};

var FIREBALL_ANIM = [
	FireballTypes.NONE => "fireball",
	FireballTypes.BASE => "fireball_base",
	FireballTypes.ABSORBABLE => "fireball_absorbable",
	FireballTypes.REFLECTABLE => "fireball_reflectable",
	FireballTypes.UNKNOWN_1 => "fireball",
	FireballTypes.UNKNOWN_2 => "fireball"
];

function initialize() {
	self.setXSpeed(8);
	stage.getCharactersBackContainer().addChild(self.getViewRootContainer());
	Common.enableReflectionListener({mode: "X", replaceOwner: true});
	self.addEventListener(EntityEvent.COLLIDE_STRUCTURE, onStructureHit, {persistent: true});
}

function onStructureHit() {
	self.toState(PState.DESTROYING);
	self.removeEventListener(EntityEvent.COLLIDE_STRUCTURE, onStructureHit);
}

function update() {
	if (self.getAnimation() == "fireball") {
		// switch to anim w/ correct hitbox stats
		// not using update hitbox stats since doesn't work for reflectable/absorbable ...
		self.playAnimation(FIREBALL_ANIM[self.getCostumeIndex()]);
	}
}
