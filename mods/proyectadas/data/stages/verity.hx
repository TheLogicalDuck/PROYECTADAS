import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.util.FlxTimer;
import flixel.FlxSprite;

var cameoTimer:FlxTimer;
var cameoTween:FlxTween;
var isCameoWalking:Bool = false;

var startX:Float = -2200;
var endX:Float = 4500;

// --- CONFIGURACIÓN DE LAS NOTAS DEL OPONENTE EN EL FONDO ---
var noteMinX:Float = 150;      // Límite izquierdo donde pueden aparecer las notas
var noteMaxX:Float = 1400;     // Límite derecho donde pueden aparecer las notas
var noteMinY:Float = 100;      // Límite superior
var noteMaxY:Float = 650;      // Límite inferior
var noteMinScale:Float = 0.45; // Tamaño mínimo más pequeño
var noteMaxScale:Float = 0.85; // Tamaño máximo más pequeño
var noteFadeTime:Float = 0.9;  // Duración en segundos antes de desaparecer

var noteDirs:Array<String> = ["purple", "blue", "green", "red"];

function postCreate() {
    // 1. Lógica del Cameo
    if (lijaCameo != null) {
        lijaCameo.visible = false;
        lijaCameo.x = startX;
        scheduleNextCameo();
    }

    // 2. Ocultar los receptores normales del oponente en el HUD
    var oppStrumLine = strumLines.members[0];
    if (oppStrumLine != null) {
        for (strum in oppStrumLine.members) {
            if (strum != null) {
                strum.visible = false;
                strum.alpha = 0;
            }
        }
    }
}

// Ocultar las notas reales del oponente en el HUD
function onNoteCreation(event) {
    if (event.note.strumLine == strumLines.members[0]) {
        event.note.visible = false;
        event.note.alpha = 0;
    }
}

// Cada vez que el oponente golpea una nota, aparece el efecto en el fondo
function onDadHit(event) {
    if (event.note.isSustainNote) return;

    var dir:Int = event.note.noteData;
    var animName:String = noteDirs[dir % 4];

    var bgNote:FlxSprite = new FlxSprite();
    bgNote.frames = Paths.getSparrowAtlas("game/notes/default");
    bgNote.animation.addByPrefix("idle", animName + "0", 24, false);
    bgNote.animation.play("idle");

    // Posición y escala aleatoria más pequeña
    bgNote.x = FlxG.random.float(noteMinX, noteMaxX);
    bgNote.y = FlxG.random.float(noteMinY, noteMaxY);
    
    var randomScale:Float = FlxG.random.float(noteMinScale, noteMaxScale);
    bgNote.scale.set(randomScale, randomScale);
    bgNote.updateHitbox();

    // Cámara y scroll del escenario
    bgNote.cameras = [camGame];
    bgNote.scrollFactor.set(1, 1);
    bgNote.antialiasing = false;

    // Ángulo inicial aleatorio y dirección de giro
    var startAngle:Float = FlxG.random.float(-25, 25);
    var rotateAmount:Float = FlxG.random.float(20, 45) * (FlxG.random.bool(50) ? 1 : -1);
    bgNote.angle = startAngle;

    // Insertar exactamente detrás de 'lijaCameo' (y por lo tanto delante de 'back layer')
    var cameoIndex:Int = (lijaCameo != null) ? members.indexOf(lijaCameo) : -1;
    if (cameoIndex != -1) {
        insert(cameoIndex, bgNote);
    } else {
        add(bgNote);
    }

    // Animación suave de desaparición y rotación
    FlxTween.tween(bgNote, {
        alpha: 0,
        angle: startAngle + rotateAmount,
        "scale.x": randomScale * 0.75,
        "scale.y": randomScale * 0.75
    }, noteFadeTime, {
        ease: FlxEase.quadOut,
        onComplete: function(twn:FlxTween) {
            remove(bgNote, true);
            bgNote.destroy();
        }
    });
}

// --- FUNCIONES DEL CAMEO (Lijacameo) ---
function scheduleNextCameo() {
    var waitTime:Float = FlxG.random.float(10, 25);
    cameoTimer = new FlxTimer().start(waitTime, function(tmr:FlxTimer) {
        triggerCameo();
    });
}

function triggerCameo() {
    if (lijaCameo == null || isCameoWalking) return;

    isCameoWalking = true;
    lijaCameo.x = startX;
    lijaCameo.visible = true;
    lijaCameo.playAnim("idle", true);

    var walkDuration:Float = FlxG.random.float(30, 40);

    cameoTween = FlxTween.tween(lijaCameo, {x: endX}, walkDuration, {
        onComplete: function(twn:FlxTween) {
            lijaCameo.visible = false;
            isCameoWalking = false;
            scheduleNextCameo();
        }
    });
}

function destroy() {
    if (cameoTimer != null) cameoTimer.cancel();
    if (cameoTween != null) cameoTween.cancel();
}