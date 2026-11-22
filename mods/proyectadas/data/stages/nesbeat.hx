import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.util.FlxTimer;
import flixel.FlxG;

// -- VARIABLES DEL ACTO 1 --
var bgBar:FlxSprite;
var darkbg:FlxSprite;
var ycbuLightning:FlxSprite;
var ycbuFellas:FlxSprite;

// (Variables de actos 2, 3 y 4)
var smbSprites:Array<FlxSprite> = [];
var duckSprites:Array<FlxSprite> = [];
var smbCastTop:FlxSprite; var smbCastBot:FlxSprite; var smbPlat:FlxSprite; var smbLava:FlxSprite;
var sky_ithink:FlxSprite; var dhTree:FlxSprite; var dhBush:FlxSprite; var dhGrass:FlxSprite;
var clownCar:FlxSprite; var finaleStaticDuck:FlxSprite; var finaleStaticCastle:FlxSprite;
var staticBg:FlxSprite; var staticTrans:FlxSprite; var duckCH:FlxSprite; var textNint:FlxText;
var fireBars:Array<FlxSprite> = [];
var fireBarY:Float; var intro:Bool = true; var isDad:Bool = false; var bowserMech:Bool = false;
var icAng:Float = 10;

function create() {
    // 1. FONDOS (Detrás de los personajes)
    
    // Barras de fondo (bgBar)
    bgBar = new FlxSprite().loadGraphic(Paths.image('bars'));
    bgBar.scale.set(3, 3);
    bgBar.updateHitbox();
    bgBar.screenCenter();
    add(bgBar);
    
    bgBar.angle = 35;
    FlxTween.tween(bgBar, {x: -800}, 7, {type: FlxTween.PINGPONG});
    FlxTween.tween(bgBar, {y: -800}, 8, {type: FlxTween.PINGPONG});
    FlxTween.tween(bgBar, {angle: -35}, 9, {type: FlxTween.PINGPONG});

    // Fondo oscuro (cubrirá el bgBar al inicio)
    darkbg = new FlxSprite().makeGraphic(1280 * 3, 720 * 3, 0xFFFFFFFF);
    darkbg.screenCenter();
    darkbg.color = 0xFF000000;
    add(darkbg);
}

function postCreate() {
    // 2. PRIMER PLANO (Frente a los personajes)
    
    // YCBU Lightning - Carga estática por ahora para evitar crasheos
    ycbuLightning = new FlxSprite().loadGraphic(Paths.image('ycbu_lightning')); 
    ycbuLightning.screenCenter();
    ycbuLightning.visible = false; 
    add(ycbuLightning);

    // YCBU Fellas - Carga estática por ahora
    ycbuFellas = new FlxSprite().loadGraphic(Paths.image('YouCannotBeatUS_Fellas_Assets'));
    ycbuFellas.screenCenter();
    ycbuFellas.visible = false; 
    add(ycbuFellas);

    textNint = new FlxText(0, 0, 1280, "", 165);
    textNint.setFormat(Paths.font("Pixel NES.otf"), 165, 0xFFFFFFFF, "center", FlxTextBorderStyle.OUTLINE, 0xFF000000);
    textNint.screenCenter();
    textNint.scrollFactor.set(0, 0);
    textNint.cameras = [camGame];
    add(textNint);
}

function stepHit(curStep:Int) {
    // Regresamos el fade in del fondo en el step 20 original
    if (curStep == 20) {
        FlxTween.tween(darkbg, {alpha: 0}, 10);
    }
}

function onEvent(event) {
    var n = event.event.name;
    var v1 = event.event.params[0];
    
    if (n == 'Triggers Universal') {
        if (v1 == 'hardstyle_start') { 
            ycbuLightning.visible = true;
            ycbuFellas.visible = true;
        }
    }
}