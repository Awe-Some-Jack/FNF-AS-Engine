package flixel.system.ui;

import openfl.display.Sprite;
import flixel.system.FlxAssets;
import openfl.events.Event;

/**
 * The flixel sound tray, the little volume meter that pops down sometimes.
 * Accessed via `FlxG.game.soundTray` or `FlxG.sound.soundTray`.
 * Modified by ItzJiggzy, so that it looks like how base game is.
 * Modified again by ItzJiggzy to Optimize this Shit.
 */
class FlxSoundTray extends Sprite
{
    /**
     * Because reading any data from DisplayObject is insanely expensive in hxcpp,
     * keep track of whether we need to update it or not.
     */
    public var active:Bool;

    /**Scale of the soundTray.**/
    var _defaultScale:Float = 0.6;

    /**The sound used when increasing the volume.**/
    public var volumeUpSound:String = "flixel/sounds/beep";

    /**The sound used when decreasing the volume.**/
    public var volumeDownSound:String = 'flixel/sounds/beep';

    /**Whether or not changing the volume should make noise.**/
    public var silent:Bool = false;

    /**
     * This is Were your images are,
     * you can leave imagePath empty if it just in the images folder.
     **/
    var imagePath = 'soundTray/';

    var volumeImages = [
        'soundTray_0',
        'soundTray_1',
        'soundTray_2',
        'soundTray_3',
        'soundTray_4',
        'soundTray_5',
        'soundTray_6',
        'soundTray_7',
        'soundTray_8',
        'soundTray_9',
        'soundTray_10'
    ];
    
    /**Scale of the SoundTray, or at least the Fill of it.**/
    var fillScale = 0.43;

    /**
     * This is Were your sounds are,
     * you can leave soundPath empty if it just in the sounds folder.
    **/
    var soundPath = '';

    /**Sounds Names.**/
    var volumeSounds = ['Volup', 'Voldown', 'VolMAX'];

    /**How Long you want the SoundTray to stay visible.**/
    var defaultStayTime = 1;

    /**Will it Start on the Top or the Left Side.**/
    var topSoundTray = true;

    /**---------- Don't Change any of this below unless you know what you are doing. ----------**/
    var makeTray = true;
    public function new()
    {
        super();

        // Image Checker bcs if it fails, it gives Null Object.
        for (i in 0...volumeImages.length)
        {
            if (!Paths.fileExists('images/$imagePath${volumeImages[i]}.png', IMAGE, false))
            {
                makeTray = false;
                trace('images/$imagePath${volumeImages[i]}.png was not Found.');
            }
        }
        // Sound Checker.
        for (i in 0...volumeSounds.length)
        {
            if (!Paths.fileExists('sounds/$soundPath${volumeSounds[i]}.ogg', SOUND, false))
            {
                trace('sounds/$soundPath${volumeSounds[i]}.ogg was not Found | Using Flixel default sound for this Specific Action.');
            }
        }
        if (makeTray)
            createTray();
    }

    var fill:Sprite;
    var fillImage = null;

    var stayTime:Float = 0;

    private function createTray():Void
    {
        fillImage = Paths.image('$imagePath${volumeImages[0]}', false);

        fill = new Sprite();
        addChild(fill);

        if (topSoundTray) // Hides the SoundTray | this.height/width doesnt fully hide the tray for some reason...
            y = -fillImage.height - 10;
        else
            x = -fillImage.width - 10;

        active = visible = false;
        updateFill(); // Update Fill to Current Volume

        // other stuff
        FlxG.stage.addEventListener(Event.RESIZE, onResize);

        // fix scale
        _defaultScale = getScaleMult();
        scaleX = scaleY = _defaultScale;

        FlxG.signals.postStateSwitch.add(function()
        {
            stayTime = 0;
        });
    }

    var curVolume = 0;

    private function updateFill():Void
    {   
        curVolume = Math.round(FlxG.sound.volume * 10);
        var number = !silent ? curVolume : 0;

        fillImage = Paths.image('$imagePath${volumeImages[number]}', false);
        // trace('Current Volume: $number');

        fill.graphics.clear();
        fill.graphics.beginBitmapFill(fillImage.bitmap, null, false);
        fill.graphics.drawRect(0, 0, fillImage.width, fillImage.height);
        
        graphics.endFill();

        #if FLX_SAVE
        // Save sound preferences
        if (FlxG.save.isBound)
        {
            FlxG.save.data.muted = silent;
            FlxG.save.data.volume = curVolume / 10;
            FlxG.save.flush();
        }
        #end
    }
    
    var lerpPos:Float = 0;
    var alphaTarget:Float = 0;
    var lowerStayTime:Bool = false;

    private override function __enterFrame(deltaTime:Float):Void
    {
        if (!makeTray)
            return;

        if (topSoundTray) // is in __enterFrame in case people scale the windows.
        {
            x = (0.5 * (FlxG.stage.stageWidth - width * _defaultScale) - FlxG.game.x); // Center X 
            y = FlxMath.lerp(y, lerpPos, 0.1); // Y Lerp
        }
        else
        {
            x = FlxMath.lerp(x, lerpPos, 0.1); // X Lerp
            y = (0.5 * (FlxG.stage.stageHeight - height * _defaultScale) - FlxG.game.y); // Center Y
        }
        alpha = FlxMath.lerp(alpha, alphaTarget, 0.25); // Alpha Lerp
        active = visible = alpha > 0;
        
        if (FlxG.keys.anyJustPressed(FlxG.sound.volumeUpKeys)
            || FlxG.keys.anyJustPressed(FlxG.sound.volumeDownKeys)
            || FlxG.keys.anyJustPressed(FlxG.sound.muteKeys))
        {
            lowerStayTime = false;
            stayTime = defaultStayTime;
        }

        var sound = null;
        if (FlxG.keys.anyJustPressed(FlxG.sound.volumeUpKeys))
        {
            silent = false;
            if (curVolume == 10 && Paths.fileExists('sounds/$soundPath${volumeSounds[2]}.ogg', SOUND, false))
            {
                sound = Paths.sound('$soundPath${volumeSounds[2]}');
            }
            else
            {
                sound = Paths.fileExists('sounds/$soundPath${volumeSounds[0]}.ogg', SOUND,
                    false) ? Paths.sound('$soundPath${volumeSounds[0]}') : FlxAssets.getSound(volumeUpSound);
            }
        }
        else if (FlxG.keys.anyJustPressed(FlxG.sound.volumeDownKeys))
        {
            silent = false;
            sound = Paths.fileExists('sounds/$soundPath${volumeSounds[1]}.ogg', SOUND,
                false) ? Paths.sound('$soundPath${volumeSounds[1]}') : FlxAssets.getSound(volumeDownSound);
        }
        else if (FlxG.keys.anyJustPressed(FlxG.sound.muteKeys))
        {
            silent = !silent;
        }
        if (sound != null)
            FlxG.sound.load(sound).play();

        var elapsed = deltaTime / 1000;
        if (FlxG.keys.anyJustReleased(FlxG.sound.volumeUpKeys)
            || FlxG.keys.anyJustReleased(FlxG.sound.volumeDownKeys)
            || FlxG.keys.anyJustReleased(FlxG.sound.muteKeys))
        {
            lowerStayTime = true;
            updateFill();
        }

        if (stayTime > 0)
        { // When you Release Any Volume Key
            if (lowerStayTime)
                stayTime = Math.max(stayTime - elapsed, 0);
            alphaTarget = 1;
            lerpPos = 10;
        }
        else
        {
            alphaTarget = 0;
            if (topSoundTray)
            {
                if (y >= -height)
                    lerpPos = -height - 10;
            }
            else
            {
                if (x >= -width)
                    lerpPos = -width - 10;
            }
        }
    }
    
    private function onResize(e:Event)
    {
        _defaultScale = getScaleMult();
        scaleX = scaleY = _defaultScale;
    }

    function getScaleMult():Float { // Thank you Ai for fixing my shitty code
        var xScale:Float = 0.6;
        var yScale:Float = 0.6;
        return Math.min(xScale, yScale);
    }

    // Useless ahh functions that need to be there to let me compile
    public function update(MS:Float):Void {}
    public function show(up:Bool = false):Void {}
    public function screenCenter():Void {}
}