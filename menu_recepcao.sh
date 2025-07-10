
criar_cliente_interessado() {
  clear
  echo "===== REGISTRO DE CLIENTE INTERESSADO ====="

  # Verifica se o usuário está autenticado
  if [ ! -f .session ]; then
    echo "Erro: usuário não autenticado."
    sleep 2
    return
  fi

  # Lê os dados da sessão
  IFS=";" read -r USER_ID USER_NOME USER_FILIAL_ID < .session

  # Define o nome da filial
  if [ "$USER_ID" = "1" ]; then
    nome_filial=""
    nome_filial_formatado=""
    filial_id="0"
  else
    nome_filial=$(awk -F';' -v fid="$USER_FILIAL_ID" 'NR > 1 && $1 == fid { print $2 }' filiais.csv)
    nome_filial_formatado=$(echo "$nome_filial" | tr -d '[:space:]')
    filial_id="$USER_FILIAL_ID"
  fi

  # Define os nomes dos arquivos
  nome_arquivo="clientesInteressados${nome_filial_formatado}.csv"
  nome_arquivo_carros="carros${nome_filial_formatado}.csv"

  # Verifica se arquivo de carros da filial existe
  if [ ! -f "$nome_arquivo_carros" ]; then
    echo "Erro: Nenhum carro encontrado para esta filial."
    sleep 2
    return
  fi

  # Cria cabeçalho se arquivo ainda não existir
  if [ ! -f "$nome_arquivo" ]; then
    echo "id_interesse;nome_cliente;telefone;email;carro_interessado;data_interesse;id_filial;nome_funcionario" > "$nome_arquivo"
  fi

  # Gera ID automático
  ultimo_id=$(tail -n +2 "$nome_arquivo" | cut -d';' -f1 | sort -n | tail -1)
  if [ -z "$ultimo_id" ]; then
    novo_id="01"
  else
    novo_id=$(printf "%02d" $((10#$ultimo_id + 1)))
  fi

  # Coletar dados do cliente
  read -p "Nome do cliente: " nome_cliente
  read -p "Telefone: " telefone
  read -p "Email: " email
  read -p "ID do carro de interesse: " carro_id

  # Verifica se o carro existe no arquivo da filial
  carro_existe=$(tail -n +2 "$nome_arquivo_carros" | grep "^$carro_id;")
  if [ -z "$carro_existe" ]; then
    echo "Erro: Carro com ID $carro_id não encontrado nesta filial."
    sleep 2
    return
  fi

  # Data atual
  data_interesse=$(date "+%Y-%m-%d %H:%M:%S")

  # Salva no arquivo
  echo "$novo_id;$nome_cliente;$telefone;$email;$carro_id;$data_interesse;$filial_id;$USER_NOME" >> "$nome_arquivo"
  echo "cliente interessado registrado com sucesso no arquivo: $nome_arquivo"
  sleep 2
}

listar_clientes_interessados() {
  clear
  echo "=== LISTAGEM DE CLIENTES INTERESSADOS ==="

  # Verifica se o usuário está autenticado
  if [ ! -f .session ]; then
    echo "Erro: usuário não autenticado."
    sleep 2
    return
  fi

  # Lê os dados da sessão
  IFS=";" read -r USER_ID USER_NOME USER_FILIAL_ID < .session

  # Define o nome da filial e o nome do arquivo
  if [ "$USER_ID" = "1" ]; then
    nome_filial_formatado=""
    nome_arquivo="clientesInteressados.csv"
  else
    nome_filial=$(awk -F';' -v fid="$USER_FILIAL_ID" 'NR > 1 && $1 == fid { print $2 }' filiais.csv)
    nome_filial_formatado=$(echo "$nome_filial" | tr -d '[:space:]')
    nome_arquivo="clientesInteressados${nome_filial_formatado}.csv"
  fi

  # Verifica se o arquivo existe
  if [ ! -f "$nome_arquivo" ]; then
    echo "Nenhum cliente interessado registrado para esta filial."
    sleep 2
    return
  fi

  total=$(wc -l < "$nome_arquivo")
  if [ "$total" -le 1 ]; then
    echo "Nenhum cliente interessado encontrado."
    sleep 2
    return
  fi

  # Exibe cabeçalho
  IFS=";" read -r idh nomeh telh emailh carroh datah filialh funcionarioh < <(head -1 "$nome_arquivo")
  printf "%-5s %-20s %-15s %-25s %-10s %-20s %-8s %-15s\n" "$idh" "$nomeh" "$telh" "$emailh" "$carroh" "$datah" "$filialh" "$funcionarioh"

  # Exibe dados
  tail -n +2 "$nome_arquivo" | while IFS=";" read -r id nome telefone email carro data_interesse filial_id funcionario; do
    printf "%-5s %-20s %-15s %-25s %-10s %-20s %-8s %-15s\n" "$id" "$nome" "$telefone" "$email" "$carro" "$data_interesse" "$filial_id" "$funcionario"
  done

  echo
  read -p "ENTER para voltar..."
}

listar_clientes_interessados() {
  clear
  echo "=== LISTAGEM DE CLIENTES INTERESSADOS ==="

  # Verifica se usuário está autenticado
  if [ ! -f .session ]; then
    echo "Erro: usuário não autenticado."
    sleep 2
    return
  fi

  # Lê dados da sessão
  IFS=";" read -r USER_ID USER_NOME USER_FILIAL_ID < .session

  # Define nome da filial e arquivo
  if [ "$USER_ID" = "1" ]; then
    nome_filial_formatado=""
  else
    nome_filial=$(awk -F';' -v fid="$USER_FILIAL_ID" 'NR > 1 && $1 == fid { print $2 }' filiais.csv)
    nome_filial_formatado=$(echo "$nome_filial" | tr -d '[:space:]')
  fi

  nome_arquivo="clientesInteressados${nome_filial_formatado}.csv"

  # Verifica se arquivo existe
  if [ ! -f "$nome_arquivo" ]; then
    echo "Nenhum cliente interessado registrado para sua filial."
    sleep 2
    return
  fi

  # Exibe cabeçalho formatado
  printf "%-4s %-20s %-15s %-25s %-10s %-20s %-8s %-15s\n" \
    "ID" "Nome" "Telefone" "Email" "CarroID" "Data Interesse" "Filial" "Funcionário"

  # Lê e exibe cada registro formatado, pulando o cabeçalho
  tail -n +2 "$nome_arquivo" | while IFS=";" read -r id nome telefone email carro data_interesse filial funcionario; do
    printf "%-4s %-20s %-15s %-25s %-10s %-20s %-8s %-15s\n" \
      "$id" "$nome" "$telefone" "$email" "$carro" "$data_interesse" "$filial" "$funcionario"
  done

  echo
  read -p "ENTER para voltar..."
}

menu_recepcao() {
  while true; do
    clear
    echo "@@@@@@@@ MENU RECEPÇÃO - ANGOLA CARS @@@@@@@@@"
    echo "[1] Registrar cliente interessado"
    echo "[2] Listar clientes interessados"
    echo "[0] Sair"
    read -p "Opção: " op
    case $op in
      1) criar_cliente_interessado;;
      2) listar_clientes_interessados;;
      0) break;;
      *) echo "Opção inválida";;
    esac
    read -p "ENTER para continuar..."
  done
  
  }
