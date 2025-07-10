# menu_carro.sh

registrar_log() {
  local tipo="$1"
  local mensagem="$2"
  local log_dir="logs"
  local log_file="$log_dir/sistema.log"
  local data_hora=$(date "+%Y-%m-%d %H:%M:%S")

 # mkdir -p "$log_dir"
  echo "[$data_hora] [$tipo] $mensagem" >> "$log_file"
}


cadastrar_carro() {
  clear
  echo "*****Cadastro de Carro *****"

  # Verifica se o usuário está autenticado
  if [ ! -f .session ]; then
    echo "Erro: usuário não autenticado. Faça login novamente."
    sleep 2
    return
  fi

  # Lê dados da sessão
  IFS=";" read -r USER_ID USER_NOME USER_FILIAL_ID < .session

  # Define o nome do arquivo com base na filial
  if [ "$USER_ID" = "1" ]; then
    nome_arquivo="carrosSede.csv"
    filial_id="0"  # sede = 0
  else
    nome_filial=$(awk -F';' -v fid="$USER_FILIAL_ID" 'NR > 1 && $1 == fid { print $2 }' filiais.csv)
    nome_filial_formatado=$(echo "$nome_filial" | tr -d '[:space:]')
    nome_arquivo="carros${nome_filial_formatado}.csv"
    filial_id="$USER_FILIAL_ID"
  fi

  # Cria o cabeçalho se o arquivo ainda não existir
  if [ ! -f "$nome_arquivo" ]; then
    echo "id;marca;data_entrada;preco;id_filial" > "$nome_arquivo"
  fi

  # Gera ID automaticamente
  ultimo_id=$(tail -n +2 "$nome_arquivo" | cut -d';' -f1 | sort -n | tail -1)
  if [ -z "$ultimo_id" ]; then
    novo_id="01"
  else
    novo_id=$(printf "%02d" $((10#$ultimo_id + 1)))
  fi

  # Coleta dados do carro
  read -p "Marca: " marca
  read -p "Data de entrada (AAAA-MM-DD): " data_entrada
  read -p "Preço: " preco

  # Registra o carro no arquivo correto com o ID da filial
  echo "$novo_id;$marca;$data_entrada;$preco;$filial_id" >> "$nome_arquivo"

  echo "Carro cadastrado com sucesso no arquivo '$nome_arquivo' (ID: $novo_id)"
  registrar_log "O $USER_NOME" "Cadastrou carro com sucesso" "Sucesso"
  sleep 2
}

listar_carros() {
  clear
  echo "******* LISTAGEM DE CARROS *******"

  # Verifica se o usuário está autenticado
  if [ ! -f .session ]; then
    echo "Erro: usuário não autenticado."
    sleep 2
    return
  fi

  # Lê dados da sessão
  IFS=";" read -r USER_ID USER_NOME USER_FILIAL_ID < .session

  # Define o nome do arquivo e filial_id conforme o usuário
  if [ "$USER_ID" = "1" ]; then
    nome_arquivo="carros.csv"
    nome_filial=""
  else
    nome_filial=$(awk -F';' -v fid="$USER_FILIAL_ID" 'NR>1 && $1==fid { print $2 }' filiais.csv)
    nome_filial_formatado=$(echo "$nome_filial" | tr -d '[:space:]')
    nome_arquivo="carros${nome_filial_formatado}.csv"
  fi

  # Verifica se o arquivo existe
  if [ ! -f "$nome_arquivo" ]; then
    echo "Arquivo '$nome_arquivo' não encontrado para a filial '$nome_filial'."
    sleep 2
    return
  fi

  # Verifica se arquivo tem dados além do cabeçalho
  total_linhas=$(wc -l < "$nome_arquivo")
  if [ "$total_linhas" -le 1 ]; then
    echo "Nenhum carro cadastrado na filial '$nome_filial'."
    sleep 2
    return
  fi

  # Imprime cabeçalho formatado
  IFS=";" read -r idh marcah datah precoh idfilialh < <(head -1 "$nome_arquivo")
  printf "%-5s %-15s %-15s %-10s %-10s\n" "$idh" "$marcah" "$datah" "$precoh" "$idfilialh"

  # Imprime dados do arquivo
  tail -n +2 "$nome_arquivo" | while IFS=";" read -r id marca data preco id_filial; do
    printf "%-5s %-15s %-15s %-10s %-10s\n" "$id" "$marca" "$data" "$preco" "$id_filial"
  done

  echo
  read -p "ENTER para voltar..."
}

editar_carro() {
  clear
  echo "****** EDITAR CARRO ******"

  if [ ! -f .session ]; then
    echo "Erro: usuário não autenticado."
    sleep 2
    return
  fi

  IFS=";" read -r USER_ID USER_NOME USER_FILIAL_ID < .session

  # Define o arquivo conforme a filial
  if [ "$USER_ID" = "1" ]; then
    nome_arquivo="carros.csv"
  else
    nome_filial=$(awk -F';' -v fid="$USER_FILIAL_ID" 'NR>1 && $1==fid { print $2 }' filiais.csv)
    nome_filial_formatado=$(echo "$nome_filial" | tr -d '[:space:]')
    nome_arquivo="carros${nome_filial_formatado}.csv"
  fi

  if [ ! -f "$nome_arquivo" ]; then
    echo "Arquivo '$nome_arquivo' não encontrado."
    sleep 2
    return
  fi

  read -p "Informe o ID do carro que deseja editar: " id

  # Procura linha do carro pelo ID
  linha=$(tail -n +2 "$nome_arquivo" | grep "^$id;")
  if [ -z "$linha" ]; then
    echo "Carro com ID $id não encontrado nesta filial."
    sleep 2
    return
  fi

  marca_atual=$(echo "$linha" | cut -d';' -f2)
  data_atual=$(echo "$linha" | cut -d';' -f3)
  preco_atual=$(echo "$linha" | cut -d';' -f4)
  filial_atual=$(echo "$linha" | cut -d';' -f5)

  echo "Deixe em branco para manter o valor atual."
  read -p "Nova marca [$marca_atual]: " marca
  read -p "Nova data de entrada [$data_atual]: " data_entrada
  read -p "Novo preço [$preco_atual]: " preco

  marca="${marca:-$marca_atual}"
  data_entrada="${data_entrada:-$data_atual}"
  preco="${preco:-$preco_atual}"

  # Recria o arquivo sem a linha do carro editado
  head -n 1 "$nome_arquivo" > tmp_carros.csv
  tail -n +2 "$nome_arquivo" | grep -v "^$id;" >> tmp_carros.csv
  # Acrescenta a linha atualizada
  echo "$id;$marca;$data_entrada;$preco;$filial_atual" >> tmp_carros.csv

  mv tmp_carros.csv "$nome_arquivo"

  echo "Carro com ID $id atualizado com sucesso."
  registrar_log "$USER_NOME" "Carro Editado com sucesso" "Sucesso"
  sleep 2
}

eliminar_carro() {
  clear
  echo "******* ELIMINAR CARRO *******"

  if [ ! -f .session ]; then
    echo "Erro: usuário não autenticado."
    sleep 2
    return
  fi

  IFS=";" read -r USER_ID USER_NOME USER_FILIAL_ID < .session

  # Define o arquivo conforme a filial
  if [ "$USER_ID" = "1" ]; then
    nome_arquivo="carrosSede.csv"
  else
    nome_filial=$(awk -F';' -v fid="$USER_FILIAL_ID" 'NR>1 && $1==fid { print $2 }' filiais.csv)
    nome_filial_formatado=$(echo "$nome_filial" | tr -d '[:space:]')
    nome_arquivo="carros${nome_filial_formatado}.csv"
  fi

  if [ ! -f "$nome_arquivo" ]; then
    echo "Arquivo '$nome_arquivo' não encontrado."
    sleep 2
    return
  fi

  read -p "Informe o ID do carro que deseja eliminar: " id

  # Verifica se o carro existe
  linha=$(tail -n +2 "$nome_arquivo" | grep "^$id;")
  if [ -z "$linha" ]; then
    echo "Carro com ID $id não encontrado nesta filial."
    sleep 2
    return
  fi

  read -p "Tem certeza que deseja eliminar o carro com ID $id? (s/n): " confirma
  if [[ "$confirma" =~ ^[Ss]$ ]]; then
    # Remove o carro e recria arquivo sem essa linha
    head -n 1 "$nome_arquivo" > tmp_carros.csv
    tail -n +2 "$nome_arquivo" | grep -v "^$id;" >> tmp_carros.csv
    mv tmp_carros.csv "$nome_arquivo"
    echo "Carro eliminado com sucesso."
    registrar_log "O $USER_NOME" "Eliminou carro com sucesso" "Sucesso"
  else
    echo "Operação cancelada."
  fi
  sleep 2
}

eliminar_carro() {
  clear
  echo "****** ELIMINAR CARRO ******"

  if [ ! -f .session ]; then
    echo "Erro: usuário não autenticado."
    sleep 2
    return
  fi

  IFS=";" read -r USER_ID USER_NOME USER_FILIAL_ID < .session

  # Define o arquivo conforme a filial
  if [ "$USER_ID" = "1" ]; then
    nome_arquivo="carros.csv"
  else
    nome_filial=$(awk -F';' -v fid="$USER_FILIAL_ID" 'NR>1 && $1==fid { print $2 }' filiais.csv)
    nome_filial_formatado=$(echo "$nome_filial" | tr -d '[:space:]')
    nome_arquivo="carros${nome_filial_formatado}.csv"
  fi

  if [ ! -f "$nome_arquivo" ]; then
    echo "Arquivo '$nome_arquivo' não encontrado."
    sleep 2
    return
  fi

  read -p "Informe o ID do carro que deseja eliminar: " id

  # Verifica se o carro existe
  linha=$(tail -n +2 "$nome_arquivo" | grep "^$id;")
  if [ -z "$linha" ]; then
    echo "Carro com ID $id não encontrado nesta filial."
    sleep 2
    return
  fi

  read -p "Tem certeza que deseja eliminar o carro com ID $id? (s/n): " confirma
  if [[ "$confirma" =~ ^[Ss]$ ]]; then
    # Remove o carro e recria arquivo sem essa linha
    head -n 1 "$nome_arquivo" > tmp_carros.csv
    tail -n +2 "$nome_arquivo" | grep -v "^$id;" >> tmp_carros.csv
    mv tmp_carros.csv "$nome_arquivo"
    echo "Carro eliminado com sucesso."
    registrar_log "O $USER_NOME" "Eliminou carro com sucesso" "Sucesso"
  else
    echo "Operação cancelada."
  fi
  sleep 2
}

menu_carro() {
  while true; do
    clear
    echo "***** MENU DE CARROS ******"
    echo "[1] Cadastrar carro"
    echo "[2] Listar carros"
    echo "[3] Editar carro"
    echo "[4] Eliminar carro"
    echo "[0] Voltar"
    read -p "Opção: " op
    case $op in
      1) cadastrar_carro ;;
      2) listar_carros ;;
      3) editar_carro ;;
      4) eliminar_carro ;;
      0) break ;;
      *) echo "Opção inválida!"; sleep 1 ;;
    esac
  done
}
