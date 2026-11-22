// Script by bctix
import flixel.text.FlxTextBorderStyle;
import flixel.text.FlxTextFormatMarkerPair;
import flixel.text.FlxTextFormat;
import flixel.text.FlxText.FlxTextAlign;

var letrasstardewConfig = {
    xOffset: 0,
    yOffset: 50,
    color: FlxColor.WHITE,
    borderColor: FlxColor.BLACK,
    font: "stardew",
    size: 34,
    borderSize: 2,
    textSpaceMovementMult: 1, // Multiplier for how far the text history moves. make it -1 to move down
    showHistory: true
}

var textGroup:FlxTypedGroup;

function create()
{
    textGroup = new FlxTypedGroup();
    add(textGroup);
}

function onEvent(eventEvent) {
    if(eventEvent.event.name != "letrasstardew") return;
    // trace(eventEvent.event.params);
    switch(eventEvent.event.params[0]) {
        case "Add Text":
            addText(eventEvent.event.params[1]);

        case "Force remove all text":
            killText();

        case "Set Color":
            letrasstardewConfig.color = eventEvent.event.params[2];

        case "Set Border Color":
            letrasstardewConfig.borderColor = eventEvent.event.params[2];

        case "Set Font":
            letrasstardewConfig.font = eventEvent.event.params[1];

        case "Set Size":
            letrasstardewConfig.size = eventEvent.event.params[1];

        case "Enable text history (On, Off)":
            letrasstardewConfig.showHistory = eventEvent.event.params[3];
            trace(eventEvent.event.params[3]);
        case "Change text offset":
            trace(eventEvent.event.params[2]);
            letrasstardewConfig.xOffset = Std.int(eventEvent.event.params[1].split(",")[0]);
            letrasstardewConfig.yOffset = Std.int(eventEvent.event.params[1].split(",")[1]);
            
    }
}

function addText(setText)
{
    for(i in textGroup.members)
    {
        if(letrasstardewConfig.showHistory)
        {
            var spaceToMove = !camHUD.downscroll ? letrasstardewConfig.size : -1 * letrasstardewConfig.size;
            spaceToMove *= letrasstardewConfig.textSpaceMovementMult;
            FlxTween.tween(i, {alpha: i.alpha - 0.7, y: i.y - spaceToMove}, 0.3, {ease: FlxEase.cubeOut, onComplete: function(t){
                if(i.alpha == 0)
                {
                    textGroup.remove(i, true);
                    i.destroy();
                }
            }});
        } else {
            textGroup.remove(i, true);
            i.destroy();
        }
        
    }
    var text = new FlxText(0, 500);
    text.setFormat(getFont(), letrasstardewConfig.size, letrasstardewConfig.color, FlxTextAlign.CENTER, FlxTextBorderStyle.OUTLINE, letrasstardewConfig.borderColor);
    text.borderSize = letrasstardewConfig.borderSize;
    text.text = setText;
    text.antialiasing = true;
    text.screenCenter(FlxAxes.X);
    text.x += letrasstardewConfig.xOffset;
    text.y += letrasstardewConfig.yOffset;
    text.cameras = [camHUD];
    textGroup.add(text);
}

function getFont()
{
    trace(Paths.font(letrasstardewConfig.font));
    if(StringTools.endsWith(letrasstardewConfig.font, ".ttf") || StringTools.endsWith(letrasstardewConfig.font, ".otf"))
        return Paths.font(letrasstardewConfig.font);

    if(Assets.exists(Paths.font(letrasstardewConfig.font) + ".ttf"))
        return Paths.font(letrasstardewConfig.font) + ".ttf";

    if(Assets.exists(Paths.font(letrasstardewConfig.font) + ".otf"))
        return Paths.font(letrasstardewConfig.font) + ".otf";
}

function killText()
{
    for(i in textGroup.members)
    {
        FlxTween.tween(i, {alpha: 0}, 0.3, {ease: FlxEase.cubeOut, onComplete: function(t){
            textGroup.remove(i, true);
            i.destroy();
        }});
    }
}