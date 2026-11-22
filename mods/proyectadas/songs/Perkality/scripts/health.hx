import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.math.FlxRect;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.util.FlxColor;

var sdBg:FlxSprite;
var sdFill:FlxSprite;
var sdFrame:FlxSprite;
var healthText:FlxText;

var maxDisplayHealth:Int = 100;

var uiScale:Float = 1.0;
var topEmptyPixels:Float = 14;
var bottomEmptyPixels:Float = 2;

var fillClip:FlxRect;
var smoothHealth:Float = 0.5;
var mousePos:FlxPoint;

function postCreate() {
    FlxG.mouse.visible = true;
    mousePos = new FlxPoint();

    healthBarBG.visible = false;
    healthBar.visible = false;
    iconP1.visible = false;
    iconP2.visible = false;

    var posX:Float = FlxG.width - 70;
    var posY:Float = FlxG.height - 200;

    sdBg = new FlxSprite(posX, posY);
    sdBg.loadGraphic(Paths.image("stages/fatal/fondobida"));
    sdBg.scale.set(uiScale, uiScale);
    sdBg.updateHitbox();
    sdBg.antialiasing = false;
    sdBg.cameras = [camHUD];
    add(sdBg);

    sdFill = new FlxSprite(posX, posY);
    sdFill.loadGraphic(Paths.image("stages/fatal/bida"));
    sdFill.scale.set(uiScale, uiScale);
    sdFill.updateHitbox();
    sdFill.antialiasing = false;
    sdFill.cameras = [camHUD];

    fillClip = new FlxRect(0, 0, sdFill.frameWidth, sdFill.frameHeight);
    sdFill.clipRect = fillClip;
    add(sdFill);

    sdFrame = new FlxSprite(posX, posY);
    sdFrame.loadGraphic(Paths.image("stages/fatal/marco"));
    sdFrame.scale.set(uiScale, uiScale);
    sdFrame.updateHitbox();
    sdFrame.antialiasing = false;
    sdFrame.cameras = [camHUD];
    add(sdFrame);

    healthText = new FlxText(posX - 210, posY + (sdFrame.height * 0.65), 200, "");
    healthText.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, "right");
    healthText.setBorderStyle(2, FlxColor.fromRGB(65, 30, 15), 2);
    healthText.antialiasing = false;
    healthText.visible = false;
    healthText.cameras = [camHUD];
    add(healthText);
}

function update(elapsed:Float) {
    var targetPercent:Float = FlxMath.bound(health / 2.0, 0, 1);
    smoothHealth = FlxMath.lerp(smoothHealth, targetPercent, elapsed * 15);

    var usableHeight:Float = sdFill.frameHeight - topEmptyPixels - bottomEmptyPixels;
    var currentVisibleHeight:Float = usableHeight * smoothHealth;
    var cutFromTop:Float = topEmptyPixels + (usableHeight - currentVisibleHeight);

    fillClip.y = cutFromTop;
    fillClip.height = currentVisibleHeight + bottomEmptyPixels;
    sdFill.clipRect = fillClip;

    var mainColor:FlxColor;
    if (smoothHealth > 0.5) {
        var t:Float = (smoothHealth - 0.5) * 2;
        mainColor = FlxColor.interpolate(FlxColor.fromRGB(255, 215, 0), FlxColor.WHITE, t);
    } else {
        var t:Float = smoothHealth * 2;
        mainColor = FlxColor.interpolate(FlxColor.fromRGB(230, 30, 30), FlxColor.fromRGB(255, 215, 0), t);
    }
    sdFill.color = mainColor;

    // Obtenemos la posición real del mouse dentro de camHUD
    FlxG.mouse.getWorldPosition(camHUD, mousePos);

    // Comprobamos si el cursor está dentro de los límites de la barra
    var isHovering:Bool = (
        mousePos.x >= sdFrame.x &&
        mousePos.x <= sdFrame.x + sdFrame.width &&
        mousePos.y >= sdFrame.y &&
        mousePos.y <= sdFrame.y + sdFrame.height
    );

    if (isHovering) {
        healthText.visible = true;
        var currentHP:Int = Math.round(targetPercent * maxDisplayHealth);
        healthText.text = currentHP + "/" + maxDisplayHealth;
    } else {
        healthText.visible = false;
    }
}

function destroy() {
    FlxG.mouse.visible = false;
}