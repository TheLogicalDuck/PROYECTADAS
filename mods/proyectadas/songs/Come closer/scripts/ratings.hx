// --- CONFIGURACIÓN ---
var ratingScale:Float = 0.45;      // Tamaño del rating
var offsetYDownscroll:Float = -60; // Altura en Downscroll
var offsetYUpscroll:Float = 95;    // Altura en Upscroll
// ---------------------

var laneRatings:Array<FlxSprite> = [null, null, null, null];

function onPlayerHit(event) {
    if (event.note.isSustainNote) return;

    // 1. Ocultamos el rating grande por defecto
    event.showRating = false;
    // event.showNums = false; // Descomenta esta línea si también quieres ocultar los números del combo

    if (event.rating == null) return;

    // 2. Obtenemos la flecha del jugador (0: Izq, 1: Abajo, 2: Arriba, 3: Der)
    var dir:Int = event.direction;
    var strum = playerStrums.members[dir];
    if (strum == null) return;

    // 3. Si ya hay un rating en esa flecha, lo eliminamos para que no se encime
    if (laneRatings[dir] != null) {
        FlxTween.cancelTweensOf(laneRatings[dir]);
        laneRatings[dir].destroy();
    }

    // 4. Cargamos la imagen desde la carpeta real de Codename Engine ('game/score/')
    var ratingSpr = new FlxSprite();
    var isPixel:Bool = PlayState.isPixelStage;
    var imgPath:String = isPixel ? ('stages/school/ui/' + event.rating) : ('game/score/' + event.rating);

    ratingSpr.loadGraphic(Paths.image(imgPath));
    ratingSpr.cameras = [camHUD];
    ratingSpr.antialiasing = !isPixel;

    var finalScale:Float = isPixel ? (ratingScale * 5.5) : ratingScale;
    ratingSpr.scale.set(finalScale, finalScale);
    ratingSpr.updateHitbox();

    // 5. Centramos en X respecto a la flecha y posicionamos en Y
    ratingSpr.x = strum.x + (strum.width / 2) - (ratingSpr.width / 2);
    var targetY:Float = strum.y + (downscroll ? offsetYDownscroll : offsetYUpscroll);
    ratingSpr.y = targetY + (downscroll ? 10 : -10);

    // 6. Añadimos directamente a la escena (sin usar strumLineNotes)
    add(ratingSpr);
    laneRatings[dir] = ratingSpr;

    // 7. Animación rápida de aparición y desvanecimiento
    FlxTween.tween(ratingSpr, {y: targetY, alpha: 0}, 0.35, {
        ease: FlxEase.cubeOut,
        startDelay: 0.1,
        onComplete: function(twn:FlxTween) {
            if (ratingSpr != null) {
                ratingSpr.destroy();
                if (laneRatings[dir] == ratingSpr) laneRatings[dir] = null;
            }
        }
    });
}