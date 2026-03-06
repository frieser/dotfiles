# Configuración de Niri para Modo PIP

## Agregar a tu ~/.config/niri/config.kdl

Añade esta línea dentro del bloque `binds`:

```kdl
binds {
    // ... tus otros binds ...
    
    // Activar modo PIP con Super+P
    Mod+P { spawn "qs" "ipc" "call" "ui.window.pip" "enable"; }
    
    // Alternativamente, con Super+Shift+P para toggle
    Mod+Shift+P { spawn "qs" "ipc" "call" "ui.window.pip" "toggle"; }
}
```

## Uso

1. Enfoca la ventana que quieres poner en modo PIP
2. Presiona `Super+P`
3. La ventana se convertirá en flotante, se redimensionará a 1/3 del tamaño de la pantalla, 
   y se posicionará en la esquina inferior derecha

## Ejemplo completo de bloque binds

```kdl
binds {
    // Navegación básica
    Mod+H { focus-column-left; }
    Mod+L { focus-column-right; }
    Mod+J { focus-window-down; }
    Mod+K { focus-window-up; }
    
    // Modo PIP
    Mod+P { spawn "qs" "ipc" "call" "ui.window.pip" "enable"; }
    
    // Volver ventana a tiling (sacarla de PIP)
    Mod+Shift+T { move-window-to-tiling; }
}
```

## Comandos útiles relacionados

### Volver una ventana flotante a tiling
```bash
niri msg action move-window-to-tiling
```

### Cambiar entre modo flotante y tiling
```bash
niri msg action toggle-window-floating
```

### Centrar ventana flotante
```bash
niri msg action center-window
```
