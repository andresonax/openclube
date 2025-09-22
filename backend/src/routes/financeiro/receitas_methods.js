const conection = require("../../config/database"); // ATENCÃO A ESTE PATH!!!
const moment = require("moment");
const utils = require("../../utils/utils");

const {
  getDadosUsuario,
} = require("../usuario_app/usuario_app_methods");



const insertInLivroFinanceiro = async (id_conta, baixa) => {
  return await new Promise((resolve, reject) => {
    conection.query(
      `INSERT INTO l_livrofinanceiro (` +
        ` id_categoria , ` +
        ` id_conta , ` +
        ` valorPrevisto , ` +
        ` dataLancamento , ` +
        ` codUsuario , ` +
        ` recebido , ` +
        ` valorTotal , ` +
        ` descricao  ` +
        ` )VALUES( ` +
        ` ${baixa.id_categoria}, ` +
        ` ${id_conta}, ` +
        ` ${baixa.valorPrevisto}, ` +
        ` '${baixa.dataBaixa + " " + baixa.hoje}', ` +
        ` ${baixa.id_usuario_baixa}, ` +
        ` 1, ` +
        ` ${baixa.valorBaixa}, ` +
        ` '${baixa.descricao}') `,

      (error, results) => {
        if (error) reject(error);
        else resolve(results);
      }
    );
  });
};

const applyBaixaReceita = async (id_conta, baixa) => {
  return await new Promise((resolve, reject) => {
    let sql =
      "UPDATE receitas_despesas SET dataBaixa = ?,  " +
      " acrescimos = ?, descontos = ?, valorBaixa = ?, id_usuario_baixa = ?, recebido = ?, id_livro = ? WHERE id_conta = ?";
    conection.query(
      sql,
      [
        baixa.dataBaixa,
        baixa.acrescimos,
        baixa.descontos,
        baixa.valorBaixa,
        baixa.id_usuario_baixa,
        baixa.recebido,
        baixa.id_livro,
        id_conta,
      ],
      (error, results) => {
        if (error) reject(error);
        else resolve(results);
      }
    );
  });
};

/*baixa = {
  valorBaixa: double,
  movimentoCaixa: string ('s'),
  dataBaixa: string,
  id_usuario_baixa: number,
  descontos: number,
  acrescimos: number,
  valorPrevisto: number,
  id_categoria: number,
  descricao: string,
}*/
const fazBaixa = async (id_conta, baixa) => {
  baixa.descontos = parseFloat(baixa.descontos);
  baixa.acrescimos = parseFloat(baixa.acrescimos);
  baixa.valorPrevisto = parseFloat(baixa.valorPrevisto);
  baixa.id_categoria = parseFloat(baixa.id_categoria);
  baixa.recebido = "s";
  baixa.hoje = moment().format("HH:mm:ss");
  const results = await insertInLivroFinanceiro(id_conta, baixa);
  baixa.id_livro = results.insertId;
  if (baixa.movimentoCaixa === "s") {
    return await applyBaixaReceita(id_conta, baixa);
  } else {
    return results;
  }
};

const deleteReceita = async (id_conta) => {
  return await new Promise((resolve) =>
    conection.query(
      "DELETE FROM receitas_despesas where id_conta = ?",
      [id_conta],
      (error, results) => {
        if (error) {
          console.error("Error on DELETE BY ID receitas_despesas:");
          console.error(error);
          error.err = true;
          resolve(error);
        } else {
          resolve(results);
        }
      }
    )
  );
};

const createReceita = async (data) => {
  return await new Promise((resolve, reject) => {
    const descricao = data.descricao.substring(0, 30);
    const id_dest_origem = data.id_dest_origem;
    const id_categoria = data.id_categoria;
    const dataVencimento = data.dataVencimento;
    const dataBaixa = null;
    const valorPrevisto = data.valorPrevisto;
    const recebido = "n";
    const observacao = data.observacao;
    const id_usuario_cad = data.id_usuario_cad;
    const id_usuario_baixa = null;
    const valorBaixa = null;
    const acrescimos = data.acrescimos;
    const descontos = data.descontos;
    const documento = data.documento;

    conection.query(
      "INSERT INTO receitas_despesas(descricao, id_dest_origem,id_categoria, dataVencimento, dataBaixa, valorPrevisto, recebido, observacao,id_usuario_cad, id_usuario_baixa, valorBaixa, acrescimos, descontos, documento) " +
        " values(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
      [
        descricao,
        id_dest_origem,
        id_categoria,
        dataVencimento,
        dataBaixa,
        valorPrevisto,
        recebido,
        observacao,
        id_usuario_cad,
        id_usuario_baixa,
        valorBaixa,
        acrescimos,
        descontos,
        documento,
      ],
      (error, results) => {
        if (error) {
          reject(error);
        } else {
          resolve(results);
        }
      }
    );
  });
};

const getReceita = async (id_conta) => {
  return await new Promise((resolve, reject) => {
    conection.query(
      "SELECT * FROM receitas_despesas WHERE id_conta = ?",
      [id_conta],
      (error, results) => {
        if (error) {
          reject(error);
        } else {
          resolve(results[0]);
        }
      }
    );
  });
};

//Obtém o SQL para busca de receitas
const getSqlSelectReceitas = (ano, mes) => {
  var sql =
    "SELECT id_conta, boleto, id_bancario, numero_deles, id_dest_origem, receitas_despesas.id_categoria, id_livro, receitas_despesas.descricao, DATE_FORMAT(dataVencimento, '%d/%m/%Y') as dataVencimento, " +
    " ifnull(dataBaixa, DATE_FORMAT(dataBaixa, '%d/%m/%Y')) as dataBaixa, valorPrevisto, recebido, observacao, anexo, id_usuario_baixa, id_usuario_cad, " +
    " valorBaixa, acrescimos, descontos, documento, tipo, " +
    " if(recebido = 'n', if(convert(dataVencimento, date) = convert(now(),date), 'Aberto - Vencendo Hoje', " +
    "if(convert(dataVencimento, date) > convert(now(),date), 'Aberto', 'Aberto - Vencido')), 'Baixado') as status " +
    " FROM receitas_despesas inner join categoriafinanceiro on receitas_despesas.id_categoria = categoriafinanceiro.id_categoria";
  if (ano != -1 || mes != -1) sql += " WHERE";
  if (ano != -1) {
    sql += ` YEAR(dataVencimento) = ${ano}`;
    if (mes != -1) sql += " AND";
  }
  if (mes != -1) sql += ` MONTH(dataVencimento) = ${mes}`;
  return sql;
};

//Seleciona as receitas
const selectReceitas = (ano, mes) => {
  return new Promise((resolve, reject) => {
    conection.query(getSqlSelectReceitas(ano, mes), (error, results) => {
      if (error) reject(error);
      else resolve(results);
    });
  });
};

//Lê os clientes
const readClientes = () => {
  return new Promise((resolve, reject) => {
    conection.query("SELECT * FROM fornecedor", (error, results) => {
      if (error) reject(error);
      else resolve(results);
    });
  });
};

//Obtém a compra pelo id da receita
const getCompraByReceita = (id_conta) => {
  return new Promise((resolve, reject) => {
    conection.query(
      "SELECT * FROM l_compra WHERE id_conta = ?",
      [id_conta],
      (error, results) => {
        if (error) reject(error);
        else resolve(results[0]);
      }
    );
  });
};

//Obtém o nome do cliente da locação
const getNomeClienteLocacao = async (id_conta) => {
  const compra = await getCompraByReceita(id_conta);
  if (compra.nome_responsavel) return compra.nome_responsavel;
  const dadosUsuario = await getDadosUsuario(
    compra.id_usuario,
    compra.tipo_usuario
  );
  if (dadosUsuario) return dadosUsuario.nome;
  return "-";
};

//Obtém o nome do cliente de uma receita padrão
const getNomeClienteReceitas = (clienteList, id_dest_origem) => {
  const cliente = clienteList.find(
    (cliente) => cliente.id_cliente === id_dest_origem
  );
  if (cliente) return cliente.razao_social;
  return "-";
};

//Obtém nome do cliente da receita
const getNomeCliente = async (clienteList, receita) => {
  if (receita.id_categoria == -6)
    return await getNomeClienteLocacao(receita.id_conta);
  else return getNomeClienteReceitas(clienteList, receita.id_dest_origem);
};

//Lê as receitas e completa informações
const readReceitas = async (ano, mes) => {
  const receitaList = await selectReceitas(ano, mes);
  const clienteList = await readClientes();
  for (let i = 0; i < receitaList.length; i++) {
    receitaList[i].nome_cliente = await getNomeCliente(
      clienteList,
      receitaList[i]
    );
  }
  return receitaList;
};

module.exports = {
  fazBaixa,
  deleteReceita,
  createReceita,
  getReceita,
  readReceitas,
};
