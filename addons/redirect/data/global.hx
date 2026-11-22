import funkin.backend.assets.ModsFolder;

function preStateSwitch()
    if (ModsFolder.currentModFolder != 'proyectadas')
        ModsFolder.switchMod('proyectadas');