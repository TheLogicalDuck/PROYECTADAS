import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import funkin.menus.MainMenuState;
import funkin.menus.FreeplayState;
import funkin.game.PlayState;
import funkin.savedata.FunkinSave;

var customSongList:Array<Dynamic> = [
    {name: "Perkality", diff: "hard", dialogue: [
        {text: "Todo el día en mi habitación...", anim: "shy"}, 
        {text: "Oh!", anim: "uuhh"}, 
        {text: "Hola jugador!", anim: "happy"},
        {text: "Umm...", anim: "shy"},
        {text: "Aun se siguen haciendo pruebas de dialogos y de código...", anim: "happy"},
        {text: "Así que espero que te guste esta -pequeña- demostración", anim: "blush"}
    ]}, 
    {name: "for-you-someday", diff: "hard", dialogue: [
        {text: "Oh...", anim: "shy"}, 
        {text: "Me pone un poco triste esta de aquí...", anim: "sad"}, 
        {text: "Ese tipo se proyectó muy fuerte", anim: "sad"}
    ]}, 
    {name: "Hell of a ride", diff: "hard", dialogue: [
        {text: "Patrón...", anim: "laugh"}, 
        {text: "Si ant es hormiga en ingles", anim: "shy"},
        {text: "Y onion en cebolla", anim: "shy"},
        {text: "¿Antonio es una hormiga encebollada?", anim: "uuhh"}
    ]}, 
    {name: "Powerscaling", diff: "hard", dialogue: [
        {text: "Umm...", anim: "uuhh"}, 
        {text: "Esta tampoco está acabada", anim: "mad"}, 
        {text: "Solo... no sigas jugando", anim: "shy"},
        {text: "...", anim: "idle"},
        {text: "ADIOS", anim: "laugh"}
    ]}
];

var curSelectedCustom:Int = 0;
var customBG:FlxSprite;
var verity:FlxSprite;

var coverSprites:Array<FlxSprite> = [];
var coverTexts:Array<FlxText> = [];

var dialogueBox:FlxSprite;
var boxBorder:FlxSprite;
var dialogueText:FlxText;

var isDialoguing:Bool = false;
var textFinished:Bool = false;
var dialoguePages:Array<Dynamic> = [];
var currentPage:Int = 0;
var targetText:String = "";
var currentTextIndex:Int = 0;
var textTimer:Float = 0;
var textDelay:Float = 0.04;
var inputCooldown:Float = 0;

var unlockedStatus:Array<Bool> = [];

function postCreate() {
    // Apagamos el control nativo para que arriba/abajo no hagan nada ni suenen
    disableAutoUpdate = true;

    FlxG.camera.follow(null);
    FlxG.camera.scroll.set(0, 0);

    // 1. Fondo del menú (al cubrir 1280x720 tapa cualquier elemento nativo detrás)
    customBG = new FlxSprite();
    if (Assets.exists(Paths.image('menus/freeplayBG'))) {
        customBG.loadGraphic(Paths.image('menus/freeplayBG'));
        customBG.setGraphicSize(FlxG.width, FlxG.height);
        customBG.updateHitbox();
    } else {
        customBG.makeGraphic(FlxG.width, FlxG.height, 0xFF1A1A2E);
    }
    customBG.screenCenter();
    customBG.antialiasing = true;
    add(customBG);

    // 2. Portadas de canciones
    for (i in 0...customSongList.length) {
        var isUnlocked = true;
        if (i > 0) {
            var prevSong = customSongList[i - 1];
            var entry = FunkinSave.getSongHighscore(prevSong.name, prevSong.diff); 
            if (entry.score <= 0) isUnlocked = false; 
        }
        unlockedStatus.push(isUnlocked);

        var banner = new FlxSprite(0, 0);
        var bannerColor = isUnlocked ? 0xFF00AAFF : 0xFF333333; 
        banner.makeGraphic(250, 250, bannerColor); 
        add(banner); 
        coverSprites.push(banner);

        var displayTxt = isUnlocked ? customSongList[i].name : "Bloqueado";
        var txt = new FlxText(0, 0, 250, displayTxt, 32);
        txt.alignment = "center";
        txt.color = 0xFFFFFFFF;
        add(txt); 
        coverTexts.push(txt);
    }

    // 3. Verity
    verity = new FlxSprite(15, 140); 
    verity.frames = Paths.getSparrowAtlas('menus/verity'); 
    
    verity.animation.addByPrefix('blush', 'blush', 1, true);
    verity.animation.addByPrefix('happy', 'happy', 1, true);
    verity.animation.addByPrefix('idle', 'idle', 4, true);
    verity.animation.addByPrefix('laugh', 'laugh', 1, true);
    verity.animation.addByPrefix('mad', 'mad', 1, true);
    verity.animation.addByPrefix('sad', 'sad', 1, true);
    verity.animation.addByPrefix('shy', 'shy', 1, true);
    verity.animation.addByPrefix('uuhh', 'uuhh', 1, true);
    
    verity.animation.play('idle');
    verity.antialiasing = true;
    verity.updateHitbox();
    verity.origin.y = verity.height; 
    add(verity);

    // 4. Caja de diálogo
    boxBorder = new FlxSprite(36, 496).makeGraphic(1208, 188, 0xFFFFFFFF);
    boxBorder.visible = false;
    add(boxBorder);

    dialogueBox = new FlxSprite(40, 500).makeGraphic(1200, 180, 0xFF000000);
    dialogueBox.alpha = 0.8;
    dialogueBox.visible = false;
    add(dialogueBox);

    dialogueText = new FlxText(60, 520, 1160, "", 40);
    dialogueText.setFormat(Paths.font("Minecraftia.ttf"), 40, 0xFFFFFFFF, "left");
    dialogueText.visible = false;
    add(dialogueText);
    
    changeSelection(0);
}

function update(elapsed:Float) {
    if (isDialoguing) {
        if (!textFinished) {
            textTimer += elapsed;
            if (textTimer >= textDelay) {
                textTimer = 0;
                currentTextIndex++;
                dialogueText.text = targetText.substring(0, currentTextIndex);
                
                var currentChar = targetText.charAt(currentTextIndex - 1);
                if (currentChar != " " && currentChar != "\n") {
                    FlxG.sound.play(Paths.sound('menu/verity2'), 0.3);
                }
                
                if (currentTextIndex >= targetText.length) {
                    textFinished = true;
                }
            }
        }

        if (inputCooldown > 0) {
            inputCooldown -= elapsed;
        } else if (controls.ACCEPT) {
            FlxTween.cancelTweensOf(verity.scale);
            verity.scale.set(0.9, 1.1);
            FlxTween.tween(verity.scale, {x: 1, y: 1}, 0.2, {ease: FlxEase.elasticOut});

            if (!textFinished) {
                dialogueText.text = targetText;
                currentTextIndex = targetText.length;
                textFinished = true;
                inputCooldown = 0.15;
            } else {
                currentPage++;
                if (currentPage < dialoguePages.length) {
                    targetText = dialoguePages[currentPage].text;
                    
                    var emocion = dialoguePages[currentPage].anim != null ? dialoguePages[currentPage].anim : 'happy';
                    verity.animation.play(emocion);
                    
                    dialogueText.text = "";
                    currentTextIndex = 0;
                    textFinished = false;
                    textTimer = 0;
                    inputCooldown = 0.2; 
                } else {
                    var songData = customSongList[curSelectedCustom];
                    PlayState.loadSong(songData.name, songData.diff);
                    FlxG.switchState(new PlayState());
                }
            }
        }
        return; 
    }

    if (FlxG.keys.justPressed.SEVEN) {
        var songData = customSongList[curSelectedCustom];
        var entry = FunkinSave.getSongHighscore(songData.name, songData.diff);
        
        entry.score = 1000;
        FlxG.save.flush(); 
        
        FlxG.sound.play(Paths.sound('menu/confirm'));
        FlxG.switchState(new FreeplayState());
        return;
    }

    var scrollDir = 0;

    if (controls.LEFT_P) scrollDir = -1;
    if (controls.RIGHT_P) scrollDir = 1;

    if (FlxG.mouse.wheel != 0) {
        scrollDir = FlxG.mouse.wheel > 0 ? -1 : 1;
    }

    if (scrollDir != 0) {
        FlxG.sound.play(Paths.sound('menu/scroll'));
        changeSelection(scrollDir);
    }

    if (controls.BACK) {
        FlxG.sound.play(Paths.sound('menu/cancelMenu'));
        FlxG.switchState(new MainMenuState());
    }

    if (controls.ACCEPT) {
        if (unlockedStatus[curSelectedCustom]) {
            var songData = customSongList[curSelectedCustom];
            var entry = FunkinSave.getSongHighscore(songData.name, songData.diff);
            
            if (entry.score <= 0) {
                startDialogue(songData.dialogue); 
            } else {
                PlayState.loadSong(songData.name, songData.diff);
                FlxG.switchState(new PlayState());
            }
        } else {
            FlxG.sound.play(Paths.sound('menu/cancelMenu'));
            
            verity.animation.play('uuhh');
            
            FlxTween.cancelTweensOf(verity.scale);
            verity.scale.set(1.3, 0.7);
            FlxTween.tween(verity.scale, {x: 1, y: 1}, 0.2, {ease: FlxEase.bounceOut});
            
            var selectedBanner = coverSprites[curSelectedCustom];
            FlxTween.cancelTweensOf(selectedBanner);
            FlxTween.tween(selectedBanner, {x: selectedBanner.x + 15}, 0.05, {type: FlxTween.PINGPONG, ease: FlxEase.quadInOut});
            
            haxe.Timer.delay(function() {
                changeSelection(0); 
            }, 200);
        }
    }
}

function startDialogue(paginas:Array<Dynamic>) {
    isDialoguing = true;
    textFinished = false;
    dialoguePages = paginas;
    currentPage = 0;
    
    targetText = dialoguePages[currentPage].text;
    var emocion = dialoguePages[currentPage].anim != null ? dialoguePages[currentPage].anim : 'happy';
    verity.animation.play(emocion);
    
    dialogueText.text = "";
    currentTextIndex = 0;
    textTimer = 0;
    inputCooldown = 0.2; 

    dialogueBox.visible = true;
    boxBorder.visible = true;
    dialogueText.visible = true;

    FlxTween.cancelTweensOf(verity.scale);
    verity.scale.set(0.8, 1.2);
    FlxTween.tween(verity.scale, {x: 1, y: 1}, 0.4, {ease: FlxEase.elasticOut});
}

function changeSelection(change:Int) {
    curSelectedCustom += change;
    if (curSelectedCustom < 0) curSelectedCustom = customSongList.length - 1;
    if (curSelectedCustom >= customSongList.length) curSelectedCustom = 0;

    if (verity.animation.curAnim != null && verity.animation.curAnim.name != 'idle') {
        verity.animation.play('idle');
    }

    for (i in 0...coverSprites.length) {
        var banner = coverSprites[i];
        var txt = coverTexts[i];
        
        FlxTween.cancelTweensOf(banner);
        FlxTween.cancelTweensOf(banner.scale);
        FlxTween.cancelTweensOf(txt);
        FlxTween.cancelTweensOf(txt.scale);

        var distancia = i - curSelectedCustom; 
        
        var targetY = 150; 
        var targetX = 750 + (distancia * 220); 

        var distAbs = Math.abs(distancia);
        var targetAlpha = 1.0 - (distAbs * 0.4); 
        if (targetAlpha < 0) targetAlpha = 0; 
        
        if (distancia == 0) {
            FlxTween.tween(banner, {x: targetX, y: targetY, alpha: 1.0}, 0.2, {ease: FlxEase.quadOut});
            FlxTween.tween(banner.scale, {x: 1.1, y: 1.1}, 0.2, {ease: FlxEase.quadOut}); 

            FlxTween.tween(txt, {x: targetX, y: targetY - 40, alpha: 1.0}, 0.2, {ease: FlxEase.quadOut});
            FlxTween.tween(txt.scale, {x: 1.0, y: 1.0}, 0.2, {ease: FlxEase.quadOut});
        } else {
            FlxTween.tween(banner, {x: targetX, y: targetY + 30, alpha: targetAlpha}, 0.2, {ease: FlxEase.quadOut});
            FlxTween.tween(banner.scale, {x: 0.7, y: 0.7}, 0.2, {ease: FlxEase.quadOut}); 

            FlxTween.tween(txt, {x: targetX, y: targetY - 10, alpha: targetAlpha}, 0.2, {ease: FlxEase.quadOut});
            FlxTween.tween(txt.scale, {x: 0.7, y: 0.7}, 0.2, {ease: FlxEase.quadOut});
        }
    }
}