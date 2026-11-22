import flixel.math.FlxMath;

// Ajusta este valor para cambiar qué tanto se mueve la cámara
var camIntensity:Float = 30; 
var camSpeed:Float = 5; 

// Se ejecuta cuando el Oponente (Dad) presiona una nota
function onDadHit(event) {
    if (!event.note.isSustainNote) applyCamOffset(event.note.noteData);
}

// Se ejecuta cuando el Jugador (Boyfriend) presiona una nota
function onPlayerHit(event) {
    if (!event.note.isSustainNote) applyCamOffset(event.note.noteData);
}

// Función que define hacia dónde mover la cámara
function applyCamOffset(dir:Int) {
    switch(dir) {
        case 0: camGame.targetOffset.set(-camIntensity, 0); // Izquierda
        case 1: camGame.targetOffset.set(0, camIntensity);  // Abajo
        case 2: camGame.targetOffset.set(0, -camIntensity); // Arriba
        case 3: camGame.targetOffset.set(camIntensity, 0);  // Derecha
    }
}

// Regresa la cámara al centro suavemente en cada frame
function update(elapsed:Float) {
    camGame.targetOffset.x = FlxMath.lerp(camGame.targetOffset.x, 0, elapsed * camSpeed);
    camGame.targetOffset.y = FlxMath.lerp(camGame.targetOffset.y, 0, elapsed * camSpeed);
}