import flixel.FlxSprite;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.util.FlxColor;
import openfl.filters.ShaderFilter;

var blackScreen:FlxSprite;
var comicShader:CustomShader;

var useComicShader:Bool = false;
// Intensidad del shader (0.0 = invisible, 0.25 = sutil/poquita, 1.0 = completo)
var shaderIntensity:Float = 0; 

function postCreate() {
    if (useComicShader) {
        comicShader = new CustomShader("comicBook_FX");
        comicShader.iTime = 0;
        comicShader.uIntensity = shaderIntensity;
        camGame.setFilters([new ShaderFilter(comicShader)]);
    }

    blackScreen = new FlxSprite().makeGraphic(FlxG.width * 2, FlxG.height * 2, FlxColor.BLACK);
    blackScreen.scrollFactor.set(0, 0);
    blackScreen.screenCenter();
    blackScreen.cameras = [camHUD]; 
    add(blackScreen);
}

function onSongStart() {
    // Calcula la duración exacta en segundos desde el inicio hasta el step 120
    var fadeDuration:Float = (Conductor.stepCrochet * 120) / 1000;

    FlxTween.tween(blackScreen, {alpha: 0}, fadeDuration, {
        ease: FlxEase.linear,
        onComplete: function(twn:FlxTween) {
            remove(blackScreen);
            blackScreen.destroy();
        }
    });
}

function update(elapsed:Float) {
    if (useComicShader && comicShader != null) {
        comicShader.iTime += elapsed;
    }
}