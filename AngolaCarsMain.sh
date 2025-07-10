#!/bin/bash

source ./menu_carro.sh
source ./menu_usuarios.sh
source ./menu_filial.sh
source ./menu_vendas.sh
source ./menu_recepcao.sh

registrar_log() {
  local tipo="$1"
  local mensagem="$2"
  local log_dir="logs"
  local log_file="$log_dir/sistema.log"
  local data_hora=$(date "+%Y-%m-%d %H:%M:%S")

  mkdir -p "$log_dir"
  echo "[$data_hora] [$tipo] $mensagem" >> "$log_file"
}

listar_logs_sistema() {
  LOG_PATH="logs/sistema.log"

  if [ -f "$LOG_PATH" ]; then
    echo "📄 Listando conteúdo de: $LOG_PATH"
    echo "--------------------------------------------"
    cat "$LOG_PATH"
    echo "--------------------------------------------"
    echo "✔️ Total de linhas: $(wc -l < "$LOG_PATH")"
  else
    echo "❌ Arquivo de log não encontrado: $LOG_PATH"
  fi
}


menu_admin() {
  while true; do
    clear
    echo "***** MENU ADMIN - ANGOLA CARS ******"
    echo "[1] Gerir carros"
    echo "[2] Gerir funcionarios(usuarios)"
    echo "[3] Gerir filial"
    echo "[4] Menu venda"
    echo "[5] Listar Vendas - Geral"
    echo "[6] Fazer backup"
    echo "[7] Listar log"
    echo "[0] Sair"
    read -p "Opção: " op
    case $op in
      1) menu_carro;;
      2) menu_usuarios;;
      3) menu_filial;;
      4) menu_vendas;;
      5) abrir_vendas;;
      6) backup_vendas_para_pendrive;;
      7) listar_logs_sistema;;
      0) break;;
      *) echo "Opção inválida";;
    esac
    read -p "ENTER para continuar..."
  done
 }

menu_admin_filial() {
  local nome_filial="$1"

  while true; do
    clear
    echo "****** MENU ADMIN - ANGOLA CARS - FILIAL $nome_filial ******"
    echo "[1] Gerir carro"
    echo "[2] Listar carros disponiveis antes de vender"
    echo "[3] Registrar venda"
    echo "[4] Pesquisar Venda"
    echo "[5] Emitir comprovativo de Venda"
    echo "[6] Listar Vendas Geral"
    echo "[7] Listar Vendas da Filial"
    echo "[0] Sair"
    read -p "Opção: " op
    case $op in
      1) menu_carro;;
      2) listar_carros;;
      3) criar_venda;;
      4) pesquisar_venda;;
      5) emitir_comprovativo;;
      6) abrir_vendas;;
      7) listar_vendas_filial;;
      0) break;;
      *) echo "Opção inválida";;
    esac
    read -p "ENTER para continuar..."
  done
}

logar() {
  while true; do
    clear
    echo "*********** LOGIN ANGOLA CARS ************"
    read -p "ID: " id
    read -s -p "Senha: " senha
    echo

    linha=$(grep "^$id;.*;$senha;" usuarios.csv)

    if [ -n "$linha" ]; then
      usuario=$(echo "$linha" | cut -d';' -f2)
      funcao=$(echo "$linha" | cut -d';' -f4)
      filial_id=$(echo "$linha" | cut -d';' -f7)

      echo "$id;$usuario;$filial_id" > .session

      if [ -n "$filial_id" ]; then
        nome_filial=$(awk -F';' -v fid="$filial_id" 'NR>1 && $1==fid { print $2 }' filiais.csv)
        echo "Bem-vindo, $usuario – Filial: $nome_filial ($funcao)"
        registrar_log "LOGIN" "Usuário $usuario (ID: $id) logado na filial $nome_filial como $funcao"
      else
        echo "Bem-vindo, $usuario ($funcao)"
        registrar_log "LOGIN" "Usuário $usuario (ID: $id) logado na sede como $funcao"
      fi

      sleep 2

      case "$funcao" in
        Admin)
          if [ -n "$filial_id" ]; then
            menu_admin_filial "$nome_filial"
          else
            menu_admin
          fi
          ;;
        Recepcao) menu_recepcao ;;
        Vendas) menu_vendas ;;
        *)
          echo "Função desconhecida!"
          registrar_log "ERRO" "Função desconhecida ($funcao) para usuário $usuario (ID: $id)"
          sleep 2
          ;;
      esac

      break
    else
      echo "ID ou senha inválidos!"
      registrar_log "LOGIN_FALHADO" "Tentativa de login inválida com ID: $id"
      read -p "Pressione ENTER para tentar novamente..."
    fi
  done
}
   

logar


