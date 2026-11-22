import flixel.FlxG;
import flixel.text.FlxText;
import flixel.group.FlxGroup.FlxTypedGroup;
import funkin.options.OptionsMenu;
import funkin.backend.ModState;
import funkin.backend.shaders.CustomShader;
import funkin.editors.EditorPicker;
import funkin.menus.FreeplayState;

var opciones:Array<String> = ["Freeplay", "Opciones"];
var curSelectedCustom:Int = 0;
var grpOpciones:FlxTypedGroup<FlxText>;

var water:CustomShader = null;
var totalTimer:Float = FlxG.random.float(100, 1000);

function postCreate() {
    menuItems.visible = false; 
    selectedSomethin = true; 

    FlxG.camera.follow(null);
    FlxG.camera.scroll.set(0, 0);

    if (Options.gameplayShaders) {
        water = new CustomShader("waterDistortion");
        water.strength = 0.15; 
        if (bg != null) {
            bg.shader = water;
        }
    }

    grpOpciones = new FlxTypedGroup();
    add(grpOpciones);

    for (i in 0...opciones.length) {
        var txt = new FlxText(0, 0, 0, opciones[i], 64);
        txt.color = 0xFFFFFFFF; 
        txt.screenCenter();
        txt.y += (i * 120) - 60;
        grpOpciones.add(txt);
    }
    changeSelection(0);
}

function update(elapsed:Float) {
    if (water != null) {
        totalTimer += elapsed;
        water.time = totalTimer;
    }

    // 2. Reactivamos el menú Debug / Editores con la tecla 7
    if (FlxG.keys.justPressed.SEVEN) {
        persistentUpdate = false;
        persistentDraw = true;
        openSubState(new EditorPicker());
        return;
    }

    if (controls.UP_P) {
        FlxG.sound.play(Paths.sound('menu/scroll'));
        changeSelection(-1);
    }
    if (controls.DOWN_P) {
        FlxG.sound.play(Paths.sound('menu/scroll'));
        changeSelection(1);
    }
    

    if (controls.ACCEPT) {
        FlxG.sound.play(Paths.sound('menu/confirm'));
        if (curSelectedCustom == 0)
            FlxG.switchState(new ModState("FreeplayState")); 
        else
            FlxG.switchState(new OptionsMenu());
    }
}

function changeSelection(change:Int) {
    curSelectedCustom += change;
    if (curSelectedCustom < 0) curSelectedCustom = opciones.length - 1;
    if (curSelectedCustom >= opciones.length) curSelectedCustom = 0;

    for (i in 0...grpOpciones.members.length) {
        grpOpciones.members[i].alpha = (i == curSelectedCustom) ? 1.0 : 0.5;
    }
}