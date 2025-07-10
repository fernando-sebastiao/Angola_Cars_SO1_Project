registrar_log() {
  local tipo="$1"
  local mensagem="$2"
  local log_dir="logs"
  local log_file="$log_dir/sistema.log"
  local data_hora=$(date "+%Y-%m-%d %H:%M:%S")

 # mkdir -p "$log_dir"
  echo "[$data_hora] [$tipo] $mensagem" >> "$log_file"
}

cadastrar_funcionario() {
  clear
  echo "***** Cadastrar Novo Funcionário *******"

  # Cria arquivo com cabeçalho se não existir
  if [ ! -f usuarios.csv ]; then
    echo "ID;usuario;senha;funcao;telefone;morada;filial_id" > usuarios.csv
  fi

  ultimo_id=$(tail -n +2 usuarios.csv | cut -d';' -f1 | sort -n | tail -1)
  if [ -z "$ultimo_id" ]; then
    novo_id="01"
  else
    novo_id=$(printf "%02d" $((10#$ultimo_id + 1)))
  fi

  read -p "Nome: " nome
  read -s -p "Senha: " senha
  echo

  echo "Selecione a função:"
  echo "[1] Admin"
  echo "[2] Vendas"
  echo "[3] Recepção"
  read -p "Opção: " funcao_opcao
  case "$funcao_opcao" in
    1) funcao="Admin" ;;
    2) funcao="Vendas" ;;
    3) funcao="Recepcao" ;;
    *) echo "Função inválida."; sleep 2; return ;;
  esac

  read -p "Telefone: " telefone
  read -p "Morada: " morada
  read -p "Filial_Id (ENTER para sede): " filial_id

  if [ -z "$filial_id" ]; then
    filial_id=""
  else
    if ! grep -q "^$filial_id;" filiais.csv; then
      echo "Filial com ID $filial_id não encontrada!"
      sleep 2
      return
    fi
  fi

  echo "$novo_id;$nome;$senha;$funcao;$telefone;$morada;$filial_id" >> usuarios.csv
  echo "Funcionário cadastrado com sucesso! (ID: $novo_id)"
  registrar_log "Admin" "Cadastrou com sucesso" "Sucesso"
  sleep 2
}



eliminar_usuario() {
  clear
  echo "****** REMOÇÃO DE USUÁRIO ******"
  echo

  if [ ! -f usuarios.csv ]; then
    echo "Arquivo usuarios.csv não encontrado!"
    sleep 2
    return
  fi

  read -p "Informe o ID do usuário a remover: " id

  # Verifica se o ID existe (ignorando cabeçalho)
  if ! tail -n +2 usuarios.csv | grep -q "^$id;"; then
    echo "Usuário com ID $id não encontrado."
    sleep 2
    return
  fi

  # Confirmação
  read -p "Tem certeza que deseja remover o usuário com ID $id? (s/n): " confirm
  if [ "$confirm" != "s" ]; then
    echo "Operação cancelada."
    sleep 2
    return
  fi

  # Remove a linha correspondente e recria o ficheiro mantendo o cabeçalho
  head -n 1 usuarios.csv > tmp_usuarios.csv
  tail -n +2 usuarios.csv | grep -v "^$id;" >> tmp_usuarios.csv
  mv tmp_usuarios.csv usuarios.csv

  echo "Usuário com ID $id removido com sucesso."
  registrar_log "Funcionario com $id" "Removido com sucesso" "Sucesso"
  sleep 2
}

listar_usuarios() {
  clear
  echo "****** LISTA DE USUÁRIOS CADASTRADOS *******"
  echo

  if [ ! -f usuarios.csv ]; then
    echo "Arquivo usuarios.csv não encontrado!"
    sleep 2
    return
  fi

  total=$(wc -l < usuarios.csv)
  if [ "$total" -le 1 ]; then
    echo "Nenhum usuário cadastrado."
    sleep 2
    return
  fi

  # Cabeçalho formatado
  IFS=";" read -r idh usuarioh senhah funcaoh telefoneh moradah filialh < <(head -1 usuarios.csv)
  printf "%-4s %-15s %-10s %-10s %-12s %-20s %-10s\n" "$idh" "$usuarioh" "SENHA" "$funcaoh" "$telefoneh" "$moradah" "$filialh"

  # Linhas com os dados
  tail -n +2 usuarios.csv | while IFS=";" read -r id usuario senha funcao telefone morada filial_id; do
    printf "%-4s %-15s %-10s %-10s %-12s %-20s %-10s\n" "$id" "$usuario" "$senha" "$funcao" "$telefone" "$morada" "$filial_id"
  done

  echo
  read -p "ENTER para voltar..."
}

editar_usuario() {
  clear
  echo "***** EDITAR USUÁRIO *****"
  echo

  if [ ! -f usuarios.csv ]; then
    echo "Arquivo usuarios.csv não encontrado!"
    sleep 2
    return
  fi

  read -p "Informe o ID do usuário que deseja editar: " id

  # Verifica se o ID existe
  linha=$(tail -n +2 usuarios.csv | grep "^$id;")
  if [ -z "$linha" ]; then
    echo "Usuário com ID $id não encontrado."
    sleep 2
    return
  fi

  # Pega os valores atuais
  usuario_atual=$(echo "$linha" | cut -d';' -f2)
  senha_atual=$(echo "$linha" | cut -d';' -f3)
  funcao_atual=$(echo "$linha" | cut -d';' -f4)
  telefone_atual=$(echo "$linha" | cut -d';' -f5)
  morada_atual=$(echo "$linha" | cut -d';' -f6)
  filial_atual=$(echo "$linha" | cut -d';' -f7)

  echo "Deixe em branco para manter o valor atual."

  read -p "Novo nome de usuário [$usuario_atual]: " usuario
  read -p "Nova senha [$senha_atual]: " senha
  read -p "Nova função(Admin/Vendas/Recepcao) [$funcao_atual]: " funcao
  read -p "Novo telefone [$telefone_atual]: " telefone
  read -p "Nova morada [$morada_atual]: " morada
  read -p "Nova filial_id [$filial_atual]: " filial_id

  # Usa os valores antigos se novos estiverem vazios
  usuario="${usuario:-$usuario_atual}"
  senha="${senha:-$senha_atual}"
  funcao="${funcao:-$funcao_atual}"
  telefone="${telefone:-$telefone_atual}"
  morada="${morada:-$morada_atual}"
  filial_id="${filial_id:-$filial_atual}"

  # Atualiza o arquivo
  head -n 1 usuarios.csv > tmp_usuarios.csv
  tail -n +2 usuarios.csv | grep -v "^$id;" >> tmp_usuarios.csv
  echo "$id;$usuario;$senha;$funcao;$telefone;$morada;$filial_id" >> tmp_usuarios.csv
  mv tmp_usuarios.csv usuarios.csv

  echo "Usuário com ID $id foi atualizado com sucesso!"
  registrar_log "$name" "Editado com sucesso" "Sucesso"
  sleep 2
}

menu_usuarios() {
  while true; do
    clear
    echo "******* MENU DE FUNCIONÁRIOS *******"
    echo "[1] Cadastrar funcionario"
    echo "[2] Listar funcionario"
    echo "[3] Editar funcionario"
    echo "[4] Eliminar funcionario"
    echo "[0] Voltar"
    read -p "Opção: " op
    case $op in
      1) cadastrar_funcionario;;
      2) listar_usuarios;;
      3) editar_usuario;;
      4) eliminar_usuario;;
      0) break ;;
      *) echo "Opção inválida!"; sleep 1 ;;
    esac
  done
}

