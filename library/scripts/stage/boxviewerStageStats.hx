// Stats for Template Stage
{
	spriteContent: self.getResource().getContent("boxviewer"),
	animationId: "stage",
	ambientColor: 0x20fd8eff,
	shadowLayers: [
		{
			id: "0",
			maskSpriteContent: self.getResource().getContent("boxviewer"),
			maskAnimationId: "shadowMaskFront",
			color: 0x40000000,
			foreground: true
		},
		{
			id: "1",
			maskSpriteContent: self.getResource().getContent("boxviewer"),
			maskAnimationId: "shadowMask",
			color: 0x40000000,
			foreground: false
		}
	],
	camera: {
		startX: 0,
		startY: 43,
		zoomX: 0,
		zoomY: 0,
		camEaseRate: 1 / 11,
		camZoomRate: 1 / 15,
		minZoomHeight: 360,
		initialHeight: 360,
		initialWidth: 640,
		backgrounds: [
			// TODO: Should robably add some parallax to the BG!
			{
				spriteContent: self.getResource().getContent("boxviewer"),
				animationId: "static_bg",
				mode: ParallaxMode.BOUNDS,
				originalBGWidth: 1900,
				originalBGHeight: 3550,
				horizontalScroll: true,
				verticalScroll: true,
				loopWidth: 0,
				loopHeight: 0,
				xPanMultiplier: 0.06,
				yPanMultiplier: 0.06,
				scaleMultiplier: 1,
				foreground: false,
				depth: 2001
			},
		]
	}
}
