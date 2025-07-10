registrar_log() {
  local tipo="$1"
  local mensagem="$2"
  local log_dir="logs"
  local log_file="$log_dir/sistema.log"
  local data_hora=$(date "+%Y-%m-%d %H:%M:%S")

 # mkdir -p "$log_dir"
  echo "[$data_hora] [$tipo] $mensagem" >> "$log_file"
}


listar_filiais() {
  clear
  echo "****** LISTA DE FILIAIS CADASTRADAS ******"
  echo

  if [ ! -f filiais.csv ]; then
    echo "Arquivo filiais.csv não encontrado!"
    sleep 2
    return
  fi

  total=$(wc -l < filiais.csv)
  if [ "$total" -le 1 ]; then
    echo "Nenhuma filial cadastrada."
    sleep 2
    return
  fi

  # Cabeçalho formatado
  IFS=";" read -r idh nomeh paish cidadeh contactoh emailh < <(head -1 filiais.csv)
  printf "%-5s %-15s %-10s %-12s %-15s %-25s\n" "$idh" "$nomeh" "$paish" "$cidadeh" "$contactoh" "$emailh"

  # Dados
  tail -n +2 filiais.csv | while IFS=";" read -r id nome pais cidade contacto email; do
    printf "%-5s %-15s %-10s %-12s %-15s %-25s\n" "$id" "$nome" "$pais" "$cidade" "$contacto" "$email"
  done

  echo
  read -p "ENTER para voltar..."
}


cadastrar_filial() {
  clear
  echo "****** Cadastrar Nova Filial ******"

  # Cria o arquivo com cabeçalho se ainda não existir
  if [ ! -f filiais.csv ]; then
    echo "id;nome;pais;cidade;contacto;email" > filiais.csv
  fi

  # Gerar novo ID automático
  ultimo_id=$(tail -n +2 filiais.csv | cut -d';' -f1 | sort -n | tail -1)
  
  if [ -z "$ultimo_id" ]; then
    novo_id="01"
  else
    novo_id=$(printf "%02d" $((10#$ultimo_id + 1)))
  fi

  # Pedir dados
  read -p "Nome da filial: " nome
  read -p "País: " pais
  read -p "Cidade: " cidade
  read -p "Contacto: " contacto
  read -p "Email: " email

  echo "$novo_id;$nome;$pais;$cidade;$contacto;$email" >> filiais.csv

  echo "Filial cadastrada com sucesso! (ID: $novo_id)"
  registrar_log "Admin" "Cadastrou carro com sucesso" "Sucesso"
  sleep 2
}

editar_filial() {
  clear
  echo "****** EDITAR FILIAL ******"

  if [ ! -f filiais.csv ]; then
    echo "Arquivo filiais.csv não encontrado!"
    sleep 2
    return
  fi

  read -p "Informe o ID da filial que deseja editar: " id

  linha=$(tail -n +2 filiais.csv | grep "^$id;")
  if [ -z "$linha" ]; then
    echo "Filial com ID $id não encontrada."
    sleep 2
    return
  fi

  nome_atual=$(echo "$linha" | cut -d';' -f2)
  pais_atual=$(echo "$linha" | cut -d';' -f3)
  cidade_atual=$(echo "$linha" | cut -d';' -f4)
  contacto_atual=$(echo "$linha" | cut -d';' -f5)
  email_atual=$(echo "$linha" | cut -d';' -f6)

  echo "Deixe em branco para manter o valor atual."
  read -p "Novo nome [$nome_atual]: " nome
  read -p "Novo país [$pais_atual]: " pais
  read -p "Nova cidade [$cidade_atual]: " cidade
  read -p "Novo contacto [$contacto_atual]: " contacto
  read -p "Novo email [$email_atual]: " email

  nome="${nome:-$nome_atual}"
  pais="${pais:-$pais_atual}"
  cidade="${cidade:-$cidade_atual}"
  contacto="${contacto:-$contacto_atual}"
  email="${email:-$email_atual}"

  head -n 1 filiais.csv > tmp_filiais.csv
  tail -n +2 filiais.csv | grep -v "^$id;" >> tmp_filiais.csv
  echo "$id;$nome;$pais;$cidade;$contacto;$email" >> tmp_filiais.csv
  mv tmp_filiais.csv filiais.csv

  echo "Filial com ID $id atualizada com sucesso!"
  registrar_log "ADMIN" "Cadastrou FILIAL com sucesso" "Sucesso"
  sleep 2
}

eliminar_filial() {
  clear
  echo "******* REMOVER FILIAL ******"

  if [ ! -f filiais.csv ]; then
    echo "Arquivo filiais.csv não encontrado!"
    sleep 2
    return
  fi

  read -p "Informe o ID da filial a remover: " id

  linha=$(tail -n +2 filiais.csv | grep "^$id;")
  if [ -z "$linha" ]; then
    echo "Filial com ID $id não encontrada."
    sleep 2
    return
  fi

  echo "Tem certeza que deseja remover a filial com ID $id?"
  read -p "(s/n): " confirm
  if [[ "$confirm" != "s" && "$confirm" != "S" ]]; then
    echo "Operação cancelada."
    sleep 2
    return
  fi

  head -n 1 filiais.csv > tmp_filiais.csv
  tail -n +2 filiais.csv | grep -v "^$id;" >> tmp_filiais.csv
  mv tmp_filiais.csv filiais.csv

  echo "Filial com ID $id removida com sucesso."
  registrar_log "ADMIN GERAL" "Removeu filial com sucesso" "Sucesso"
  sleep 2
}


menu_filial() {
  while true; do
    clear
    echo "******** MENU FILIAL ********"
    echo "[1] Cadastrar filial"
    echo "[2] Listar filiais"
    echo "[3] Editar filial"
    echo "[4] Eliminar filial"
    echo "[0] Voltar"
    read -p "Opção: " op
    case $op in
      1) cadastrar_filial;;
      2) listar_filiais;;
      3) editar_filial;;
      4) eliminar_filial;;
      0) break ;;
      *) echo "Opção inválida!"; sleep 1 ;;
    esac
  done
}
