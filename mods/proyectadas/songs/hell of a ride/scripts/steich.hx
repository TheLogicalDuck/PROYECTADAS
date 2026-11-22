import flixel.FlxSprite;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.util.FlxColor;
import flixel.math.FlxMath;
import flixel.text.FlxTextAlign;

var blackOverlay:FlxSprite;

function postCreate() {
    // Oculta toda la interfaz al iniciar
    camHUD.alpha = 0;

    // Oculta a "dad" al cargar la canción
    dad.alpha = 0;

    blackOverlay = new FlxSprite(-1000, -1000).makeGraphic(4000, 4000, FlxColor.BLACK);
    insert(members.indexOf(dad), blackOverlay);

    // --- 1. BARRA DE VIDA VERTICAL A LA IZQUIERDA ---
    // Rotamos la barra 90 grados (arriba será dad, abajo será boyfriend)
    healthBarBG.angle = 90;
    healthBar.angle = 90;

    // La ubicamos centrada verticalmente en el lado izquierdo
    healthBarBG.x = -230; 
    healthBarBG.screenCenter(0x10); // 0x10 equivale a FlxAxes.Y
    
    healthBar.x = healthBarBG.x + 4;
    healthBar.y = healthBarBG.y + 4;

    // --- 2. TEXTOS ORDENADOS EN LA ESQUINA INFERIOR DERECHA ---
    var marginX = 25;
    var bottomY = FlxG.height - 35;
    var spacing = 26;

    // Configuramos ancho, posición X y alineación a la derecha para los 3 textos
    for (txt in [scoreTxt, missesTxt, accuracyTxt]) {
        txt.fieldWidth = 400;
        txt.x = FlxG.width - txt.fieldWidth - marginX;
        txt.alignment = FlxTextAlign.RIGHT;
    }

    // Los apilamos de abajo hacia arriba
    scoreTxt.y = bottomY;
    missesTxt.y = bottomY - spacing;
    accuracyTxt.y = bottomY - (spacing * 2);
}

// Actualiza los iconos y textos en cada frame
function postUpdate(elapsed:Float) {
    // Calculamos el porcentaje de vida (0.0 a 1.0)
    var percent = FlxMath.remapToRange(health, 0, maxHealth, 0, 1);
    
    // Calculamos el centro y límites verticales de la barra rotada
    var barCenterY = healthBar.y + (healthBar.height / 2);
    var halfLength = healthBar.width / 2;
    var topY = barCenterY - halfLength;
    
    // En rotación de 90°, el relleno de BF crece desde abajo hacia arriba
    var fillY = topY + (healthBar.width * (1 - percent));
    var iconCenterX = healthBar.x + (healthBar.width / 2);

    // Posicionamos los iconos sobre la división de vida
    iconP1.x = iconCenterX - (iconP1.width / 2);
    iconP1.y = fillY - 15; // Debajo de la línea (lado de BF)

    iconP2.x = iconCenterX - (iconP2.width / 2);
    iconP2.y = fillY - iconP2.height + 15; // Encima de la línea (lado de Dad)

    // Cambiamos "Combo Breaks:" por "Misses:" manteniendo el conteo
    missesTxt.text = StringTools.replace(missesTxt.text, "Combo Breaks", "Misses");
}

// Cancela las imágenes y sonidos de la cuenta regresiva ("3, 2, 1, Go")
function onCountdown(event) {
    event.cancel();
}

// Se ejecuta exactamente cuando termina la cuenta regresiva y empieza la canción
function onSongStart() {
    FlxTween.tween(dad, {alpha: 1}, 0.6, {
        ease: FlxEase.quadOut
    });
}

function stepHit(curStep:Int) {
    if (curStep == 48) {
        // Desvanece el fondo negro
        FlxTween.tween(blackOverlay, {alpha: 0}, 0.6, {
            ease: FlxEase.quadOut,
            onComplete: function(twn:FlxTween) {
                remove(blackOverlay);
                blackOverlay.destroy();
            }
        });

        // Hace aparecer la interfaz sutilmente al mismo tiempo
        FlxTween.tween(camHUD, {alpha: 1}, 0.6, {
            ease: FlxEase.quadOut
        });
    }
}