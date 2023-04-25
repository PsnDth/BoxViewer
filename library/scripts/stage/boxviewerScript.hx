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
        // TODO: Should simplify this math, fairly expensive as written
        // cbox.centerX, cbox.centerY will lie if there is rotation applied
        // the real center should account for rotation
        var p_center = new Point(cbox.centerX, cbox.centerY);
        if (cbox.rotation == 0)
            return p_center;
        var p = new Point(cbox.x, cbox.y);
        var pivot = new Point(cbox.pivotX, cbox.pivotY);
        // rotate back
        var orig_p = Util.rotatePointAroundPivot(p, pivot, -cbox.rotation);
        var sub_p = p.clone();
        sub_p.scale(-1, -1);
        var vec2center = p_center.add(sub_p);
        var orig_center = orig_p.add(vec2center);
        return Util.rotatePointAroundPivot(orig_center, pivot, cbox.rotation);
    },
    rotatePointAroundPivot: function(point:Point, pivot:Point, angle:Float) {
        var degrees = Math.forceBase360(angle);
        if (degrees == 0)
            return point;

        var translated_point = new Point(point.x - pivot.x, point.y - pivot.y);
        return new Point(Math.fastCos(degrees) * translated_point.x
            - Math.fastSin(degrees) * translated_point.y
            + pivot.x,
            Math.fastSin(degrees) * translated_point.x
            + Math.fastCos(degrees) * translated_point.y
            + pivot.y);
        },
        transformPointAroundPivot: function(point:Point, pivot:Point, rotation:Float, scale:Point) {
            var degrees = Math.forceBase360(rotation);
            if (degrees == 0 && scale.x == 1 && scale.y == 1)
                return point;
            var translated_point = new Point(point.x - pivot.x, point.y - pivot.y);
            translated_point.scale(scale.x, scale.y);
            return new Point(Math.fastCos(degrees) * translated_point.x
                - Math.fastSin(degrees) * translated_point.y
                + pivot.x,
                Math.fastSin(degrees) * translated_point.x
                + Math.fastCos(degrees) * translated_point.y
                + pivot.y);
    },
    average: (num1, num2) -> (num1 + num2) / 2,
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
    addCallback: (cb) -> StageTimer._callbacks.contains(cb) ? StageTimer._callbacks.length : StageTimer._callbacks.push(cb),
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
// TODO: Add more toggles
var CollisionBoxRenderer = {
    init: function() {
        StageTimer.addCallback(CollisionBoxRenderer._renderLoop);
        // match.addEventListener(MatchEvent.TICK_END, CollisionBoxRenderer._renderLoop, {persistent: true});
    },
    toggleRender: (boxType) -> CollisionBoxRenderer._boxTypeRenderMap.set(boxType, !CollisionBoxRenderer._shouldRender(boxType)),
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

        var should_apply_vel = (entity.getHitstop() == 0);
        var entity_pos = new Point(entity.getX() + should_apply_vel * entity.getNetXVelocity(), entity.getY() + should_apply_vel * entity.getNetYVelocity());
        var entity_pivot = new Point(entity.getPivotXScaled() + entity_pos.x, entity.getPivotYScaled() + entity_pos.y);
        // TODO: Should these points be scaled?
        // var box_start = new Point(cbox.centerX, cbox.centerY);
        // var box_pivot = new Point(cbox.pivotY, cbox.pivotY);
        // var box_center = Util.rotatePointAroundPivot(box_start, box_pivot, cbox.rotation);
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
        if (entity.getType() == EntityType.CUSTOM_GAME_OBJECT && cbox.type == CollisionBoxType.HURT)
            return;
        var fixed_box = CollisionBoxRenderer._fixBox(cbox, entity);
        var vfx:Vfx = match.createVfx(new VfxStats({
            spriteContent: self.getResource().getContent("box"),
            animation: "display_box",
            // Need to account for speed since this information is for the *next* frame
            // x: cbox.centerX + (entity.isFacingRight() ? 1 : -1)*entity.getNetXVelocity(),
            // y: cbox.centerY + entity.getNetYVelocity(),
            x: fixed_box.x,
            y: fixed_box.y,
            scaleX: fixed_box.width / 100,
            scaleY: fixed_box.height / 100,
            rotation: fixed_box.rotation,
            layer: "front",
            fadeOut: false,
            shrink: false,
            // physics: true,
            loop: false,
            timeout: 1,
            smoothing: true,
        }));
        vfx.setAlpha((cbox.type == CollisionBoxType.HURT) ? 0.5 : 0.7);
        var color_filter:HsbcColorFilter = new HsbcColorFilter();
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
    init: () -> {
        StageTimer.addCallback(SlowDownHandler._tick);
    },
    toggleSlow: () -> {
        SlowDownHandler._shouldSlow = !SlowDownHandler._shouldSlow;
    },
    // Private
    _char: null,
    _char_initialized: false,
    _shouldSlow: false,
    _tick: () -> {
        if (!SlowDownHandler._char_initialized) {
            SlowDownHandler._char = Util.getP1();
            SlowDownHandler._char_initialized = true;
        }
        if (SlowDownHandler._shouldSlow && SlowDownHandler._char != null) {
            if (SlowDownHandler._char.inStateGroup(CStateGroup.ATTACK))
                match.freezeScreen(5, []);
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
// Depends: StageTimer, StageGlobals, Util
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
            default_anim: "on",
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
            var empty_handler = () -> {};
            ButtonHandler._spawn_button(name, _toggle_handlers.exists(name) ? _toggle_handlers.get(name) : empty_handler);
        }
    },
    // private
    _buttons: [],
    _spawn_button: function(name, toggle_handler) {
        var button_stats = ButtonHandler.BUTTON_STATS[name];
        var b:Projectile = match.createProjectile(self.getResource().getContent("boxviewerButton"));
        b.playAnimation(button_stats.default_anim);
        b.setX(button_stats.position[0]);
        b.setY(button_stats.position[1] + ButtonHandler.BUTTON_Y_OFFSET);
        b.addEventListener(GameObjectEvent.HIT_RECEIVED, function(e:GameObjectEvent) {
            // Ignore hitboxes that wouldn't flinch anyways
            var hitbox = e.data.hitboxStats;
            if (hitbox.flinch == false) return;

            Engine.log("Toggling " + name + " button");
            AudioClip.play(GlobalSfx.STRONG_CLICK);
            var char = e.data.foe.getRootOwner();
            if (char == null || char.getType() != EntityType.CHARACTER)
                return;

            var isOn = (b.getAnimation() == "on");
            var toggleAnim = isOn ? "off" : "on";
            b.playAnimation(toggleAnim);
            toggle_handler();
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
    },
    _visible: true,
};

// Manage moving platform that moves P1 between the different stage regions
// Depends: StageTimer, StageGlobals, Util
var ElevatorHandler = {
    WAIT_TIME: 300,
    MAX_Y: -977.5,
    MOVE_SPEED: -7.5,
    init: () -> {
        ElevatorHandler._platform = match.createStructure(self.getResource().getContent("boxviewerElevator"));
        StageTimer.addCallback(ElevatorHandler._tick);
    },
    getElevator: () -> ElevatorHandler._platform,
    // private
    _platform: null,
    _wait_timer: -1,
    _hasPassengers: () -> {
        var char:Character = Util.getP1();
        if (char == null)
            return false;
        return (char.getCurrentFloor() == ElevatorHandler._platform);
    },
    _tick: () -> {
        var plat:Structure = ElevatorHandler._platform;
        // when character on plat mvoe up
        if (ElevatorHandler._hasPassengers()) {
            plat.setY(Math.max(ElevatorHandler.MAX_Y, plat.getY() + ElevatorHandler.MOVE_SPEED));
        }
        // when character not on plat, wait a bit, then teleport back to start position
        else if (plat.getY() != plat.getStructureStat("startY")) {
            if (ElevatorHandler._wait_timer < 0) {
                ElevatorHandler._wait_timer = ElevatorHandler.WAIT_TIME;
            }
            ElevatorHandler._wait_timer--;
            if (ElevatorHandler._wait_timer < 0) {
                plat.setY(plat.getStructureStat("startY"));
            }
        }
    },
};

// Helps to ensure the camera view is sane.
// Prioritizes P1 in tricky situations otherwise teleport other players to where P1 is.
//
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
            Engine.log("ERROR: No elevator plat found", 0xFF0000);
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
        }
        else if (CameraViewHelper._isInRegion("ELEVATOR", char)) {
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
            Engine.log("ERROR: Using default region because can't place char ... (x:" + char.getX() + ", y:" + char.getY() + ")", 0xFF0000);
        }
        // Default to main region
        return "MAIN";
    },
    _isInRegion: (region, char) -> {
        if (region == null || char == null) return false;
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
        },
        "STAGE" => StageVisibilityHandler.toggleVisibility,
        "ATT_SLOW" => SlowDownHandler.toggleSlow,
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

// Playtesters: Nuova, Sky, Lood, Exo, Peace

// TODO (post-release):
// - disabled buttons
// - empty custom game object to workaround getCustomGameObjects() bug
// - ECB display
// - elevator ease rising?
// - add grid to BG? or BG parallax idk
// - boxes on menu image o.O
// - correlate w/ hitbox stats (and display)
// - performance
// - buttons should be intangible probably
