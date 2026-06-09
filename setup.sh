#!/bin/bash
set -e

REPO_DIR="$HOME/klipper-adxl-auto"
CONFIG_DIR="$HOME/printer_data/config/Accelerometer"

echo "=== Instalando klipper-adxl-auto ==="

# --- Detectar ADXL ---
AUTO_SERIAL=""
DEVICES=$(ls /dev/serial/by-id/usb-Klipper_* 2>/dev/null || true)
COUNT=$(echo "$DEVICES" | grep -c . || true)

if [ "$COUNT" -eq 0 ]; then
    echo "No se detectó ninguna placa ADXL conectada."
    echo "Conéctala por USB o introduce el serial manualmente."
    read -rp "Serial ADXL (ej: /dev/serial/by-id/usb-Klipper_rp2040_XXXX): " USER_SERIAL
    ADXL_SERIAL="$USER_SERIAL"
elif [ "$COUNT" -eq 1 ]; then
    ADXL_SERIAL="$DEVICES"
    echo "ADXL detectado: $ADXL_SERIAL"
    read -rp "¿Usar este serial? (Enter=si, n=no): " CONFIRM
    if [ "$CONFIRM" = "n" ]; then
        read -rp "Introduce el serial manualmente: " USER_SERIAL
        ADXL_SERIAL="$USER_SERIAL"
    fi
else
    echo "Múltiples dispositivos ADXL detectados:"
    echo "$DEVICES"
    read -rp "Introduce el serial exacto: " USER_SERIAL
    ADXL_SERIAL="$USER_SERIAL"
fi

echo ""
echo "Serial configurado: $ADXL_SERIAL"

# --- Copiar adxl.cfg a config y poner serial ---
echo "[1/4] Copiando adxl.cfg a $CONFIG_DIR..."
mkdir -p "$CONFIG_DIR"
if [ ! -f "$CONFIG_DIR/adxl.cfg" ]; then
    cp "$REPO_DIR/adxl.cfg" "$CONFIG_DIR/"
    echo "OK (nuevo)"
else
    echo "OK (ya existe, omitiendo)"
fi
sed -i "s|^serial:.*|serial: $ADXL_SERIAL|" "$CONFIG_DIR/adxl.cfg"
echo "OK"

# --- Añadir include a printer.cfg ---
echo "[2/4] Añadiendo include a printer.cfg..."
PRINTER_CFG="$HOME/printer_data/config/printer.cfg"
INCLUDE_LINE="[include ./Accelerometer/adxl_autodetect.cfg]"
if [ -f "$PRINTER_CFG" ]; then
    if grep -qF "$INCLUDE_LINE" "$PRINTER_CFG"; then
        echo "OK (ya existe)"
    else
        echo "" >> "$PRINTER_CFG"
        echo "$INCLUDE_LINE" >> "$PRINTER_CFG"
        echo "OK (añadido)"
    fi
else
    echo "AVISO: printer.cfg no encontrado en $PRINTER_CFG"
fi

# --- Instalar override systemd ---
echo "[3/4] Instalando override systemd..."
sudo mkdir -p /etc/systemd/system/klipper.service.d
sudo cp "$REPO_DIR/adxl-auto.conf" /etc/systemd/system/klipper.service.d/
echo "OK"

# --- Añadir update_manager a moonraker.conf ---
echo "[4/4] Añadiendo update_manager a moonraker.conf..."
MOONRAKER_CFG="$HOME/printer_data/config/moonraker.conf"
if [ -f "$MOONRAKER_CFG" ]; then
    if grep -q "\[update_manager klipper-adxl-auto\]" "$MOONRAKER_CFG"; then
        echo "OK (ya existe)"
    else
        echo "" >> "$MOONRAKER_CFG"
        cat "$REPO_DIR/.moonraker.conf" >> "$MOONRAKER_CFG"
        echo "OK (añadido)"
    fi
else
    cp "$REPO_DIR/.moonraker.conf" "$MOONRAKER_CFG"
    echo "OK (creado nuevo)"
fi

echo "=== Instalación completa ==="
