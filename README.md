Fraymakers Box Viewer
=====================
Stage to display any collision boxes including hurtboxes and hitboxes.

Also includes some features for improving testing and experimentation.

Known Issues
------------
* Sometimes boxes seem "shifted" from where they should be
    * Seems like entities can change their physics after the box data is collected, and there isn't a way (afaik) to hook into after that. The shape of the boxes cannot change so that part remains valid
* The entity's scale is not accounted for
    * Fix is WIP
* Assists are not supported
    * Seems to be an API issue, but may be able to workaround, will revisit

Planned Improvement Areas
-------------------------
* Windboxes should not interact with buttons
* FD area is too generous
* Buttons should be intangible (for smw mario)