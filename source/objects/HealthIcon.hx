package objects;

import flixel.graphics.FlxGraphic;
import openfl.display.BitmapData;
import openfl.utils.Assets as OpenFlAssets;
#if MODS_ALLOWED
import sys.FileSystem;
#end

@:access(openfl.display.BitmapData)
class HealthIcon extends FlxSprite
{
	public var sprTracker:FlxSprite;
	private var isPlayer:Bool = false;
	private var char:String = '';

	public function new(char:String = 'face', isPlayer:Bool = false, ?allowGPU:Bool = true)
	{
		super();
		this.isPlayer = isPlayer;
		changeIcon(char, allowGPU);
		scrollFactor.set();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (sprTracker != null)
			setPosition(sprTracker.x + sprTracker.width + 12, sprTracker.y - 30);
	}

	private function findIconPath(char:String):String
	{
		var candidates:Array<String> = [
			'icons/' + char,          
			'icons/icon-' + char,     //Older versions of psych engine's support
			'icons/icon-face'         //Prevents crash from missing icon
		];

		#if MODS_ALLOWED
		for (name in candidates)
		{
			var modPath:String = Paths.modFolders('images/' + name + '.png');
			if (FileSystem.exists(modPath)) return modPath;
		}
		#end

		for (name in candidates)
		{
			if (Paths.fileExists('images/' + name + '.png', IMAGE, true))
				return Paths.getPath('images/' + name + '.png', IMAGE);
		}
		return null;
	}

	private function loadIconGraphic(path:String, ?allowGPU:Bool = true):FlxGraphic
	{
		if (path == null) return null;

		if (Paths.currentTrackedAssets.exists(path))
		{
			Paths.localTrackedAssets.push(path);
			return Paths.currentTrackedAssets.get(path);
		}

		var bitmap:BitmapData = null;
		#if MODS_ALLOWED
		if (FileSystem.exists(path))
			bitmap = BitmapData.fromFile(path);
		else
		#end
		if (OpenFlAssets.exists(path, IMAGE))
			bitmap = OpenFlAssets.getBitmapData(path);

		if (bitmap == null) return null;

		if (allowGPU && ClientPrefs.data.cacheOnGPU && bitmap.image != null)
		{
			bitmap.lock();
			if (bitmap.__texture == null)
			{
				bitmap.image.premultiplied = true;
				bitmap.getTexture(FlxG.stage.context3D);
			}
			bitmap.getSurface();
			bitmap.disposeImage();
			bitmap.image.data = null;
			bitmap.image = null;
			bitmap.readable = true;
		}

		var graph:FlxGraphic = FlxGraphic.fromBitmapData(bitmap, false, path);
		graph.persist = true;
		graph.destroyOnNoUse = false;

		Paths.currentTrackedAssets.set(path, graph);
		Paths.localTrackedAssets.push(path);
		return graph;
	}

	private var iconOffsets:Array<Float> = [0, 0];
	public function changeIcon(char:String, ?allowGPU:Bool = true) {
		if(this.char != char) {
			var graphic = loadIconGraphic(findIconPath(char), allowGPU);
			if(graphic == null) graphic = Paths.image('icons/icon-face', allowGPU); //Prevents crash from missing icon

			var iSize:Float = Math.round(graphic.width / graphic.height);
			loadGraphic(graphic, true, Math.floor(graphic.width / iSize), Math.floor(graphic.height));
			iconOffsets[0] = (width - 150) / iSize;
			iconOffsets[1] = (height - 150) / iSize;
			updateHitbox();

			animation.add(char, [for(i in 0...frames.frames.length) i], 0, false, isPlayer);
			animation.play(char);
			this.char = char;

			if(char.endsWith('-pixel'))
				antialiasing = false;
			else
				antialiasing = ClientPrefs.data.antialiasing;
		}
	}

	public var autoAdjustOffset:Bool = true;
	override function updateHitbox()
	{
		super.updateHitbox();
		if(autoAdjustOffset)
		{
			offset.x = iconOffsets[0];
			offset.y = iconOffsets[1];
		}
	}

	public function getCharacter():String {
		return char;
	}
}
