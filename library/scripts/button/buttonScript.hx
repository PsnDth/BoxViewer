
function initialize() {
    // NOTE: Can't do this from the stage side. I assume because the container will change to the parent
    stage.getCharactersBackContainer().addChild(self.getViewRootContainer());
}