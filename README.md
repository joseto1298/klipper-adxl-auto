# klipper-adxl-auto

Auto-detecta el acelerómetro ADXL345 al arranque de Klipper. Si está conectado por USB, incluye su configuración automáticamente; si no, lo omite sin errores.

## Requisitos

- Raspberry Pi con Klipper + Moonraker instalados
- ADXL345 conectado via SPI por software (ej: Fly-ADXL345)

## Conexión

Ejemplo con Fly-ADXL345:

| ADXL345 | GPIO |
|---------|------|
| CS      | gpio9  |
| SCLK    | gpio10 |
| MOSI    | gpio11 |
| MISO    | gpio12 |
| VCC     | 3.3V   |
| GND     | GND    |

## Instalación

```bash
cd ~
git clone https://github.com/joseto1298/klipper-adxl-auto.git
cd klipper-adxl-auto
bash setup.sh
```

`setup.sh` hace todo automáticamente:

1. Detecta el serial del ADXL conectado por USB
2. Copia `adxl.cfg` a `~/printer_data/config/Accelerometer/` y escribe el serial
3. Añade `[include ./Accelerometer/adxl_autodetect.cfg]` a tu `printer.cfg`
4. Instala el override systemd que ejecuta `check_adxl.sh` antes de Klipper
5. Añade `[update_manager klipper-adxl-auto]` a `moonraker.conf`
6. Reinicia Klipper

## Cómo funciona

```
Arranque → systemd ejecuta check_adxl.sh (ExecStartPre)
              ↓
         ¿ADXL conectado? ──Sí──→ escribe [include adxl.cfg] en adxl_autodetect.cfg
              No
              ↓
         deja adxl_autodetect.cfg vacío (include harmless)
              ↓
         Klipper arranca con o sin ADXL según esté conectado
```

- `check_adxl.sh` lee el serial desde `~/printer_data/config/Accelerometer/adxl.cfg`
- Si el device node existe en `/dev/serial/by-id/`, escribe el include
- `printer.cfg` tiene `[include ./Accelerometer/adxl_autodetect.cfg]`

## Macros incluidas

Dentro de `adxl.cfg` vienen dos macros para calibrar input shaping:

- `INPUTSHAPER_X` — Calibra el eje X y guarda configuración
- `INPUTSHAPER_Y` — Calibra el eje Y y guarda configuración

Uso desde la consola de Klipper:

```
INPUTSHAPER_X
INPUTSHAPER_Y
```

## Actualizaciones via Moonraker

El update manager ya está configurado. Moonraker detectará nuevos commits en el repositorio y podrás actualizar desde la UI de Fluidd/Mainsail.

## Desinstalación

```bash
sudo rm /etc/systemd/system/klipper.service.d/override.conf
sudo systemctl daemon-reload
sudo systemctl restart klipper
```

Opcional: elimina el repo y los archivos copiados:

```bash
rm -rf ~/klipper-adxl-auto
rm -rf ~/printer_data/config/Accelerometer
```
