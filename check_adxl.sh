#!/bin/bash

CFG="$HOME/printer_data/config/Accelerometer/adxl.cfg"
FILE="$HOME/printer_data/config/Accelerometer/adxl_autodetect.cfg"

ADXL_SERIAL=$(grep "^serial:" "$CFG" 2>/dev/null | sed 's/^serial:[[:space:]]*//')

if [ -n "$ADXL_SERIAL" ] && [ -e "$ADXL_SERIAL" ]; then
    echo "[include adxl.cfg]" > "$FILE"
else
    echo "" > "$FILE"
fi
