registrar_log() {
  local tipo="$1"
  local mensagem="$2"
  local log_dir="logs"
  local log_file="$log_dir/sistema.log"
  local data_hora=$(date "+%Y-%m-%d %H:%M:%S")

 # mkdir -p "$log_dir"
  echo "[$data_hora] [$tipo] $mensagem" >> "$log_file"
}

listar_carros() {
  clear
  echo "****** LISTAGEM DE CARROS ******"

  
  if [ ! -f .session ]; then
    echo "Erro: usuário não autenticado."
    sleep 2
    return
  fi

  
  IFS=";" read -r USER_ID USER_NOME USER_FILIAL_ID < .session

  
  if [ "$USER_ID" = "1" ]; then
    nome_arquivo="carros.csv"
    nome_filial=""
  else
    nome_filial=$(awk -F';' -v fid="$USER_FILIAL_ID" 'NR>1 && $1==fid { print $2 }' filiais.csv)
    nome_filial_formatado=$(echo "$nome_filial" | tr -d '[:space:]')
    nome_arquivo="carros${nome_filial_formatado}.csv"
  fi


  if [ ! -f "$nome_arquivo" ]; then
    echo "Arquivo '$nome_arquivo' não encontrado para a filial '$nome_filial'."
    sleep 2
    return
  fi

  
  total_linhas=$(wc -l < "$nome_arquivo")
  if [ "$total_linhas" -le 1 ]; then
    echo "Nenhum carro cadastrado na filial '$nome_filial'."
    sleep 2
    return
  fi

  
  IFS=";" read -r idh marcah datah precoh idfilialh < <(head -1 "$nome_arquivo")
  printf "%-5s %-15s %-15s %-10s %-10s\n" "$idh" "$marcah" "$datah" "$precoh" "$idfilialh"

  
  tail -n +2 "$nome_arquivo" | while IFS=";" read -r id marca data preco id_filial; do
    printf "%-5s %-15s %-15s %-10s %-10s\n" "$id" "$marca" "$data" "$preco" "$id_filial"
  done

  echo
  read -p "ENTER para voltar..."
}

abrir_vendas() {
  if [ ! -f vendas.csv ]; then
    echo "Arquivo vendas.csv não encontrado!"
    sleep 2
    return
  fi

  xdg-open vendas.csv &

  echo "Abrindo arquivo vendas.csv no programa padrão..."
  sleep 2
}

criar_venda() {
  clear
  echo "****** REGISTRO DE VENDA ******"

  if [ ! -f .session ]; then
    echo "Erro: usuário não autenticado."
    sleep 2
    return
  fi

  # Ler dados da sessão
  IFS=";" read -r USER_ID USER_NOME USER_FILIAL_ID < .session

  # Determina nome do arquivo de carros da filial
  if [ "$USER_ID" = "1" ]; then
    nome_arquivo_carros="carrosSede.csv"
    filial_nome="Sede"
  else
    nome_filial=$(awk -F';' -v fid="$USER_FILIAL_ID" 'NR > 1 && $1 == fid { print $2 }' filiais.csv)
    nome_filial_formatado=$(echo "$nome_filial" | tr -d '[:space:]')
    nome_arquivo_carros="carros${nome_filial_formatado}.csv"
    filial_nome="$nome_filial"
  fi

  if [ ! -f "$nome_arquivo_carros" ]; then
    echo "Erro: Arquivo de carros da filial não encontrado: $nome_arquivo_carros"
    sleep 2
    return
  fi

  read -p "ID do carro vendido: " carro_id
  read -p "Nome do cliente: " cliente_nome

  # Verifica se o carro existe no arquivo correto
  linha_carro=$(grep "^$carro_id;" "$nome_arquivo_carros")
  if [ -z "$linha_carro" ]; then
    echo "Erro: Carro com ID $carro_id não encontrado na sua filial."
    sleep 2
    return
  fi

  preco_venda=$(echo "$linha_carro" | cut -d';' -f4)
  marca=$(echo "$linha_carro" | cut -d';' -f2)

  # Remove espaços extras
  carro_id=$(echo "$carro_id" | xargs)
  cliente_nome=$(echo "$cliente_nome" | xargs)
  preco_venda=$(echo "$preco_venda" | xargs)
  filial_nome=$(echo "$filial_nome" | xargs)
  USER_NOME=$(echo "$USER_NOME" | xargs)

  data_venda=$(date "+%Y-%m-%d %H:%M")
  nome_arquivo="vendas.csv"


  if [ ! -f "$nome_arquivo" ]; then
    echo "id_venda;carro_id;data_venda;preco_venda;cliente_nome;user_id;nome_funcionario;filial_nome" > "$nome_arquivo"
  fi
  ultimo_id=$(tail -n +2 "$nome_arquivo" | cut -d';' -f1 | sort -n | tail -1)
  if [ -z "$ultimo_id" ]; then
    novo_id="01"
  else
    novo_id=$(printf "%02d" $((10#$ultimo_id + 1)))
  fi

 
  echo
  echo "===== CONFIRMAÇÃO DE VENDA ====="
  echo "ID da Venda      : $novo_id"
  echo "Data             : $data_venda"
  echo "Cliente          : $cliente_nome"
  echo "Carro ID         : $carro_id"
  echo "Marca do Carro   : $marca"
  echo "Preço            : $preco_venda"
  echo "Atendido por     : $USER_NOME"
  echo "Filial           : $filial_nome"
  echo "================================"
  read -p "Confirmar venda? (s/n): " confirmar

  if [[ ! "$confirmar" =~ ^[Ss]$ ]]; then
    echo "Venda cancelada."
    sleep 1.5
    return
  fi


  echo "$novo_id;$carro_id;$data_venda;$preco_venda;$cliente_nome;$USER_ID;$USER_NOME;$filial_nome" >> "$nome_arquivo"
  echo "Venda registrada com sucesso!"
  echo "ID da nova venda: $novo_id"
  registrar_log "$USER_NOME" "Cadastrou venda com sucesso" "Sucesso"
  sleep 1

  read -p "Deseja emitir o comprovativo desta venda? (s/n): " opc
  if [[ "$opc" =~ ^[Ss]$ ]]; then
    emitir_comprovativo_automatico "$novo_id"
  fi
}

emitir_comprovativo_automatico() {
  local id_venda="$1"

  linha=$(awk -F';' -v id="$id_venda" '$1 == id { print $0 }' vendas.csv)
  if [ -z "$linha" ]; then
    echo "Venda com ID $id_venda não encontrada para emissão."
    sleep 2
    return
  fi

  IFS=';' read -r id_venda carro_id data_venda preco_venda cliente_nome user_id nome_funcionario filial_nome <<< "$linha"
  linha_carro=$(grep "^$carro_id;" carros*.csv 2>/dev/null | head -n 1)
  marca=$(echo "$linha_carro" | cut -d';' -f2)

  mkdir -p ComprovativosVenda
  tmp_txt="ComprovativosVenda/tmp_comprovativo_${id_venda}.txt"
  pdf_path="ComprovativosVenda/comprovativo_${id_venda}.pdf"

  {
    echo "----------- COMPROVATIVO DE VENDA -----------"
    echo "Venda Nº         : $id_venda"
    echo "Data da Venda    : $data_venda"
    echo "Cliente          : $cliente_nome"
    echo "Carro ID         : $carro_id"
    echo "Marca do Carro   : $marca"
    echo "Preço            : $preco_venda"
    echo "Atendido por     : $nome_funcionario"
    echo "Filial           : ${filial_nome:-Sede}"
    echo "---------------------------------------------"
    echo "Obrigado por comprar na ANGOLA CARS"
  } > "$tmp_txt"

  enscript "$tmp_txt" -o - | ps2pdf - "$pdf_path"
  rm "$tmp_txt"

  echo "Comprovativo PDF salvo como '$pdf_path'"
  registrar_log "O ADMIN Geral - $USER_NOME" "Gerou Comprovativo de Venda"
  sleep 1
}


pesquisar_venda() {
  clear
  echo "******* PESQUISAR VENDA *******"

  
  if [ ! -f vendas.csv ]; then
    echo "Arquivo de vendas não encontrado!"
    sleep 2
    return
  fi

  echo "Pesquisar por:"
  echo "[1] ID da Venda"
  echo "[2] Nome do Cliente"
  read -p "Escolha uma opção: " opcao

  case $opcao in
    1)
      read -p "Digite o ID da venda: " id_venda
      resultado=$(awk -F';' -v id="$id_venda" 'NR == 1 || $1 == id' vendas.csv)
      ;;
    2)
      read -p "Digite o nome do cliente (ou parte): " nome_cliente
      resultado=$(awk -F';' -v nome="$nome_cliente" 'NR == 1 || tolower($5) ~ tolower(nome)' vendas.csv)
      ;;
    *)
      echo "Opção inválida!"
      sleep 2
      return
      ;;
  esac

  echo
  if [ -z "$resultado" ] || [ "$(echo "$resultado" | wc -l)" -le 1 ]; then
    echo "Nenhuma venda encontrada."
  else
    echo "Resultado da pesquisa:"
    echo "$resultado" | column -t -s ';'
  fi

  echo
  read -p "ENTER para voltar..."
}

emitir_comprovativo() {
  clear
  echo "****** EMITIR COMPROVATIVO DE VENDA ******"

  if [ ! -f vendas.csv ]; then
    echo "Arquivo de vendas não encontrado."
    sleep 2
    return
  fi

  read -p "Digite o ID da venda: " id_venda

  linha=$(awk -F';' -v id="$id_venda" '$1 == id { print $0 }' vendas.csv)
  if [ -z "$linha" ]; then
    echo "Venda com ID $id_venda não encontrada."
    sleep 2
    return
  fi

  IFS=';' read -r id_venda carro_id data_venda preco_venda cliente_nome user_id nome_funcionario filial_nome <<< "$linha"

  linha_carro=$(grep "^$carro_id;" carros*.csv 2>/dev/null | head -n 1)
  marca=$(echo "$linha_carro" | cut -d';' -f2)

  echo
  echo "---------------------------------------------"
  echo "           COMPROVATIVO DE VENDA             "
  echo "---------------------------------------------"
  echo "Venda Nº         : $id_venda"
  echo "Data da Venda    : $data_venda"
  echo "Cliente          : $cliente_nome"
  echo "Carro ID         : $carro_id"
  echo "Marca do Carro   : $marca"
  echo "Preço            : $preco_venda"
  echo "Atendido por     : $nome_funcionario"
  echo "Filial           : ${filial_nome:-Sede}"
  echo "---------------------------------------------"
  echo "         Obrigado por comprar na             "
  echo "              ANGOLA CARS                    "
  echo "---------------------------------------------"

  echo
  read -p "Deseja salvar como arquivo PDF (comprovativo_$id_venda.pdf)? (s/n): " salvar
  if [[ "$salvar" =~ ^[Ss]$ ]]; then
    mkdir -p ComprovativosVenda
    tmp_txt="ComprovativosVenda/tmp_comprovativo_${id_venda}.txt"
    pdf_path="ComprovativosVenda/comprovativo_${id_venda}.pdf"

    {
      echo "----------- COMPROVATIVO DE VENDA -----------"
      echo "Venda Nº         : $id_venda"
      echo "Data da Venda    : $data_venda"
      echo "Cliente          : $cliente_nome"
      echo "Carro ID         : $carro_id"
      echo "Marca do Carro   : $marca"
      echo "Preço            : $preco_venda"
      echo "Atendido por     : $nome_funcionario"
      echo "Filial           : ${filial_nome:-Sede}"
      echo "---------------------------------------------"
      echo "Obrigado por comprar na ANGOLA CARS"
    } > "$tmp_txt"

    enscript "$tmp_txt" -o - | ps2pdf - "$pdf_path"
    rm "$tmp_txt"

    echo "Comprovativo PDF salvo como '$pdf_path'"
    registrar_log "$USER_NOME" "Emitiu Comprovativo" "Sucesso"
  fi

  read -p "ENTER para voltar..."
}


listar_vendas_filial(){
  clear
  echo "******* LISTA DE VENDAS DA FILIAL ******"

  if [ ! -f .session ]; then
    echo "Erro: usuário não autenticado."
    sleep 2
    return
  fi

  if [ ! -f vendas.csv ]; then
    echo "Arquivo vendas.csv não encontrado!"
    sleep 2
    return
  fi

 
  IFS=";" read -r USER_ID USER_NOME USER_FILIAL_ID < .session

  echo
  printf "%-8s %-9s %-18s %-15s %-20s %-10s %-20s %-15s\n" \
    "ID" "CARRO" "DATA VENDA" "PREÇO" "CLIENTE" "USER ID" "FUNCIONÁRIO" "FILIAL"
  echo "-------------------------------------------------------------------------------------------------------------------------------------"

  tail -n +2 vendas.csv | while IFS=";" read -r id_venda carro_id data_venda preco_venda cliente_nome user_id nome_funcionario filial_nome; do
    if [ "$USER_ID" = "1" ] || [ "$USER_FILIAL_ID" = "$(awk -F';' -v fn="$filial_nome" '$2==fn {print $1}' filiais.csv)" ]; then
      printf "%-8s %-9s %-18s %-15s %-20s %-10s %-20s %-15s\n" \
        "$id_venda" "$carro_id" "$data_venda" "$preco_venda" "$cliente_nome" "$user_id" "$nome_funcionario" "$filial_nome"
    fi
  done

  echo
  read -p "ENTER para voltar..."
}

backup_vendas_para_pendrive() {
  clear
  echo "***** BACKUP DE VENDAS PARA PENDRIVE *****"

  if [ ! -f vendas.csv ]; then
    echo "Nenhum arquivo de vendas encontrado para backup."
    sleep 2
    return
  fi

  echo "🔍 Verificando pendrives em /media/$USER e /mnt ..."
  sleep 1

  # Procura dispositivos em /media/$USER/*
  dispositivos_media=(/media/$USER/*)
  dispositivos_mnt=(/mnt/*)

  # Escolhe o primeiro válido
  for dir in "${dispositivos_media[@]}" "${dispositivos_mnt[@]}"; do
    if [ -d "$dir" ]; then
      caminho_pendrive="$dir"
      break
    fi
  done

  if [ -z "$caminho_pendrive" ]; then
    echo "Nenhuma pendrive montada foi encontrada em /media ou /mnt."
    sleep 2
    return
  fi

  echo "📦 Pendrive detectada em: $caminho_pendrive"

  pasta_backup="$caminho_pendrive/backups_vendas"
  mkdir -p "$pasta_backup"

  data=$(date +%Y-%m-%d)
  destino="$pasta_backup/vendas_backup_$data.csv"

  cp vendas.csv "$destino"
  echo "✅ Backup copiado com sucesso para: $destino"

  # Remove backups antigos com mais de 1 ano
  find "$pasta_backup" -name "vendas_backup_*.csv" -type f -mtime +365 -exec rm -f {} \;
  echo "🧹 Backups com mais de 1 ano foram limpos."

  # Desmontar a pendrive se desejar
  read -p "Deseja desmontar a pendrive agora? (s/n): " desmontar
  if [[ "$desmontar" =~ ^[Ss]$ ]]; then
    dispositivo_montado=$(df "$caminho_pendrive" | tail -1 | awk '{print $1}')
    sudo umount "$dispositivo_montado"
    echo "📤 Pendrive desmontada com sucesso."
  fi

  sleep 2
}

menu_vendas() {
  while true; do
    clear
    echo "***** MENU VENDAS - ANGOLA CARS ******"
    echo "[1] Registrar venda"
    echo "[2] Listar carros disponiveis antes de vender"
    echo "[3] Listar vendas feitas"
    echo "[4] Emitir comprovativo de vendas"
    echo "[0] Sair"
    read -p "Opção: " op
    case $op in
      1) criar_venda;;
      2) listar_carros;;
      3) listar_vendas_filial;; 
      4) emitir_comprovativo;;
      0) break;;
      *) echo "Opção inválida";;
    esac
    read -p "ENTER para continuar..."
  done
  }
  
