# Rpi-Asm-Framebuffer-SPACE-GAME

https://github.com/ramiro-l/Rpi-Asm-Framebuffer-SPACE-GAME/assets/74385260/989ec836-37dd-4e4a-bdf5-46fa6ce6b424

## Descripción

Proyecto de la clase de Organizador del Computador de la Licenciatura en Ciencias de la Computación, programado en ensamblador para la arquitectura ARMv8, utilizando el simulador QEMU.

Es un juego en donde una nave espacial se mueva por el espacio, añadiendo un fondo dinámico en donde las estrellas y planetas bajan a diferente velocidad, teniendo profundidad y haciendo el efecto de que la nave avanze.

Las siguientes teclas mueven la nave de la siguiente forma:

- W arriba
- S abajo
- A izquierda
- D derecha

La barra espaciadora activa en la nave la propulsión haciendo que avance rápidamente por el espacio impidiendole maniobrar, solo avanzar.

### Observaciones

- Configuración de pantalla: `640x480` pixels, formato `ARGB` 32 bits.
- El registro `X0` contiene la dirección base del FrameBuffer (Pixel 1).
- El código de cada consigna debe ser escrito en el archivo _app.s_.
- El archivo _start.s_ contiene la inicialización del FrameBuffer **(NO EDITAR)**, al finalizar llama a _app.s_.

## Estructura

- **[app.s](app.s)** Este archivo contiene a apliación. Todo el hardware ya está inicializado anteriormente.
- **[start.s](start.s)** Este archivo realiza la inicialización del hardware.
- **[Makefile](Makefile)** Archivo que describe como construir el software _(que ensamblador utilizar, que salida generar, etc)_.
- **[memmap](memmap)** Este archivo contiene la descripción de la distribución de la memoria del programa y donde colocar cada sección.

- **README.md** este archivo.

## Uso

### Requerimientos

Necesitan tener instalado `qemu-system-aarch64` y `gcc-aarch64-linux-gnu` para poder correr el proyecto.

```bash
$ sudo apt-get install qemu-system-aarch64 gcc-aarch64-linux-gnu
```

El archivo _Makefile_ contiene lo necesario para construir el proyecto.
Se pueden utilizar otros archivos **.s** si les resulta práctico para emprolijar el código y el Makefile los ensamblará.

**Para correr el proyecto ejecutar**

```bash
$ make runQEMU
```

Esto construirá el código y ejecutará qemu para su emulación.

Si qemu se queja con un error parecido a `qemu-system-aarch64: unsupported machine type`, prueben cambiar `raspi3` por `raspi3b` en la receta `runQEMU` del **Makefile** (línea 23 si no lo cambiaron).

**Para correr el gpio manager**

Necesitas darm permisos al binario de gpiom para poder ejecutarlo.

```bash
$ chmod +x ./bin/gpiom
```

Luego si puede ejecutar:

```bash
$ make runGPIOM
```

Ejecutar _luego_ de haber corrido qemu.

## Como correr qemu y gcc usando Docker containers

Los containers son maquinas virtuales livianas que permiten correr procesos individuales como el qemu y gcc.

Para seguir esta guia primero tienen que instala docker y asegurarse que el usuario que vayan a usar tenga permiso para correr docker (ie dockergrp) o ser root

### Linux

- Para construir el container hacer

```bash
docker build -t famaf/rpi-qemu .
```

- Para arrancarlo

```bash
xhost +
cd rpi-asm-framebuffer
docker run -dt --name rpi-qemu --rm -v $(pwd):/local --privileged -e "DISPLAY=${DISPLAY:-:0.0}" -v /tmp/.X11-unix:/tmp/.X11-unix -v "$HOME/.Xauthority:/root/.Xauthority:rw" famaf/rpi-qemu
```

- Para correr el emulador y el simulador de I/O

```bash
docker exec -d rpi-qemu make runQEMU
docker exec -it rpi-qemu make runGPIOM
```

- Para terminar el container

```bash
docker kill rpi-qemu
```

### MacOS

En MacOS primero tienen que [instalar un X server](https://medium.com/@mreichelt/how-to-show-x11-windows-within-docker-on-mac-50759f4b65cb) (i.e. XQuartz)

- Para construir el container hacer

```bash
docker build -t famaf/rpi-qemu .
```

- Para arrancarlo

```bash
xhost +
cd rpi-asm-framebuffer
docker run -dt --name rpi-qemu --rm -v $(pwd):/local --privileged -e "DISPLAY=host.docker.internal:0" -v /tmp/.X11-unix:/tmp/.X11-unix -v "$HOME/.Xauthority:/root/.Xauthority:rw" famaf/rpi-qemu
```

- Para correr el emulador y el simulador de I/O

```bash
docker exec -d rpi-qemu make runQEMU
docker exec -it rpi-qemu make runGPIOM
```

- Para terminar el container

```bash
docker kill rpi-qemu
```

---

### Otros comandos utiles

```bash
# Correr el container en modo interactivo
docker run -it --rm -v $(pwd):/local --privileged -e "DISPLAY=${DISPLAY:-:0.0}" -v /tmp/.X11-unix:/tmp/.X11-unix -v "$HOME/.Xauthority:/root/.Xauthority:rw" famaf/rpi-qemu
# Correr un shell en el container
docker exec -it rpi-qemu /bin/bash
```

### Otros comandos utiles

```bash
# Dar permisos
chmod +x ./bin/gpiom
# Para poder debugear, modificar el makefile agregando
runQEMU-GDB: kernel8.img
      qemu-system-aarch64 -s -S -M raspi3b -kernel kernel8.img -serial stdio -qtest unix:/tmp/qtest.sock,server,nowait

add-symbol-file app.o 0x00000000000900c8
```
