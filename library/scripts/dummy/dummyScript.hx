// Main script
// This dummy is just an invisible hurtbox so that hitboxes can "connect" with it

var CAMERA_X = stage.getDeathBounds().getX();
var CAMERA_Y = stage.getDeathBounds().getY();
var CAMERA_WIDTH = stage.getDeathBounds().getRectangle().width;
var CAMERA_HEIGHT = stage.getDeathBounds().getRectangle().height;

function initialize() {
	Engine.log("Spawned hitbox listener!");
	self.setAlpha(0);
	self.setScaleX(CAMERA_WIDTH / 100);
	self.setScaleY(CAMERA_HEIGHT / 100);
	Engine.log("dummy owner is self? " + (self.getOwner() == self));
}

function update() {
	self.updateAnimationStats({bodyStatus: BodyStatus.INTANGIBLE});
	self.setX(CAMERA_X);
	self.setY(CAMERA_Y);
}
