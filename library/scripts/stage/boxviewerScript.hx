// API Script for Hitbox Debug Stage
var BOX_TYPES = [
	CollisionBoxType.HURT, // bottom layer
	CollisionBoxType.SHIELD,
	CollisionBoxType.LEDGEGRAB,
	CollisionBoxType.HIT,
	CollisionBoxType.GRAB,
	CollisionBoxType.ABSORB,
	CollisionBoxType.REFLECT,
	CollisionBoxType.COUNTER,
	CollisionBoxType.CUSTOMA,
	CollisionBoxType.CUSTOMB,
	CollisionBoxType.CUSTOMC, // top layer
];

// NOTE: The below look like classes, but are really just structs. Treat them like singletons/static classes.
//       Goal of doing it this way, is to make things a bit more portable.
// TODO: Should be more rollback safe probably

var Util = {
	getP1: () -> {
		var players = match.getCharacters().filter((c) -> !c.getPlayerConfig().cpu);
		return (players.length > 0 ? players[0] : null);
	},
	throwError: (msg) -> Engine.log("ERROR: " + msg, 0xFF0000),
	collisionBoxTypeToString: (cbtype) -> {
		switch (cbtype) {
			case CollisionBoxType.HURT: "HURT";
			case CollisionBoxType.SHIELD: "SHIELD";
			case CollisionBoxType.LEDGEGRAB: "LEDGEGRAB";
			case CollisionBoxType.HIT: "HIT";
			case CollisionBoxType.GRAB: "GRAB";
			case CollisionBoxType.ABSORB: "ABSORB";
			case CollisionBoxType.REFLECT: "REFLECT";
			case CollisionBoxType.COUNTER: "COUNTER";
			case CollisionBoxType.CUSTOMA: "CUSTOMA";
			case CollisionBoxType.CUSTOMB: "CUSTOMB";
			case CollisionBoxType.CUSTOMC: "CUSTOMC";
			case CollisionBoxType.NONE: "NONE";
			default: "N/A";
		}
	},
	getTrueCenter: function(cbox:CollisionBox) {
		if (cbox.rotation == 0)
			return new Point(cbox.centerX, cbox.centerY);
		var p = new Point(cbox.x, cbox.y);
		var tMatrix = new Matrix();
		// Undo rotation around pivot
		tMatrix.translate(-cbox.pivotX, -cbox.pivotY);
		tMatrix.rotate(Math.toRadians(-cbox.rotation));
		tMatrix.translate(cbox.pivotX, cbox.pivotY);
		// Translate point to center
		tMatrix.translate(cbox.centerX - cbox.x, cbox.centerY - cbox.y);
		// Redo rotation around pivot
		tMatrix.translate(-cbox.pivotX, -cbox.pivotY);
		tMatrix.rotate(Math.toRadians(cbox.rotation));
		tMatrix.translate(cbox.pivotX, cbox.pivotY);
		return Util.applyMatrix(tMatrix, p);
	},
	rotatePointAroundPivot: function(point:Point, pivot:Point, angle:Float) {
		var degrees = Math.forceBase360(angle);
		if (degrees == 0)
			return point;
		var tMatrix = new Matrix();
		tMatrix.translate(-pivot.x, -pivot.y);
		tMatrix.rotate(Math.toRadians(rotation));
		tMatrix.translate(pivot.x, pivot.y);
		return Util.applyMatrix(tMatrix, point);
	},
	transformPointAroundPivot: function(point:Point, pivot:Point, rotation:Float, scale:Point) {
		var degrees = Math.forceBase360(rotation);
		if (degrees == 0 && scale.x == 1 && scale.y == 1)
			return point;

		// TODO: Should probably use matrices for this too
		var translated_point = new Point(point.x - pivot.x, point.y - pivot.y);
		translated_point.scale(scale.x, scale.y);
		return new Point(Math.fastCos(degrees) * translated_point.x
			- Math.fastSin(degrees) * translated_point.y
			+ pivot.x,
			Math.fastSin(degrees) * translated_point.x
			+ Math.fastCos(degrees) * translated_point.y
			+ pivot.y);
		var tMatrix = new Matrix();
		tMatrix.translate(-pivot.x, -pivot.y);
		tMatrix.rotate(Math.toRadians(rotation));
		tMatrix.scale(scale.x, scale.y);
		tMatrix.translate(pivot.x, pivot.y);
		return Util.applyMatrix(tMatrix, point);
	},
	average: (num1, num2) -> (num1 + num2) / 2,
	printMatrix: (m) -> {
		Engine.log("[" + m.a + " " + m.b + " " + m.tx);
		Engine.log(" " + m.c + " " + m.d + " " + m.ty);
		Engine.log(" " + 0 + " " + 0 + " " + 1 + "]");
	},
	applyMatrix: function(matrix:Matrix, point:Point) {
		return new Point(matrix.a * point.x + matrix.b * point.y + matrix.tx, matrix.c * point.x + matrix.d * point.y + matrix.ty);
	},
	checkBits: (num, mask) -> (num & mask) != 0x0,
	positiveMod: (num, mod) -> (((num % mod) + mod) % mod),
	onButtonsHeld: function(char:Character, buttonMask:Int, cb:Function, ?persistent:Bool = false) {
		// NOTE: Unlike engine eventlistener style functions, persistent here means it doesn't get cleared after firing once.
		var poll_for_press; // reference to remove the timer
		// Use closure to make sure these varibles persist ...
		(() -> {
			// Should not fire if pressed this frame.
			// TODO: This should probably be an option
			var seen_buttons = Util.checkBits(char.getHeldControls().buttons, buttonMask);
			poll_for_press = () -> {
				if (Util.checkBits(char.getHeldControls().buttons, buttonMask)) {
					if (!seen_buttons) {
						seen_buttons = true;
						cb();
						if (!persistent)
							StageTimer.removeCallback(poll_for_press);
					}
				} else {
					seen_buttons = false;
				}
			};
			StageTimer.addCallback(poll_for_press);
		})();
		// return callback so it can be removed manually
		return poll_for_press;
	},
	disableAttacks: (char) -> [
		char.addStatusEffect(StatusEffectType.DISABLE_ACTION, CharacterActions.JAB).id,
		char.addStatusEffect(StatusEffectType.DISABLE_ACTION, CharacterActions.TILT_DOWN).id,
		char.addStatusEffect(StatusEffectType.DISABLE_ACTION, CharacterActions.TILT_FORWARD).id,
		char.addStatusEffect(StatusEffectType.DISABLE_ACTION, CharacterActions.TILT_UP).id,
		char.addStatusEffect(StatusEffectType.DISABLE_ACTION, CharacterActions.STRONG_DOWN).id,
		char.addStatusEffect(StatusEffectType.DISABLE_ACTION, CharacterActions.STRONG_FORWARD).id,
		char.addStatusEffect(StatusEffectType.DISABLE_ACTION, CharacterActions.STRONG_UP).id,
		char.addStatusEffect(StatusEffectType.DISABLE_ACTION, CharacterActions.SPECIAL_NEUTRAL).id,
		char.addStatusEffect(StatusEffectType.DISABLE_ACTION, CharacterActions.SPECIAL_SIDE).id,
		char.addStatusEffect(StatusEffectType.DISABLE_ACTION, CharacterActions.SPECIAL_UP).id,
	],
	reenableAttacks: (char, ids) -> {
		for (effectId in ids)
			char.removeStatusEffect(StatusEffectType.DISABLE_ACTION, effectId);
	},
};

var StageGlobals = {
	// Append to this list for entities that are part of the stage, used
	// to differentiate between game entities and spawned ones
	entities: [],
};

// Tools for running callbacks on every frame! Call tick() every frame, and dependencies can hook into this call using this class
// Depends: match
var StageTimer = {
	// init: () -> match.addEventListener(MatchEvent.TICK_START, StageTimer._tick, {persistent: true}),
	init: () -> {},
	addCallback: (cb) -> StageTimer._callbacks.contains(cb) ? StageTimer._callbacks.indexOf(cb) : StageTimer._callbacks.push(cb) - 1,
	removeCallback: (cb) -> StageTimer._callbacks.remove(cb),
	/// Private
	_tick: () -> {
		for (cb in StageTimer._callbacks)
			cb();
	},
	_callbacks: [],
};

// Draw collision (hurt, hit, grab, etc.) boxes as vfx w/ different colours. Simply initialize w/ blacklist of entities to not render
// Depends: StageTimer, match, StageGlobals
var CollisionBoxRenderer = {
	init: function() {
		StageTimer.addCallback(CollisionBoxRenderer._renderLoop);
		// match.addEventListener(MatchEvent.TICK_END, CollisionBoxRenderer._renderLoop, {persistent: true});
		// Don't render hurtboxes by default
		CollisionBoxRenderer.toggleRender(CollisionBoxType.HURT);
	},
	toggleRender: (boxType) -> {
		CollisionBoxRenderer._boxTypeRenderMap.set(boxType, !CollisionBoxRenderer._shouldRender(boxType));
		return true;
	},
	/// Private
	_boxTypeRenderMap: new IntMap(), // if false
	_shouldRender: (boxType) -> (!CollisionBoxRenderer._boxTypeRenderMap.exists(boxType)
		|| CollisionBoxRenderer._boxTypeRenderMap.get(boxType)),
	_renderLoop: () -> {
		CollisionBoxRenderer._showBoxesFor(match.getCharacters());
		CollisionBoxRenderer._showBoxesFor(match.getProjectiles());
	},
	_fixBox: function(cbox:CollisionBox, entity:Entity) {
		// Returns a collision box but fixes x/y values to absolute accounting for rotation around
		// pivot points etc.
		// NOTE: Recalculating a lot of things that could've been determined using "relativeWith/flipWith/resizeWith"
		//       this means that if the entity is flipped, moved, resized *during* the frame, this won't be reflected
		// NOTE: Also accounting for game physics here since this is calculated before it applies to positions
		var entity_scale = new Point(entity.getGameObjectStat("baseScaleX"), entity.getGameObjectStat("baseScaleY"));
		entity_scale.scale(entity.getScaleX(), entity.getScaleY());

		// get status affect scales
		var size_multiplier = entity.getStatusEffectByType(StatusEffectType.SIZE_MULTIPLIER);
		if (size_multiplier != null) {
			var size_scale = size_multiplier.getProduct();
			entity_scale.scale(size_scale, size_scale);
		}
		var width_multiplier = entity.getStatusEffectByType(StatusEffectType.WIDTH_MULTIPLIER);
		if (width_multiplier != null) {
			var width_scale = width_multiplier.getProduct();
			entity_scale.scale(width_scale, 1);
		}
		var height_multiplier = entity.getStatusEffectByType(StatusEffectType.HEIGHT_MULTIPLIER);
		if (height_multiplier != null) {
			var height_scale = height_multiplier.getProduct();
			entity_scale.scale(1, height_scale);
		}

		var width = cbox.width * entity_scale.x;
		var height = cbox.height * entity_scale.y;

		// TODO: Might be able to convert some of these into matrix manip as well
		//       Can probably return the matrix instead of the modified point and
		//       then continue to apply operations to that
		// Need to account for speed since this information is off-by-one frame.
		// TODO: Is it possible to avoid this offset?
		var should_apply_vel = (entity.getHitstop() == 0);
		var entity_pos = new Point(entity.getX() + should_apply_vel * entity.getNetXVelocity(), entity.getY() + should_apply_vel * entity.getNetYVelocity());
		var entity_pivot = new Point(entity.getPivotXScaled() + entity_pos.x, entity.getPivotYScaled() + entity_pos.y);
		var box_center = Util.getTrueCenter(cbox);

		var rotation = cbox.rotation;
		if (entity.isFacingLeft())
			rotation = Math.flipAngleOverXAxis(cbox.rotation);
		var flipper = entity.isFacingRight() ? 1 : -1;
		var fixed_box_pos = new Point(flipper * box_center.x + entity_pos.x, box_center.y + entity_pos.y);
		// Rotate this point about the *entity* pivot point
		var entity_rotation = cbox.type != CollisionBoxType.LEDGEGRAB ? entity.getRotation() : 0;
		fixed_box_pos = Util.transformPointAroundPivot(fixed_box_pos, entity_pivot, entity_rotation, entity_scale);

		var fixed_box = new CollisionBox(new Rectangle(fixed_box_pos.x, fixed_box_pos.y, width, height), cbox.type);
		fixed_box.rotation = entity_rotation + rotation;
		return fixed_box;
	},
	_displayBox: function(cbox:CollisionBox, entity:Entity) {
		var fixed_box = CollisionBoxRenderer._fixBox(cbox, entity);
		var vfx:Vfx = match.createVfx(new VfxStats({
			spriteContent: self.getResource().getContent("vfx"),
			animation: "display_box",
			x: fixed_box.x,
			y: fixed_box.y,
			scaleX: fixed_box.width / 100,
			scaleY: fixed_box.height / 100,
			rotation: fixed_box.rotation,
			layer: "front",
			timeout: 1,
		}));
		var color_filter:HsbcColorFilter = new HsbcColorFilter();
		// TODO: Might be better performance to have a different box defined animation for each
		//       color. Would also allow changing the opacity of each individually
		// Colors: https://www.learnui.design/blog/the-hsb-color-system-practicioners-primer.html
		color_filter.hue = Math.toRadians(switch (cbox.type) {
			case CollisionBoxType.HIT: 0; // RED!
			case CollisionBoxType.HURT: 60; // YELLOW-ish!
			case CollisionBoxType.GRAB: 240; // BLUE!
			case CollisionBoxType.LEDGEGRAB: 180;
			case CollisionBoxType.REFLECT: 120;
			case CollisionBoxType.ABSORB: 120;
			case CollisionBoxType.COUNTER: 120;
			case CollisionBoxType.SHIELD: 180;
			case CollisionBoxType.CUSTOMA: 270;
			case CollisionBoxType.CUSTOMB: 270;
			case CollisionBoxType.CUSTOMC: 270;
			default: 360; // TODO: should specially display
		});
		// color_filter.hue = 0;
		vfx.addFilter(color_filter);
	},
	_dumpInfo: function(cbox:CollisionBox, entity:Entity) {},
	_showBoxesFor: (entities) -> {
		for (entity in entities) {
			// Do not show boxes for entites that are part of the stage
			if (StageGlobals.entities.contains(entity))
				continue;
			for (boxType in BOX_TYPES) {
				if (!CollisionBoxRenderer._shouldRender(boxType))
					continue;
				var boxes = entity.getCollisionBoxes(boxType);
				if (boxes != null) {
					for (cbox in boxes) {
						CollisionBoxRenderer._displayBox(cbox, entity);
						CollisionBoxRenderer._dumpInfo(cbox, entity);
					}
				}
			}
		}
	}
};

// Track the hitbox stats of the attacks done by provided character (Unused & Out-of-date)
// Depends: StageTimer
var HitboxTracker = {
	// Set up variables and listeners
	init: (char, dummy) -> {
		HitboxTracker._char = char;
		StageTimer.addCallback(HitboxTracker._frame_loop);
		char.addEventListener(GameObjectEvent.HITBOX_CONNECTED, function(e:GameObjectEvent) {
			// Only track moves that hit the dummy
			if (e.data.foe == dummy) {
				HitboxTracker._connected_callback(e.data.hitboxStats);
			}
		}, {persistent: true});
		char.addEventListener(EntityEvent.STATE_CHANGE, HitboxTracker._state_handler, {persistent: true});
	},
	/// Private
	// Increment the frame if currently counting frames
	_frame_loop: () -> {
		if (HitboxTracker._should_count)
			HitboxTracker._frame += 1;
	},
	// When the character changes states, dump and reset if was tracking attack stats.
	// Otherwise start tracking if this is an attack
	_state_handler: () -> {
		if (HitboxTracker._should_count) {
			HitboxTracker._dump_stats();
			HitboxTracker._reset();
		}
		HitboxTracker._should_count = HitboxTracker._char.inStateGroup(CStateGroup.ATTACK);
	},
	// When a hitbox connects with an entity, track when it happened and what were the stats
	_connected_callback: function(hbs:HitboxStats) {
		// Create a new info struct if necessary
		if (!HitboxTracker._hitbox_info.exists(hbs.attackId)) {
			HitboxTracker._hitbox_info.set(hbs.attackId, {
				stats: new IntMap(),
				active_frames: new IntMap(),
			});
		}
		var hb_info = HitboxTracker._hitbox_info.get(hbs.attackId);
		// Create stats/active_frame info for hitbox index if necesary
		if (!hb_info.stats.exists(hbs.index)) {
			// Store the hitbox stats for this attackId/hitbox index pair.
			// Even if it reappears, the stats should be the same (minus some populated values like damage/angle)
			hb_info.stats.set(hbs.index, hbs);
			hb_info.active_frames.set(hbs.index, []);
		}
		// Store the frames that this attackId/hitbox index pair was seen.
		// Provides a full sense of how many hitboxes there will be
		hb_info.active_frames.get(hbs.index).push(HitboxTracker._frame + 1);
		Engine.log("saw hb=" + hbs.attackId + " hitbox#" + hbs.index);
	},
	// Dump simple data about which frames the hitboxes are active
	_dump_stats: () -> {
		Engine.log("Dumping stats for last attack");
		// _frame will be the frame after the last attack frame so subtract 1
		Engine.log("num_frames=" + (HitboxTracker._frame - 1));
		for (attack_id in HitboxTracker._hitbox_info.keys()) {
			var hb_info = HitboxTracker._hitbox_info.get(attack_id);
			for (hb_index in hb_info.stats.keys()) {
				var seen_frames = hb_info.active_frames.get(hb_index);
				Engine.log("attackId=" + attack_id + " hitbox#" + hb_index + " timesSeen=" + seen_frames);
			}
		}
		Engine.log("=====================================================================");
	},
	// Reset tracking information
	_reset: () -> {
		HitboxTracker._frame = 0;
		HitboxTracker._should_count = false;
		HitboxTracker._hitbox_info.clear();
	},
	_frame: 0,
	_should_count: false,
	_char: null,

	/**
	 * { [attackId: Int]: { 
	 *     stats: {[hitboxIndex: int]: HitboxStats}, 
	 *     active_frames: {[hitboxIndex: int]: Int[]} 
	 * } }
	 */
	_hitbox_info: new IntMap(),
};

// Draw collision (hurt, hit, grab, etc.) boxes as vfx w/ different colours. Simply initialize w/ blacklist of entities to not render
// Depends: StageTimer, Util
var SlowDownHandler = {
	SLOW_FRAMES: [0, 5, 10, 20],
	init: function() {
		StageTimer.addCallback(SlowDownHandler._tick);
	},
	setAmount: (slow_amount) -> {
		SlowDownHandler._slow_amount = slow_amount;
	},
	// Private
	_char: null,
	_char_initialized: false,
	_slow_amount: 0,
	_tick: () -> {
		if (!SlowDownHandler._char_initialized) {
			SlowDownHandler._char = Util.getP1();
			SlowDownHandler._char_initialized = true;
		}
		if (SlowDownHandler._slow_amount > 0 && SlowDownHandler._char != null) {
			if (SlowDownHandler._char.inStateGroup(CStateGroup.ATTACK))
				match.freezeScreen(SlowDownHandler._slow_amount, []);
		}
	},
};

// Draw collision (hurt, hit, grab, etc.) boxes as vfx w/ different colours. Simply initialize w/ blacklist of entities to not render
// Depends: StageTimer, Util
var FloatHandler = {
	init: () -> {
		StageTimer.addCallback(FloatHandler._tick);
	},
	toggleFloat: () -> {
		FloatHandler._shouldFloat = !FloatHandler._shouldFloat;
		return true;
	},
	// Private
	_char: null,
	_char_initialized: false,
	_shouldFloat: false,
	_tick: () -> {
		if (!FloatHandler._char_initialized) {
			FloatHandler._char = Util.getP1();
			FloatHandler._char_initialized = true;
		}
		var char:Character = FloatHandler._char;
		if (FloatHandler._shouldFloat && char != null) {
			if (!char.isOnFloor() && char.inStateGroup(CStateGroup.ATTACK)) {
				char.setYSpeed(0);
				char.updateAnimationStats({gravityMultiplier: 0});
			}
		}
	},
};

// Manage Buttons which can perform various actions depending on provided callbacks
// Depends: StageTimer, StageGlobals, Util, match
var ButtonHandler = {
	BUTTONS: [
		"SPECIAL",
		"HURT",
		"HIT",
		"STAGE",
		"ATT_SLOW",
		"ATT_FLOAT",
		"UNKNOWN_1",
		"UNKNOWN_2",
		"UNKNOWN_3",
	],
	BUTTON_STATS: [
		"SPECIAL" => {
			position: [Util.average(-245, -99), -97],
			default_anim: "on",
		},
		"HURT" => {
			position: [Util.average(-60, 82), -97],
			default_anim: "off",
		},
		"HIT" => {
			position: [Util.average(114, 260), -97],
			default_anim: "on",
		},
		"STAGE" => {
			position: [Util.average(-245, -99), -208],
			default_anim: "off",
		},
		"ATT_SLOW" => {
			position: [Util.average(-60, 82), -208],
			default_anim: "off",
			options: [0, 5, 10, 20]
		},
		"ATT_FLOAT" => {
			position: [Util.average(114, 260), -208],
			default_anim: "off",
		},
		"UNKNOWN_1" => {
			position: [Util.average(-245, -99), -319],
			default_anim: "off",
		},
		"UNKNOWN_2" => {
			position: [Util.average(-60, 82), -319],
			default_anim: "off",
		},
		"UNKNOWN_3" => {
			position: [Util.average(114, 260), -319],
			default_anim: "off",
		},
	],
	BUTTON_Y_OFFSET: -5,
	init: function(?toggle_handlers) {
		var _toggle_handlers = toggle_handlers;
		if (_toggle_handlers == null)
			_toggle_handlers = new StringMap();
		var num_buttons = ButtonHandler.BUTTONS.length;
		for (button_idx in 0...num_buttons) {
			var name = ButtonHandler.BUTTONS[button_idx];
			var empty_handler = () -> false;
			ButtonHandler._spawn_button(name, _toggle_handlers.exists(name) ? _toggle_handlers.get(name) : empty_handler);
		}
	},
	setButtonAnim: (name, anim) -> {
		var i = ButtonHandler.BUTTONS.indexOf(name);
		if (i >= 0 && i < ButtonHandler._buttons.length && ButtonHandler._buttons[i].hasAnimation(anim))
			ButtonHandler._buttons[i].playAnimation(anim);
	},
	openDialogueFor: (button_name, choice_cb) -> {
		if (button_name != "ATT_SLOW")
			return Util.throwError("Trying to open dialogue for unsupported button!");
		ButtonHandler._openDialogue(choice_cb);
	},
	// private
	_buttons: [],
	_dialogue_open: false, // TODO: Not needed if button has cooldown probably
	_curr_dialogue: null,
	_choice_cb: null,
	_disabled_attacks: [],
	_option_idx: 0,
	_next_option_idx: 0,
	_openDialogue: (choice_cb) -> {
		if (ButtonHandler._dialogue_open)
			return;
		ButtonHandler._dialogue_open = true;
		ButtonHandler._choice_cb = choice_cb;
		var char:Character = Util.getP1();
		if (char == null)
			return ButtonHandler._closeDialogue();
		// teleport to floor
		char.setX(ButtonHandler.BUTTON_STATS["ATT_SLOW"].position[0] - char.getEcbFootX());
		char.setY(ButtonHandler.BUTTON_STATS["ATT_SLOW"].position[1] - char.getEcbFootY());
		char.attachToFloor(match.getStructureByName("Opt. Plat ATT_SLOW"));
		char.toState(CState.UNINITIALIZED, "stand");
		char.updateAnimationStats({slideOff: false}); // o.O
		// Should be attached to floor ....
		if (char.getCurrentFloor() != null)
			char.getCurrentFloor().updateStructureStats({dropThrough: false});
		ButtonHandler._disabled_attacks = Util.disableAttacks(char);
		var right_checker, left_checker, select_checker, close_checker;
		var clean_up_dialogue = () -> {
			StageTimer.removeCallback(right_checker);
			StageTimer.removeCallback(left_checker);
			StageTimer.removeCallback(select_checker);
			StageTimer.removeCallback(close_checker);
			ButtonHandler._closeDialogue();
		};
		// NOTE: If allowing cycle, should use Math.modulo instead of %, the latter does not enforce positive result
		right_checker = Util.onButtonsHeld(char, Buttons.RIGHT | Buttons.RIGHT_STICK_RIGHT | Buttons.UP | Buttons.RIGHT_STICK_UP, () -> {
			// Stop at top target
			ButtonHandler._next_option_idx = Math.min(ButtonHandler._next_option_idx + 1, ButtonHandler.BUTTON_STATS["ATT_SLOW"].options.length - 1);
		}, true);
		left_checker = Util.onButtonsHeld(char, Buttons.LEFT | Buttons.RIGHT_STICK_LEFT | Buttons.DOWN | Buttons.RIGHT_STICK_DOWN, () -> {
			// Stop at zero
			ButtonHandler._next_option_idx = Math.max(ButtonHandler._next_option_idx - 1, 0);
		}, true);
		select_checker = Util.onButtonsHeld(char, Buttons.ATTACK | Buttons.TILT | Buttons.STRONG | Buttons.ACTION | Buttons.GRAB, () -> {
			ButtonHandler._option_idx = ButtonHandler._next_option_idx;
			clean_up_dialogue();
		}, true);
		close_checker = Util.onButtonsHeld(char, Buttons.SHIELD | Buttons.SPECIAL, () -> {
			clean_up_dialogue();
		}, true);
		ButtonHandler._curr_dialogue = match.createVfx(new VfxStats({
			spriteContent: self.getResource().getContent("vfx"),
			animation: "slowdown_select",
			x: char.getX() + char.getEcbFootX(),
			y: char.getY() + char.getEcbFootY(),
			layer: "front",
		}));
		self.getForegroundEffectsContainer().addChild(ButtonHandler._curr_dialogue.getViewRootContainer());
		ButtonHandler._curr_dialogue.playFrame(ButtonHandler._next_option_idx + 1);
		ButtonHandler._curr_dialogue.pause();
		StageTimer.addCallback(ButtonHandler._updateDialogue);
	},
	_closeDialogue: () -> {
		ButtonHandler._next_option_idx = (ButtonHandler._option_idx == null) ? 0 : ButtonHandler._option_idx;
		var char:Character = Util.getP1();
		if (char != null) {
			char.toState(CState.STAND);
			if (char.getCurrentFloor() != null)
				char.getCurrentFloor().updateStructureStats({dropThrough: true});
			Util.reenableAttacks(char, ButtonHandler._disabled_attacks);
			ButtonHandler._disabled_attacks = [];
		}
		if (ButtonHandler._curr_dialogue != null) {
			ButtonHandler._curr_dialogue.playFrame(ButtonHandler._curr_dialogue.getTotalFrames());
			ButtonHandler._curr_dialogue.resume();
			ButtonHandler._curr_dialogue = null;
		}
		if (ButtonHandler._choice_cb != null)
			ButtonHandler._choice_cb(ButtonHandler.BUTTON_STATS["ATT_SLOW"].options[ButtonHandler._option_idx]);
		ButtonHandler._choice_cb = null;
		ButtonHandler._dialogue_open = false;
		StageTimer.removeCallback(ButtonHandler._updateDialogue);
		var button_is_on = ButtonHandler._option_idx != 0;
		ButtonHandler._buttons[ButtonHandler.BUTTONS.indexOf("ATT_SLOW")].playAnimation(button_is_on ? "on" : "off");
	},
	_updateDialogue: () -> {
		if (ButtonHandler._curr_dialogue != null)
			ButtonHandler._curr_dialogue.playFrame(ButtonHandler._next_option_idx + 1);
	},
	/// button spawn
	_spawn_button: function(name, toggle_handler) {
		var button_stats = ButtonHandler.BUTTON_STATS[name];
		var b:Projectile = match.createProjectile(self.getResource().getContent("boxviewerButton"));
		b.playAnimation(button_stats.default_anim);
		b.setX(button_stats.position[0]);
		b.setY(button_stats.position[1] + ButtonHandler.BUTTON_Y_OFFSET);
		b.addEventListener(GameObjectEvent.HIT_RECEIVED, function(e:GameObjectEvent) {
			// Ignore hitboxes that wouldn't flinch anyways
			var hitbox = e.data.hitboxStats;
			if (hitbox.flinch == false)
				return;

			Engine.log("Toggling " + name + " button");
			AudioClip.play(GlobalSfx.STRONG_CLICK);
			var char = e.data.foe.getRootOwner();
			if (char == null || char.getType() != EntityType.CHARACTER)
				return;

			if (toggle_handler()) {
				var isOn = (b.getAnimation() == "on");
				var toggleAnim = isOn ? "off" : "on";
				b.playAnimation(toggleAnim);
			}
		}, {persistent: true});
		StageGlobals.entities.push(b);
		ButtonHandler._buttons.push(b);
	},
};

// Toggle between the two stage frames, first is invisible (except option plats) and second is entirely visible
// Depends: StageTimer, self
var StageVisibilityHandler = {
	init: () -> {
		self.pause();
		// play label no work? but last frame is the visible one
	},
	toggleVisibility: () -> {
		StageVisibilityHandler._visible = !StageVisibilityHandler._visible;
		self.playLabel(StageVisibilityHandler._visible ? "visible" : "invisible");
		return true;
	},
	_visible: true,
};

// Manage moving platform that moves P1 between the different stage regions
// Depends: StageTimer, StageGlobals, Util
var ElevatorHandler = {
	WAIT_TIME: 300,
	MAX_Y: -977.5,
	BASE_MOVE_SPEED: 7.5, // ~4s from bottom to top, 2s to options
	TARGETTING_MOVE_SPEED: 24, // ~1s from bottom to top
	TARGETS: ["MAIN", "OPTIONS", "FD"],
	TARGET_STATS: [
		"MAIN" => () -> ElevatorHandler._start_y,
		"OPTIONS" => () -> -208,
		"FD" => () -> ElevatorHandler.MAX_Y,
	],
	init: () -> {
		ElevatorHandler._platform = match.createStructure(self.getResource().getContent("boxviewerElevator"));
		ElevatorHandler._start_y = ElevatorHandler._platform.getStructureStat("startY");
		StageTimer.addCallback(ElevatorHandler._tick);
	},
	getElevator: () -> ElevatorHandler._platform,
	// private
	_platform: null,
	_target: null,
	_next_target: 0,
	_start_y: 0,
	_wait_timer: -1,
	// Plat is moving or char is in region select
	// TODO: Now that I know how to roughly do classes, should refact these into class instances
	_curr_dialogue: null,
	_is_moving: false,
	_in_selection_idle: false,
	_selection_cb: null,
	_disabled_attacks: [],
	_hasPassenger: (char) -> {
		if (char == null)
			return false;
		return (char.getCurrentFloor() == ElevatorHandler._platform);
	},
	_clearSelectionIdle: () -> {
		ElevatorHandler._in_selection_idle = false;
		if (ElevatorHandler._selection_cb != null) {
			StageTimer.removeCallback(ElevatorHandler._selection_cb);
			ElevatorHandler._selection_cb = null;
		}
		if (ElevatorHandler._curr_dialogue != null) {
			ElevatorHandler._curr_dialogue.resume();
			ElevatorHandler._curr_dialogue = null;
		}
	},
	_enterSelectionIdle: (char) -> {
		var plat:Structure = ElevatorHandler._platform;
		// wait a bit so that plat doesn't fire immediately
		ElevatorHandler._in_selection_idle = true;
		ElevatorHandler._selection_cb = Util.onButtonsHeld(char, Buttons.ATTACK | Buttons.TILT | Buttons.STRONG | Buttons.ACTION | Buttons.GRAB, () -> {
			if (char.getCurrentFloor() == plat) {
				ElevatorHandler._openDialogue(char);
			}
		});
		ElevatorHandler._curr_dialogue.playFrame(ElevatorHandler._curr_dialogue.getTotalFrames());
	},
	_openDialogue: (char) -> {
		ElevatorHandler._clearSelectionIdle();
		// If closed and reopened dialogue, remove selectin cb
		// display dialogue vfx;
		char.toState(CState.UNINITIALIZED, "stand");
		char.updateAnimationStats({slideOff: false}); // o.O
		char.getCurrentFloor().updateStructureStats({dropThrough: false});
		ElevatorHandler._disabled_attacks = Util.disableAttacks(char);
		var right_checker, left_checker, select_checker, close_checker;
		var clean_up_dialogue = () -> {
			StageTimer.removeCallback(right_checker);
			StageTimer.removeCallback(left_checker);
			StageTimer.removeCallback(select_checker);
			StageTimer.removeCallback(close_checker);
			ElevatorHandler._closeDialogue(char);
		};
		// NOTE: If allowing cycle, should use Math.modulo instead of %, the latter does not enforce positive result
		right_checker = Util.onButtonsHeld(char, Buttons.RIGHT | Buttons.RIGHT_STICK_RIGHT | Buttons.UP | Buttons.RIGHT_STICK_UP, () -> {
			// Stop at top target
			ElevatorHandler._next_target = Math.min(ElevatorHandler._next_target + 1, ElevatorHandler.TARGETS.length - 1);
		}, true);
		left_checker = Util.onButtonsHeld(char, Buttons.LEFT | Buttons.RIGHT_STICK_LEFT | Buttons.DOWN | Buttons.RIGHT_STICK_DOWN, () -> {
			// Stop at zero
			ElevatorHandler._next_target = Math.max(ElevatorHandler._next_target - 1, 0);
		}, true);
		select_checker = Util.onButtonsHeld(char, Buttons.ATTACK | Buttons.TILT | Buttons.STRONG | Buttons.ACTION | Buttons.GRAB, () -> {
			ElevatorHandler._target = ElevatorHandler._next_target;
			clean_up_dialogue();
		}, true);
		close_checker = Util.onButtonsHeld(char, Buttons.SHIELD | Buttons.SPECIAL, () -> {
			clean_up_dialogue();
		}, true);
		ElevatorHandler._curr_dialogue = match.createVfx(new VfxStats({
			spriteContent: self.getResource().getContent("vfx"),
			animation: "elevator_select",
			x: char.getX() + char.getEcbFootX(),
			y: char.getY() + char.getEcbFootY(),
			layer: "front",
		}));
		self.getForegroundEffectsContainer().addChild(ElevatorHandler._curr_dialogue.getViewRootContainer());
		ElevatorHandler._curr_dialogue.playFrame(ElevatorHandler._next_target + 1);
		ElevatorHandler._curr_dialogue.pause();
	},
	_closeDialogue: (char) -> {
		// Save last selection
		ElevatorHandler._next_target = ElevatorHandler._target == null ? 0 : ElevatorHandler._target;
		char.toState(CState.STAND);
		char.getCurrentFloor().updateStructureStats({dropThrough: true});
		Util.reenableAttacks(char, ElevatorHandler._disabled_attacks);
		ElevatorHandler._disabled_attacks = [];
		ElevatorHandler._enterSelectionIdle(char);
	},
	_movePlat: (char) -> {
		var plat:Structure = ElevatorHandler._platform;
		// if wasn't moving, disable character and open options dialogue
		if (!ElevatorHandler._is_moving) {
			// Open dialogue when start moving
			ElevatorHandler._openDialogue(char);
		}
		if (ElevatorHandler._target == null) {
			plat.setY(Math.max(ElevatorHandler.MAX_Y, plat.getY() - ElevatorHandler.BASE_MOVE_SPEED));
		} else {
			var target_pos = ElevatorHandler.TARGET_STATS[ElevatorHandler.TARGETS[ElevatorHandler._target]]();
			var going_down = target_pos > plat.getY();
			var apply_speed = () -> {
				if (going_down)
					return Math.min(target_pos, plat.getY() + ElevatorHandler.TARGETTING_MOVE_SPEED);
				return Math.max(target_pos, plat.getY() - ElevatorHandler.TARGETTING_MOVE_SPEED);
			};
			plat.setY(apply_speed());
		}
		if (ElevatorHandler._curr_dialogue != null) {
			ElevatorHandler._curr_dialogue.setX(char.getX() + char.getEcbFootX());
			ElevatorHandler._curr_dialogue.setY(char.getY() + char.getEcbFootY());
			if (!ElevatorHandler._in_selection_idle)
				ElevatorHandler._curr_dialogue.playFrame(ElevatorHandler._next_target + 1);
			// If dialogue is open
		}
	},
	_resetPlat: () -> {
		ElevatorHandler._clearSelectionIdle();
	},
	_tick: () -> {
		var plat:Structure = ElevatorHandler._platform;
		var char:Character = Util.getP1();
		// when character on plat mvoe up
		if (ElevatorHandler._hasPassenger(char)) {
			ElevatorHandler._movePlat(char);
			ElevatorHandler._is_moving = true;
			ElevatorHandler._wait_timer = -1;
			return;
		}
		// when character not on plat, wait a bit, then teleport back to start position
		else if (plat.getY() != ElevatorHandler._start_y) {
			if (ElevatorHandler._wait_timer < 0) {
				ElevatorHandler._wait_timer = ElevatorHandler.WAIT_TIME;
				// First time getting off the plat so should clear selection and unrender img
				ElevatorHandler._resetPlat();
			}
			ElevatorHandler._wait_timer--;
			if (ElevatorHandler._wait_timer < 0) {
				plat.setY(ElevatorHandler._start_y);
			}
		} else if (ElevatorHandler._is_moving) {
			ElevatorHandler._resetPlat();
		}
		ElevatorHandler._is_moving = false;
	},
};

// Helps to ensure the camera view is sane.
// Prioritizes P1 in tricky situations otherwise teleport other players to where P1 is.
// Depends: StageTimer
var CameraViewHelper = {
	REGIONS: [
		// Order determines which region is handled first
		// not using region_stats.keys() because assoc. arrays don't preserve order fsr.
		"ELEVATOR",
		"MAIN",
		"FD",
		"OPTIONS",
	],
	REGION_STATS: [
		"ELEVATOR" => {
			in_region: () -> CameraViewHelper._last_floor == CameraViewHelper._elevator,
			region_rect: null,
			teleport_pos: null,
		}
		"MAIN" => {
			in_region: null,
			region_rect: new Rectangle(-950, 68, 1900, 1355),
			teleport_pos: Point.create(-25, 838),
		},
		"FD" => {
			in_region: null,
			region_rect: new Rectangle(-950, -1775, 1900, 1350),
			teleport_pos: Point.create(233, -1013),
		},
		"OPTIONS" => {
			in_region: null,
			region_rect: new Rectangle(-950, -698, 1900, 768),
			teleport_pos: null,
		},
	],
	init: () -> {
		CameraViewHelper._elevator = ElevatorHandler.getElevator();
		if (CameraViewHelper._elevator == null)
			Util.throwError("No elevator plat found");
		StageTimer.addCallback(CameraViewHelper._tick);
	},
	// Private
	_elevator: null,
	_last_floor: null,
	_last_region: "MAIN",
	_char: null,
	_char_initialized: false,
	_tick: () -> {
		if (!CameraViewHelper._char_initialized) {
			CameraViewHelper._char = Util.getP1();
			CameraViewHelper._char_initialized = true;
		}
		var char:Character = CameraViewHelper._char;
		if (char != null && char.isOnFloor())
			CameraViewHelper._last_floor = char.getCurrentFloor();
		var region = CameraViewHelper._last_region;
		if (!CameraViewHelper._isInRegion(region, char)) {
			region = CameraViewHelper._getRegion();
		} else if (CameraViewHelper._isInRegion("ELEVATOR", char)) {
			// Elevator takes priority over current region
			region = "ELEVATOR";
		}
		var region_stats = CameraViewHelper.REGION_STATS[region];
		var changed_region = (region != CameraViewHelper._last_region);
		CameraViewHelper._last_region = region;
		if (region_stats.teleport_pos == null) {
			if (changed_region) {
				for (other_char in match.getCharacters()) {
					if (char == other_char)
						continue;
					camera.deleteTarget(other_char);
				}
			}
		} else {
			for (other_char in match.getCharacters()) {
				if (char == other_char)
					continue;
				if (!CameraViewHelper._isInRegion(region, other_char) && !other_char.inState(CState.KO)) {
					if (other_char.inStateGroup(CStateGroup.LEDGE)) {
						other_char.releaseLedge();
					} else if (other_char.inStateGroup(CStateGroup.HURT_HEAVY)) {
						// Leave hurt characters alone
					} else {
						other_char.setX(region_stats.teleport_pos.x);
						other_char.setY(region_stats.teleport_pos.y);
					}
				}
				if (changed_region)
					camera.addTarget(other_char);
			}
		}
	},
	_getRegion: () -> {
		var char:Character = CameraViewHelper._char;
		// Default to main region, if all players are CPU
		// - just ensure we stay in that region
		if (char != null) {
			// key-value iteration not supported it seems ;-;
			for (region in CameraViewHelper.REGIONS) {
				if (CameraViewHelper._isInRegion(region, char))
					return region;
			}
			// Going to respawn char ...
			if (char.inState(CState.KO))
				return "MAIN";
			Util.throwError("Using default region because can't place char ... (x:" + char.getX() + ", y:" + char.getY() + ")");
		}
		// Default to main region
		return "MAIN";
	},
	_isInRegion: (region, char) -> {
		if (region == null || char == null)
			return false;
		var region_stats = CameraViewHelper.REGION_STATS.get(region);
		if (region_stats.in_region != null && region_stats.in_region()) {
			return true;
		}
		if (region_stats.region_rect != null && region_stats.region_rect.contains(char.getX(), char.getY())) {
			return true;
		}
		return false;
	},
};

function initialize() {
	ButtonHandler.init([
		"HURT" => () -> CollisionBoxRenderer.toggleRender(CollisionBoxType.HURT),
		"HIT" => () -> CollisionBoxRenderer.toggleRender(CollisionBoxType.HIT),
		"SPECIAL" => () -> {
			for (boxType in BOX_TYPES) {
				if (![CollisionBoxType.HIT, CollisionBoxType.HURT].contains(boxType)) {
					CollisionBoxRenderer.toggleRender(boxType);
				}
			}
			return true;
		},
		"STAGE" => StageVisibilityHandler.toggleVisibility,
		"ATT_SLOW" => () -> {
			ButtonHandler.openDialogueFor("ATT_SLOW", SlowDownHandler.setAmount);
			// don't toggle, will apply animation update later
			return false;
		},
		"ATT_FLOAT" => FloatHandler.toggleFloat,
	]);

	StageVisibilityHandler.init();
	StageTimer.init();
	CollisionBoxRenderer.init();
	SlowDownHandler.init();
	FloatHandler.init();
	ElevatorHandler.init();
	CameraViewHelper.init();
}

function update() {
	StageTimer._tick();
}

// Unused engine callbacks:
// onTeardown
// onKill
// onStale
// afterPushState
// afterPopState
// afterFlushStates

// Pain points:
// - can't set pivot point for a vfx
//    - would be nice to use 0, 0 for the x,y and only have to do avvounting for pivot
//    - but since the pivot *must* be 0,0 for vfx, the accounting now has to be done for both
// - can't update pivot point for *entity*
//    - would be nice to just use entity pivot point for vfx and only worry about relative fixups for rotation for a given box
// - can't rotateWith
//    - similar to above, would be nice if the rotation could just match the entity (along with the *absolute* pivot)
// - centerX/centerY of collision box doesn't account for rotation
// - No good way to prevent character from using inputs and still be able to read them
//    - uninitialized state allows dropthrough?
//    - disabled state locks to last input

// Playtesters: Nuova, Sky, Lood, Exo, Peace, Salt, Kactus
// TODO (post-release):
// ===== Tier 1 (Functional) =====
// - empty custom game object to workaround getCustomGameObjects() bug
// - ECB display
// - add grid to BG? or BG parallax idk
//     - should have reference for stage widths
//     - see: MVS (https://multiversus.fandom.com/wiki/Training_Room?file=Training.png), Ultiamte (https://ssb.wiki.gallery/images/1/14/Training_stage.jpg)
// - body armour display
//
// ===== Tier 2 (Usability) =====
// - performance
// - Cooldown between button presses
// - disabled buttons
// - hazard variant is just FD? Or some other differences
//      - move between variants using options maybe on regular?
//      - Need to figure out how to handle teleport plat on all variants tho.
//      - or just elevator ease riding
// - buttons should be intangible probably
//
// ===== Tier 3 (Other) =====
// - Force buttons to position (so they can't be moved)
// - correlate w/ hitbox stats (and display)
// - boxes on menu image o.O
// - Implement UNKOWN Buttons
