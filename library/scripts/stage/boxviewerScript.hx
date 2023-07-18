// API Script for Hitbox Debug Stage
// frames in boxViewerVfx#display_box and  boxViewerVfx#display_line will match these colors
var FRAME_COLORS = {
	RED: 1,
	ORANGE: 2,
	YELLOW: 3,
	YELLOW_GREEN: 4,
	GREEN: 5,
	BLUE_GREEN: 6,
	CYAN: 7,
	AQUAMARINE: 8,
	BLUE: 9,
	PURPLE: 10,
	RED_PURPLE: 11,
	ROSE_PINK: 12,
};

// NOTE: The below look like classes, but are really just structs. Treat them like singletons/static classes.
//       Goal of doing it this way, is to make things a bit more portable.
// TODO: Should be more rollback safe probably
function frames_to_string(frames) {
	var frame_string = "";
	var curr_range = [frames[0], frames[0]];
	for (frame in frames) {
		if (frame == curr_range[1])
			continue;
		if (frame > curr_range[1] + 1) {
			if (frame_string != "") {
				frame_string += ", ";
			}
			frame_string += curr_range[0] + "-" + curr_range[1];
			curr_range = [frame, frame];
		}
		curr_range[1] += 1;
	}
	if (frame_string != "") {
		frame_string += ", ";
	}
	frame_string += curr_range[0] + "-" + curr_range[1];
	return frame_string;
}

function printAllHitboxData(hitbox_info) {
	/**
	 * { [attackId: Int]: { 
	 *     stats: {[hitboxIndex: int]: HitboxStats}, 
	 *     active_frames: {[hitboxIndex: int]: Int[]} 
	 * } }
	 */
	var i = 0;

	Engine.log("-------------------------------------------------------------------------------------------------------------------------------", 0x948f58);
	for (attack_id in hitbox_info.keys()) {
		var hb_info = hitbox_info.get(attack_id);
		for (hb_index in hb_info.stats.keys()) {
			var stats = hb_info.stats.get(hb_index);
			var seen_frames = hb_info.active_frames.get(hb_index);
			printHitboxData(i, stats, frames_to_string(seen_frames));
			++i;
			Engine.log("-------------------------------------------------------------------------------------------------------------------------------",
				0x948f58);
		}
	}
	Engine.log("");
}

function printHitboxData(idx, hitbox_stats, frame_string) {
	// Adapted from the Frame Data Tool
	var attackId = hitbox_stats.attackId;
	var index = hitbox_stats.index;
	// Important hitbox variables
	var rawdamage = hitbox_stats.rawDamage;
	var baseKnockback = hitbox_stats.baseKnockback;
	var knockbackgrowth = hitbox_stats.knockbackGrowth;
	var rawangle = hitbox_stats.rawAngle;
	var reversibleangle = hitbox_stats.reversibleAngle;
	var hitstop = hitbox_stats.hitstop;
	var hitstopoffset = hitbox_stats.hitstopOffset;
	var hitstopmultipler = hitbox_stats.hitstopMultiplier;
	var selfhitstop = hitbox_stats.selfHitstop;
	var selfhittopoffset = hitbox_stats.selfHitstopOffset;
	var hitstun = hitbox_stats.hitstun;
	// Shield
	var shieldable = hitbox_stats.shieldable;
	var shieldDamageMultiplier = hitbox_stats.shieldDamageMultiplier;
	var shieldstunMultiplier = hitbox_stats.shieldstunMultiplier;
	// Proj / Other
	var reflectable = hitbox_stats.reflectable;
	var absorbable = hitbox_stats.absorbable;
	var reverse = hitbox_stats.reverse;
	// Uncommon
	var attackRatio = hitbox_stats.attackRatio;
	var maxChargeDamageMultiplier = hitbox_stats.maxChargeDamageMultiplier;
	var jabResetType = hitbox_stats.jabResetType;
	var flinch = hitbox_stats.flinch;
	var forceTumbleFall = hitbox_stats.forceTumbleFall;
	var stackKnockback = hitbox_stats.stackKnockback;
	var knockbackCap = hitbox_stats.knockbackCap;

	// Make Array With Data
	current_hitbox_stats_basic = [
		"hitbox" + index,
		"| DMG:" + rawdamage,
		"| BKB:" + baseKnockback,
		"| KBG:" + knockbackgrowth,
		"| ANG:" + rawangle,
		"| R.ANG:" + reversibleangle,
		"| HP:" + hitstop,
		"| HPO:" + hitstopoffset,
		"| SLHP:" + selfhitstop,
		"| SLHPO:" + selfhittopoffset,
		"| HPMUL:" + hitstopmultipler,
		"| HTSTN:" + hitstun
	];

	// Extra Data Array
	current_hitbox_stats_extra = [
		"SLD:" + shieldable,
		"| S.DMG:" + shieldDamageMultiplier,
		"| S.STN:" + shieldstunMultiplier,
		"| RFT:" + reflectable,
		"| ABS:" + absorbable,
		"| RVS:" + reverse,
		"| AKRT:" + attackRatio,
		"| CDMUL:" + maxChargeDamageMultiplier,
		"| JRST:" + jabResetType,
		"| FLCH:" + flinch,
		"| FTMLB:" + forceTumbleFall,
		"| STKB:" + stackKnockback,
		"| KCAP:" + knockbackCap
	];
	var active_frames_string:String = "#" + idx + ": | Active Frames: " + frame_string;
	var hitbox_output_string:String = active_frames_string + " | " + current_hitbox_stats_basic;
	Engine.log(hitbox_output_string);
	Engine.log(current_hitbox_stats_extra);
}

var Util = {
	getP1: inline function() {
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
	bodyStatusToString: (bodyStatus) -> {
		switch (bodyStatus) {
			case BodyStatus.DAMAGE_ARMOR: "DAMAGE_ARMOR";
			case BodyStatus.DAMAGE_RESISTANCE: "DAMAGE_RESISTANCE";
			case BodyStatus.INTANGIBLE: "INTANGIBLE";
			case BodyStatus.INVINCIBLE: "INVINCIBLE";
			case BodyStatus.INVINCIBLE_GRABBABLE: "INVINCIBLE_GRABBABLE";
			case BodyStatus.LAUNCH_RESISTANCE: "LAUNCH_RESISTANCE";
			case BodyStatus.LAUNCH_ARMOR: "LAUNCH_ARMOR";
			case BodyStatus.NONE: "NONE";
			case BodyStatus.SUPER_ARMOR: "SUPER_ARMOR";
			default: "N/A";
		}
	},
	getTrueCenter: inline function(cbox:CollisionBox, outPoint:Point) {
		if (cbox.rotation == 0) {
			outPoint.x = cbox.centerX;
			outPoint.y = cbox.centerY;
			return outPoint;
		}
		var p = outPoint;
		outPoint.x = cbox.x;
		outPoint.y = cbox.y;
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
		return Util.applyMatrix(tMatrix, p, p);
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
	transformPointAroundPivot: inline function(point:Point, pivot:Point, rotation:Float, scale:Point) {
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
	},
	average: inline function(num1, num2) {
		return (num1 + num2) / 2;
	},
	printMatrix: (m) -> {
		Engine.log("[" + m.a + " " + m.b + " " + m.tx);
		Engine.log(" " + m.c + " " + m.d + " " + m.ty);
		Engine.log(" " + 0 + " " + 0 + " " + 1 + "]");
	},
	applyMatrix: function(matrix:Matrix, point:Point, ?outPoint:Point) {
		var out = outPoint == null ? new Point(0, 0) : outPoint;
		var x = matrix.a * point.x + matrix.b * point.y + matrix.tx;
		var y = matrix.c * point.x + matrix.d * point.y + matrix.ty;
		// in case point == outPoint
		out.x = x;
		out.y = y;
		return out;
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
			poll_for_press = StageTimer.addCallback(() -> {
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
			});
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
	getAssistId: (char) -> {
		var assist = char.getPlayerConfig().assist;
		return assist.namespace + "::" + assist.resourceId + "." + assist.contentId;
	},
};

var StageGlobals = {
	// Append to this list for entities that are part of the stage, used
	// to differentiate between game entities and spawned ones
	entities: [],
	assists: [],
};

// Tools for running callbacks on every frame! Call tick() every frame, and dependencies can hook into this call using this class
// Depends: match
var StageTimer = {
	// init: () -> match.addEventListener(MatchEvent.TICK_START, StageTimer._tick, {persistent: true}),
	init: () -> {},
	addCallback: (cb) -> StageTimer._callbacks.contains(cb) ? cb : StageTimer._callbacks[StageTimer._callbacks.push(cb) - 1],
	removeCallback: (cb) -> StageTimer._callbacks.remove(cb),
	/// Private
	_tick: () -> {
		for (cb in StageTimer._callbacks)
			cb();
	},
	_callbacks: [],
};

// Draw collision (hurt, hit, grab, etc.) boxes as vfx w/ different colours. Simply initialize w/ blacklist of entities to not render
// Depends: StageTimer, match
var CollisionBoxRenderer = {
	BOX_TYPES: [
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
	],
	init: function(?blacklist, ?assists) {
		StageTimer.addCallback(CollisionBoxRenderer._renderLoop);
		// match.addEventListener(MatchEvent.TICK_END, CollisionBoxRenderer._renderLoop, {persistent: true});
		// Don't render hurtboxes by default
		if (blacklist != null) {
			CollisionBoxRenderer._blacklist = blacklist;
		}
		if (assists != null) {
			CollisionBoxRenderer._assists = assists;
		}
		CollisionBoxRenderer.toggleRender(CollisionBoxType.HURT);
	},
	toggleRender: (boxType) -> {
		CollisionBoxRenderer._boxTypeRenderMap.set(boxType, !CollisionBoxRenderer._shouldRender(boxType));
		return true;
	},
	/// Private
	_assists: [],
	_blacklist: [],
	_boxTypeRenderMap: new IntMap(), // if false
	_shouldRender: (boxType) -> (!CollisionBoxRenderer._boxTypeRenderMap.exists(boxType)
		|| CollisionBoxRenderer._boxTypeRenderMap.get(boxType)),
	_renderLoop: () -> {
		CollisionBoxRenderer._showBoxesFor(match.getCharacters());
		CollisionBoxRenderer._showBoxesFor(match.getProjectiles());
		CollisionBoxRenderer._showBoxesFor(CollisionBoxRenderer._assists);
	},
	_obj_cache: {
		entity_scale: new Point(0, 0),
		entity_pos: new Point(0, 0),
		entity_pivot: new Point(0, 0),
		fixed_box_pos: new Point(0, 0),
		fixed_box_center: new Point(0, 0),
		vfx_stats: new VfxStats({
			spriteContent: self.getResource().getContent("boxviewerVfx"),
			animation: "display_box",
			layer: "front",
			timeout: 1
		}),
	},
	_updateEntityStats: function(entity:Entity) {
		var entity_scale = CollisionBoxRenderer._obj_cache.entity_scale;
		entity_scale.x = entity.getGameObjectStat("baseScaleX");
		entity_scale.y = entity.getGameObjectStat("baseScaleY");
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

		var should_apply_vel = (entity.getHitstop() == 0);
		var entity_pos = CollisionBoxRenderer._obj_cache.entity_pos;
		entity_pos.x = entity.getX() + should_apply_vel * entity.getNetXVelocity();
		entity_pos.y = entity.getY() + should_apply_vel * entity.getNetYVelocity();
		var entity_pivot = CollisionBoxRenderer._obj_cache.entity_pivot;
		entity_pivot.x = entity.getPivotXScaled() + entity_pos.x;
		entity_pivot.y = entity.getPivotYScaled() + entity_pos.y;
	},
	_calculateVfxStats: function(cbox:CollisionBox, entity:Entity) {
		// Returns a collision box but fixes x/y values to absolute accounting for rotation around
		// pivot points etc.
		// NOTE: Recalculating a lot of things that could've been determined using "relativeWith/flipWith/resizeWith"
		//       this means that if the entity is flipped, moved, resized *during* the frame, this won't be reflected
		// NOTE: Also accounting for game physics here since this is calculated before it applies to positions
		// NOTE: Most the complicated calculations (in Util) are typically no-ops since entities/boxes are not rotated

		var box_center = Util.getTrueCenter(
			cbox, CollisionBoxRenderer._obj_cache.fixed_box_center // output point
		);
		var entity_scale = CollisionBoxRenderer._obj_cache.entity_scale;
		var entity_pos = CollisionBoxRenderer._obj_cache.entity_pos;
		var entity_pivot = CollisionBoxRenderer._obj_cache.entity_pivot;
		var rotation = cbox.rotation;
		if (entity.isFacingLeft())
			rotation = Math.flipAngleOverXAxis(cbox.rotation);
		var flipper = entity.isFacingRight() ? 1 : -1;
		var fixed_box_pos = CollisionBoxRenderer._obj_cache.fixed_box_pos;
		fixed_box_pos.x = flipper * box_center.x + entity_pos.x;
		fixed_box_pos.y = box_center.y + entity_pos.y;
		// Rotate this point about the *entity* pivot point
		var entity_rotation = cbox.type != CollisionBoxType.LEDGEGRAB ? entity.getRotation() : 0;
		// NOTE: most of the time this function is a no-op
		fixed_box_pos = Util.transformPointAroundPivot(fixed_box_pos, entity_pivot, entity_rotation, entity_scale);
		var vfx_stats = CollisionBoxRenderer._obj_cache.vfx_stats;
		vfx_stats.x = fixed_box_pos.x;
		vfx_stats.y = fixed_box_pos.y;
		vfx_stats.scaleX = (cbox.width * entity_scale.x) / 100;
		vfx_stats.scaleY = (cbox.height * entity_scale.y) / 100;
		vfx_stats.rotation = entity_rotation + rotation;
		return vfx_stats;
	},
	_displayBox: function(cbox:CollisionBox, entity:Entity) {
		var vfx:Vfx = match.createVfx(CollisionBoxRenderer._calculateVfxStats(cbox, entity));
		vfx.playFrame(switch (cbox.type) {
			case CollisionBoxType.HIT: FRAME_COLORS.RED;
			case CollisionBoxType.HURT: FRAME_COLORS.YELLOW;
			case CollisionBoxType.GRAB: FRAME_COLORS.BLUE;
			case CollisionBoxType.LEDGEGRAB: FRAME_COLORS.CYAN;
			case CollisionBoxType.REFLECT: FRAME_COLORS.GREEN;
			case CollisionBoxType.ABSORB: FRAME_COLORS.BLUE_GREEN;
			case CollisionBoxType.COUNTER: FRAME_COLORS.YELLOW_GREEN;
			case CollisionBoxType.SHIELD: FRAME_COLORS.CYAN;
			case CollisionBoxType.CUSTOMA: FRAME_COLORS.PURPLE;
			case CollisionBoxType.CUSTOMB: FRAME_COLORS.RED_PURPLE;
			case CollisionBoxType.CUSTOMC: FRAME_COLORS.ROSE_PINK;
			default: FRAME_COLORS.ORANGE;
		});
	},
	_dumpInfo: function(cbox:CollisionBox, entity:Entity) {},
	_showBoxesFor: (entities) -> {
		for (entity in entities) {
			if (CollisionBoxRenderer._blacklist.contains(entity))
				continue;
			CollisionBoxRenderer._updateEntityStats(entity);
			for (boxType in CollisionBoxRenderer.BOX_TYPES) {
				if (!CollisionBoxRenderer._shouldRender(boxType))
					continue;
				var boxes = entity.getCollisionBoxes(boxType);
				if (boxes == null)
					continue;
				for (cbox in boxes) {
					CollisionBoxRenderer._displayBox(cbox, entity);
					// CollisionBoxRenderer._dumpInfo(cbox, entity);
				}
			}
		}
	},
};

// Draw ECBs. Simply initialize w/ blacklist of entities to not render
// Depends: StageTimer, match
var EcbRenderer = {
	ECB_POINT_TYPES: ["head", "left_hip", "foot", "right_hip"],
	init: function(?blacklist, ?assists) {
		StageTimer.addCallback(EcbRenderer._renderLoop);
		if (blacklist != null) {
			EcbRenderer._blacklist = blacklist;
		}
		EcbRenderer._assists = assists;
	},
	toggleAll: () -> {
		EcbRenderer.toggleEntityType(EntityType.CHARACTER);
		EcbRenderer.toggleEntityType(EntityType.PROJECTILE);
		EcbRenderer.toggleEntityType(EntityType.CUSTOM_GAME_OBJECT);
		return true;
	},
	toggleEntityType: (entity_type) -> {
		var allowed_types = EcbRenderer._allowed_entity_types;
		if (allowed_types.contains(entity_type)) {
			allowed_types.remove(entity_type);
		} else {
			allowed_types.push(entity_type);
		}
		return true;
	},
	/// Private
	_blacklist: [],
	_assists: null,
	_allowed_entity_types: [],
	_cached_ecb_points: [
		"head" => new Point(0, 0),
		"left_hip" => new Point(0, 0),
		"foot" => new Point(0, 0),
		"right_hip" => new Point(0, 0),
	],
	_cached_point_vfx_stats: new VfxStats({
		spriteContent: self.getResource().getContent("boxviewerVfx"),
		animation: "ecb_indicators",
		layer: "front",
		timeout: 1,
	}),
	_cached_line_vfx_stats: new VfxStats({
		spriteContent: self.getResource().getContent("boxviewerVfx"),
		animation: "display_line",
		layer: "front",
		timeout: 1,
	}),
	_renderLoop: function() {
		if (EcbRenderer._allowed_entity_types.contains(EntityType.CHARACTER))
			EcbRenderer._showEcbsFor(match.getCharacters());
		if (EcbRenderer._allowed_entity_types.contains(EntityType.PROJECTILE))
			EcbRenderer._showEcbsFor(match.getProjectiles());
		if (EcbRenderer._allowed_entity_types.contains(EntityType.CUSTOM_GAME_OBJECT))
			EcbRenderer._showEcbsFor(EcbRenderer._assists);
	},
	_showEcbsFor: (entities) -> {
		if (entities == null)
			return;
		for (entity in entities) {
			if (EcbRenderer._blacklist.contains(entity))
				continue;
			EcbRenderer._displayEcb(entity);
			// EcbRenderer._dumpInfo(entity);
		}
	},
	_displayEcb: function(entity:Entity) {
		var entity_x = entity.getX() + entity.getNetXVelocity();
		var entity_y = entity.getY() + entity.getNetYVelocity();
		var line_vfx_stats = EcbRenderer._cached_line_vfx_stats;
		line_vfx_stats.animation = "display_line";
		var renderLine = (point1, point2) -> {
			// draw line between curr point and prev point
			line_vfx_stats.x = Util.average(point1.x, point2.x) + entity_x;
			line_vfx_stats.y = Util.average(point1.y, point2.y) + entity_y;
			line_vfx_stats.scaleX = Math.getDistance(point1, point2) / 100;
			line_vfx_stats.rotation = Math.flipAngleOverYAxis(Math.getAngleBetween(point1, point2));
			var line_vfx:Vfx = match.createVfx(line_vfx_stats);
			line_vfx.playFrame(FRAME_COLORS.ORANGE);
		};
		// TODO: Could render once and move vfx around ...
		var ecb_point = EcbRenderer._cached_ecb_points["head"];
		ecb_point.x = entity.getEcbHeadX();
		ecb_point.y = entity.getEcbHeadY();
		ecb_point = EcbRenderer._cached_ecb_points["left_hip"];
		ecb_point.x = entity.getEcbLeftHipX();
		ecb_point.y = entity.getEcbLeftHipY();
		ecb_point = EcbRenderer._cached_ecb_points["foot"];
		ecb_point.x = entity.getEcbFootX();
		ecb_point.y = entity.getEcbFootY();
		ecb_point = EcbRenderer._cached_ecb_points["right_hip"];
		ecb_point.x = entity.getEcbRightHipX();
		ecb_point.y = entity.getEcbRightHipY();
		var point_vfx_stats = EcbRenderer._cached_point_vfx_stats;
		var last_point = null;
		for (ecb_point_type in EcbRenderer.ECB_POINT_TYPES) {
			var ecb_point = EcbRenderer._cached_ecb_points[ecb_point_type];
			point_vfx_stats.x = ecb_point.x + entity_x;
			point_vfx_stats.y = ecb_point.y + entity_y;
			var point_vfx:Vfx = match.createVfx(point_vfx_stats);
			point_vfx.playFrameLabel(ecb_point_type);
			if (last_point != null) {
				renderLine(ecb_point, last_point);
			}
			last_point = ecb_point;
		}
		renderLine(last_point, EcbRenderer._cached_ecb_points[EcbRenderer.ECB_POINT_TYPES[0]]);
	},
	_dumpInfo: function(entity:Entity) {},
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
		Engine.log("num_frames =" + HitboxTracker._frame);
		printAllHitboxData(HitboxTracker._hitbox_info);
		return;
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
		var char:Character = SlowDownHandler._char;
		if (SlowDownHandler._slow_amount > 0 && char != null) {
			if (char.inStateGroup(CStateGroup.ATTACK) || char.inState(CState.GRAB))
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
// Depends: StageTimer, Util, match
var ButtonHandler = {
	BUTTONS: [
		"SPECIAL",
		"HURT",
		"HIT",
		"STAGE",
		"ATT_SLOW",
		"ATT_FLOAT",
		"ECB",
		"TURRET",
		"ASSIST",
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
		"ECB" => {
			position: [Util.average(-245, -99), -319],
			default_anim: "off",
		},
		"TURRET" => {
			position: [Util.average(-60, 82), -319],
			default_anim: "off",
		},
		"ASSIST" => {
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
	getButtonObjects: () -> ButtonHandler._buttons,
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
			spriteContent: self.getResource().getContent("boxviewerVfx"),
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
		var onPressed = function(e:GameObjectEvent) {
			// Ignore hitboxes that wouldn't flinch anyways
			var hitbox = e.data.hitboxStats;
			if (b.getGameObjectStatsMetadata().lastToggledBy == hitbox.attackId)
				return;
			if (!hitbox.flinch)
				return;
			b.updateGameObjectStatsMetadata({lastToggledBy: hitbox.attackId});

			Engine.log("Toggling " + name + " button");
			AudioClip.play(GlobalSfx.STRONG_CLICK);
			var char = e.data.foe.getRootOwner();
			if (char == null || char != Util.getP1())
				return;
			if (toggle_handler()) {
				var isOn = (b.getAnimation() == "on");
				var toggleAnim = isOn ? "off" : "on";
				b.playAnimation(toggleAnim);
			}
		};
		b.addEventListener(GameObjectEvent.COUNTER, onPressed, {persistent: true});
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
		camera.getBackgroundContainers()[1].visible = StageVisibilityHandler._visible;
		for (cb in StageVisibilityHandler._callbacks) {
			cb(StageVisibilityHandler._visible);
		}
		return true;
	},
	isVisible: () -> StageTimer._visible,
	addCallback: (cb) -> StageVisibilityHandler._callbacks.push(cb),
	/// private
	_visible: true,
	_callbacks: [],
};

// Manage moving platform that moves P1 between the different stage regions
// Depends: StageTimer, Util
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
			spriteContent: self.getResource().getContent("boxviewerVfx"),
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
					} else if (other_char.inStateGroup(CStateGroup.HURT_HEAVY) || other_char.inState(CState.HELD)) {
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

// When enabled, spawn assists as custom game objects. Entity will be removed from list when disposed and added when spawned.
// NOTE: getting custom game objects manually doesn't work, and custom game object list also errors until both custom game object & assist has been spawned?
//       Using this method ensures the data is always shown
var AssistHandler = {
	init: function(?assist_list) {
		AssistHandler._assists = assist_list;
		StageTimer.addCallback(AssistHandler._tick);
		match.addEventListener(AssistEvent.CHARGED, (e) -> {
			AssistHandler._setAssistCharge(e.data.character);
		}, {persistent: true});
	},
	toggle: function() {
		AssistHandler._enabled = !AssistHandler._enabled;
		if (AssistHandler._enabled) {
			for (char in match.getCharacters()) {
				if (char.getAssistCharge() == 1)
					AssistHandler._setAssistCharge(char);
				AssistHandler._input_listeners.push(Util.onButtonsHeld(char, Buttons.ACTION, () -> {
					AssistHandler._handleInput(char);
				}, true));
			}
		} else {
			// Restore assist charge
			for (char in match.getCharacters()) {
				var char_meta = char.getGameObjectStatsMetadata();
				if (char_meta != null && char_meta.bv_hasAssistCharge)
					char.setAssistCharge(1);
			}
			for (listener in AssistHandler._input_listeners) {
				StageTimer.removeCallback(listener);
			}
		}
		return true;
	},
	///private
	_assists: null,
	_input_listeners: [],
	_enabled: false,
	_assist_box: null,
	_tick: () -> {
		if (!AssistHandler._enabled)
			return;
		for (char in match.getCharacters()) {
			var char_meta = char.getGameObjectStatsMetadata();
			if (char_meta != null && char_meta.bv_hasAssistCharge) {
				char.setAssistCharge(0);
			}
		}
	},
	_handleInput: (char) -> {
		var char_meta = char.getGameObjectStatsMetadata();
		if (char_meta == null || !char_meta.bv_hasAssistCharge)
			return;
		// If can't use assist, ignore input (no buffer or iasa/etc ;-;)
		if (char.inHurtState() || char.inStateGroup(CStateGroup.ATTACK) || char.inStateGroup(CStateGroup.GRAB))
			return;
		char.toState(CState.ASSIST_CALL);
		var assist_obj = match.createCustomGameObject(Util.getAssistId(char), char);
		if (AssistHandler._assists != null)
			AssistHandler._assists.push(assist_obj);
		AssistHandler._listenForDispose(assist_obj);
		char.updateGameObjectStatsMetadata({bv_hasAssistCharge: false});
		AssistHandler._assist_box.removeChild(char.getDamageCounterAssistSprite());
		AssistHandler._assist_box.dispose();
	},
	_setAssistCharge: (char) -> {
		// set assist charge manually!
		if (!AssistHandler._enabled)
			return;
		var char_meta = char.getGameObjectStatsMetadata();
		// Set the metadata to a non-null value so game doesn't crash
		if (char_meta == null)
			char.updateGameObjectStats({metadata: {}});
		char.updateGameObjectStatsMetadata({bv_hasAssistCharge: true});
		var assist_box = Container.create();
		assist_box.addChild(char.getDamageCounterAssistSprite());
		char.getDamageCounterContainer().addChild(assist_box);
		assist_box.x = 108;
		assist_box.y = 13;
		AssistHandler._assist_box = assist_box;
	},
	_listenForDispose: (assist_obj) -> {
		if (AssistHandler._assists == null)
			return;
		// Should not fire if pressed this frame.
		// TODO: This should probably be an option
		var poll_for_disposed;
		poll_for_disposed = StageTimer.addCallback(() -> {
			if (assist_obj.isDisposed()) {
				AssistHandler._assists.remove(assist_obj);
				StageTimer.removeCallback(assist_obj);
			}
		});
	},
};

var TurretHandler = {
	// relative to bottom right corner
	START_X: -742 + 10,
	START_Y: 838 - 50,
	init: function(?entity_list) {
		var turret = match.createProjectile(self.getResource().getContent("boxviewerTurret"));
		turret.setX(TurretHandler.START_X);
		turret.setY(TurretHandler.START_Y);
		TurretHandler._turret = turret;
		if (entity_list != null)
			entity_list.push(turret);
	},
	getTurret: () -> TurretHandler._turret,
	toggleMode: () -> {
		TurretHandler._turret.exports.toggleMode();
		return true;
	},
	setVisible: (visible) -> {
		TurretHandler._turret.setVisible(visible);
	},
	/// private
	_turret: null,
};

function initialize() {
	self.exports = {
		exception_list: StageGlobals.entities
	};

	ButtonHandler.init([
		"HURT" => () -> CollisionBoxRenderer.toggleRender(CollisionBoxType.HURT),
		"HIT" => () -> CollisionBoxRenderer.toggleRender(CollisionBoxType.HIT),
		"SPECIAL" => () -> {
			for (boxType in CollisionBoxRenderer.BOX_TYPES) {
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
		"ECB" => EcbRenderer.toggleAll,
		"TURRET" => TurretHandler.toggleMode,
		"ASSIST" => AssistHandler.toggle,
	]);
	for (button in ButtonHandler.getButtonObjects()) {
		StageGlobals.entities.push(button);
	}

	StageVisibilityHandler.init();
	StageTimer.init();
	CollisionBoxRenderer.init(StageGlobals.entities, StageGlobals.assists);
	EcbRenderer.init(StageGlobals.entities, StageGlobals.assists);
	SlowDownHandler.init();
	FloatHandler.init();
	ElevatorHandler.init();
	CameraViewHelper.init();
	AssistHandler.init(StageGlobals.assists);
	TurretHandler.init(StageGlobals.entities);
	StageVisibilityHandler.addCallback(TurretHandler.setVisible);
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
// - no call to get assists and getCustomGameObjects is broken

// Playtesters: Nuova, Sky, Lood, Exo, Peace, Salt, Kactus
// TODO (post-release):
// ===== Tier 1 (Functional) =====
// - [x] display for when assist is charged when handled by stage
// - [x] ECB display
// - [x] add grid to BG? or BG parallax idk
//     - [ ] should have reference for stage widths
//     - see: MVS (https://multiversus.fandom.com/wiki/Training_Room?file=Training.png), Ultiamte (https://ssb.wiki.gallery/images/1/14/Training_stage.jpg)
// - [ ] body armour display
//
// ===== Tier 2 (Usability) =====
// - [x] performance
//     - Some attempts were made, but improvements weren't anything crazy. No clear room for improvement left ..
// - [/] Cooldown between button presses
// - [x] disabled buttons
// - [ ] hazard variant is just FD? Or some other differences
//      - move between variants using options maybe on regular?
//      - Need to figure out how to handle teleport plat on all variants tho.
//      - or just elevator ease riding
//
// ===== Tier 3 (Other) =====
// - [x] Force buttons to position (so they can't be moved)
// - [ ] correlate w/ hitbox stats (and display)
// - [ ] boxes on menu image o.O
// - [x] Implement UNKOWN Buttons
// - [ ] hide character
// - [/] video for all GlobalVfx/Sfx
// - [x] Ability to test counters/reflectors/absorbers
// Options Redesign:
// Standing on the options platform spawns a fullscreen menu.
// Menu options:
// - stage layout (fd, bf, rivals training, ult training)
//     - if using a normal stage, options will open on revive?
//     - should consider an alternate imput as well and have that as optional
//     - Otherwise there'll a platform for it (button or time on plat?)
// - boxes to enable/disable (collision box types & ecb)
// - hide stage/character/projectiles
// - assists (enable handling, instant charge)
// - slowdown (amount, on attack? constant?)
// - framedata
// - input display
// - character stats
// - training mode features:
//     - hitstun display, body armour display
// Design:
// - pages for top level
//    - can move between sections of page
//    - press attack to select/unselect, special/shield to go back
