#!/bin/bash

LOG_FILE="./logs/sistema.log"
mkdir -p logs

registar_log() {
  local USER="$1"
  local ACAO="$2"
  local RESULTADO="$3"
  local DATA=$(date '+%Y-%m-%d %H:%M:%S')
  echo "[$DATA] [User: $USER] Ação: $ACAO | Resultado: $RESULTADO" >> "$LOG_FILE"
}

