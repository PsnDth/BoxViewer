var front_sprite:Vfx = null;

var FireballTypes = {
	NONE: -1,
	BASE: 0,
	ABSORBABLE: 1,
	REFLECTABLE: 2,
	UNKNOWN_1: 3,
	UNKNOWN_2: 4
};

var FIREBALL_MODES = [
	FireballTypes.BASE, 
	FireballTypes.ABSORBABLE,
	FireballTypes.REFLECTABLE,
];
var curr_fireball_mode = FireballTypes.NONE;
var fireballs = [];

function initialize() {
	stage.getCharactersBackContainer().addChild(self.getViewRootContainer());
	front_sprite = match.createVfx(new VfxStats({
		spriteContent: self.getResource().getContent("boxviewerTurret"),
		animation: "turret_front",
		loop: true,
	}), self);
	front_sprite.addShader(self.getCostumeShader());
	stage.getCharactersBackContainer().addChild(front_sprite.getViewRootContainer());
	self.exports = {
		toggleMode: toggleMode,
	};
	self.addEventListener(GameObjectEvent.COUNTER, onPressed, {persistent: true});
}

function update() {
	enforceFrontSprite();
	fireballCleanup();
}

function onPressed(e:GameObjectEvent) {
	if (self.curr_fireball_mode == FireballTypes.NONE)
		return;
	if (fireballs.contains(e.data.foe))
		return;
	var char = e.data.foe.getRootOwner();
	if (char == null)
		return;
	// Ignore hitboxes that wouldn't flinch anyways
	var hitbox = e.data.hitboxStats;
	if (self.getGameObjectStatsMetadata().lastToggledBy == hitbox.attackId)
		return;
	if (!hitbox.flinch)
		return;
	self.updateGameObjectStatsMetadata({lastToggledBy: hitbox.attackId});
	AudioClip.play(GlobalSfx.STRONG_CLICK);
	var curr_mode_idx = FIREBALL_MODES.indexOf(curr_fireball_mode);
	var next_mode_idx = (curr_mode_idx + 1) % FIREBALL_MODES.length;
	setMode(FIREBALL_MODES[next_mode_idx]);
}

function setMode(mode) {
	front_sprite.removeShader(self.getCostumeShader());
	curr_fireball_mode = mode;
	self.setCostumeIndex(Math.max(0, curr_fireball_mode));
	front_sprite.addShader(self.getCostumeShader());
}

function toggleMode() {
	var is_idle = curr_fireball_mode == FireballTypes.NONE;
	self.playAnimation(is_idle ? "turret_shot" : "turret_idle");
	setMode(is_idle ? FireballTypes.BASE : FireballTypes.NONE);
}

function fireProjectile() {
	// TODO: Charging sound fx?
	AudioClip.play(self.getResource().getContent("fireball_shot"));
	var fb = match.createProjectile(self.getResource().getContent("boxviewerFireball"), self);
	front_sprite.bringInFront(fb);
	fb.setX(self.getX() + self.flipX(9));
	fb.setY(self.getY());
	if (stage.exports != null && stage.exports.exception_list != null) {
		stage.exports.exception_list.push(fb);
	}
	fireballs.push(fb);
	fb.setCostumeIndex(self.getCostumeIndex());
}

function fireballCleanup() {
	for (fb in fireballs) {
		if (fb.isDisposed()) {
			stage.exports.exception_list.remove(fb);
			fireballs.remove(fb);
		}
	}
}

function enforceFrontSprite() {
	if (front_sprite.getX() != self.getX()) {
		front_sprite.setX(self.getX());
	}
	if (front_sprite.getY() != self.getY()) {
		front_sprite.setY(self.getY());
	}
	if (front_sprite.getVisible() != self.getVisible()) {
		front_sprite.setVisible(self.getVisible());
	}
}
