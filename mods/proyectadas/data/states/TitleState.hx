import flixel.FlxG;
import funkin.menus.MainMenuState;

function postCreate() {
    FlxG.switchState(new MainMenuState());
}

function update(elapsed:Float) {
    return Function_Stop;
}