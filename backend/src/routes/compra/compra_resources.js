const connection = require("../../config/database");
const moment = require("moment");
const receitaMethods = require("../financeiro/receitas_methods.js");
const usuarioMethods = require("../usuario_app/usuario_app_methods");
const { excludePix } = require("../financeiro/pix/pix.js");
const { enviaAlertaCompra } = require("../alertas/alertas_methods.js");
const { dataHoraToMoment } = require("../../utils/utils.js");

//Insere a compra no banco
const insertCompra = async (
  id_usuario,
  tipo_usuario,
  tipo_pagamento,
  valor_total,
  data_agenda,
  nome_responsavel,
) => {
  return await new Promise((resolve, reject) => {
    connection.query(
      "INSERT INTO l_compra(id_usuario, tipo_usuario, data_hora_compra, valor_total, situacao, tipo_pagamento, data_agenda, nome_responsavel) VALUES (?, ?, ?, ?, ?, ?, ?, ?);",
      [
        id_usuario,
        tipo_usuario,
        moment().format("YYYY-MM-DD HH:mm:ss"),
        valor_total,
        "ng",
        tipo_pagamento,
        data_agenda,
        nome_responsavel,
      ],
      (error, results) => {
        if (error) reject(error);
        else resolve(results.insertId);
      }
    );
  });
};

//Atualiza o id_conta da receita associada à compra
const updateReceita = async (id_compra, id_conta) => {
  return await new Promise((resolve, reject) => {
    connection.query(
      "UPDATE l_compra SET id_conta = ? WHERE id_compra = ?",
      [id_conta, id_compra],
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

//Cria receita para a compra
const createReceita = async (id_compra, id_usuario, valor, documento) => {
  const dataReceita = {
    descricao: `Receita de locação ` + id_compra,
    id_dest_origem: id_usuario,
    id_categoria: -6,
    dataVencimento: moment().format("YYYY-MM-DD"),
    dataBaixa: null,
    valorPrevisto: valor,
    recebido: "n",
    observacao: "",
    id_usuario_cad: null,
    id_usuario_baixa: null,
    valorBaixa: null,
    acrescimos: 0,
    descontos: 0,
    documento: documento,
  };
  const resultReceita = await receitaMethods.createReceita(dataReceita);
  await updateReceita(id_compra, resultReceita.insertId);
};

//Relaciona agenda com compra
const relateAgendaCompra = async (id_compra, id_agenda) => {
  return await new Promise((resolve, reject) => {
    connection.query(
      "INSERT INTO l_agenda_compra(id_compra, id_agenda) VALUES(?, ?);",
      [id_compra, id_agenda],
      (error, results) => {
        if (error) reject(error);
        else resolve(results);
      }
    );
  });
};

//Cria uma compra interna (gerada a partir dos agendamentos)
const createCompraInterna = async (
  id_agenda,
  id_usuario,
  tipo_usuario,
  valor,
  data_agenda,
  nome_responsavel
) => {
  const id_compra = await insertCompra(
    id_usuario,
    tipo_usuario,
    null,
    valor,
    data_agenda,
    nome_responsavel
  );
  await relateAgendaCompra(id_compra, id_agenda);
  await createReceita(id_compra, id_usuario, valor, null);
  return id_compra;
};

//Seleciona compras por agenda e data
const selectComprasByAgendaAndData = async (id_agenda, data) => {
  return await new Promise((resolve, reject) => {
    connection.query(
      "SELECT * FROM l_compra c INNER JOIN l_agenda_compra ac ON ac.id_compra = c.id_compra INNER JOIN l_agenda a ON a.id_agenda = ac.id_agenda WHERE a.id_agenda = ? AND (NOT a.repeticao OR c.data_agenda = ?);",
      [id_agenda, data],
      (error, results) => {
        if (error) reject(error);
        else resolve(results);
      }
    );
  });
};

//Lê compras por agenda e data, adicionando o nome do usuário
const readComprasByAgendaAndData = async (id_agenda, data) => {
  const compraList = await selectComprasByAgendaAndData(id_agenda, data);
  for (var i = 0; i < compraList.length; i++) {
    const dadosUsuario = await usuarioMethods.getDadosUsuario(
      compraList[i].id_usuario,
      compraList[i].tipo_usuario
    );
    compraList[i].nome_usuario = dadosUsuario.nome;
  }
  return compraList;
};

//Seleciona compras por agenda
const selectComprasByAgenda = async (id_agenda) => {
  return await new Promise((resolve, reject) => {
    connection.query(
      "SELECT c.*, horario, horario_final FROM l_compra c INNER JOIN l_agenda_compra ac ON ac.id_compra = c.id_compra INNER JOIN l_agenda a ON a.id_agenda = ac.id_agenda WHERE a.id_agenda = ?;",
      [id_agenda],
      (error, results) => {
        if (error) reject(error);
        else resolve(results);
      }
    );
  });
};

//Lê compras por agenda e data, adicionando o nome do usuário
const readComprasByAgenda = async (id_agenda) => {
  const compraList = await selectComprasByAgenda(id_agenda);
  for (var i = 0; i < compraList.length; i++) {
    const dadosUsuario = await usuarioMethods.getDadosUsuario(
      compraList[i].id_usuario,
      compraList[i].tipo_usuario
    );
    compraList[i].nome_usuario = dadosUsuario.nome;
  }
  return compraList;
};

//Atualiza a compra com a geração de um pix
const updateCompraPix = async (id_compra, id_pix, situacao, tipo_pagamento) => {
  return await new Promise((resolve, reject) => {
    connection.query(
      "UPDATE l_compra SET id_pix = ?, situacao = ?, tipo_pagamento = ? WHERE id_compra = ?",
      [id_pix, situacao, tipo_pagamento, id_compra],
      (error, results) => {
        if (error) reject(error);
        else resolve(results);
      }
    );
  });
};

//Deleta pix da compra
const deletePixCompra = async (compra) => {
  await updateCompraPix(compra.id_compra, null, "pa", null);
  await excludePix(compra.id_pix);
};

//Deleta pagamentos da compra, se existirem
const deletePagamentos = async (compra) => {
  if (!compra.tipo_pagamento) return;
  if (compra.tipo_pagamento == 1 && compra.id_pix)
    await deletePixCompra(compra);
};

//Atualiza a receita da compra
const updateCompraReceita = async (id_compra, id_conta) => {
  return await new Promise((resolve, reject) => {
    connection.query(
      "UPDATE l_compra SET id_conta = ? WHERE id_compra = ?",
      [id_conta, id_compra],
      (error, results) => {
        if (error) reject(error);
        else resolve(results);
      }
    );
  });
};

//Deleta a parte financeira de uma compra (pagamentos e receita)
const deleteFinanceiro = async (id_compra) => {
  const [compra] = await readCompraById(id_compra);
  //Deleta pagamentos
  await deletePagamentos(compra);
  //Deleta receita, se existir
  if (compra.id_conta) {
    await updateCompraReceita(compra.id_compra, null);
    await receitaMethods.deleteReceita(compra.id_conta);
  }
};

//Realiza deleção da compra do banco de dados
const deleteCompra = async (id_compra) => {
  return await new Promise((resolve, reject) => {
    connection.query(
      "DELETE FROM l_compra WHERE id_compra = ?;",
      [id_compra],
      (error, results) => {
        if (error) reject(error);
        else resolve(results);
      }
    );
  });
};

//Deleta a relação de compra com agenda
const deleteRelationAgendaCompra = async (id_compra, id_agenda) => {
  return await new Promise((resolve, reject) => {
    connection.query(
      "DELETE FROM l_agenda_compra WHERE id_compra = ? AND id_agenda = ?;",
      [id_compra, id_agenda],
      (error, results) => {
        if (error) reject(error);
        else resolve(results);
      }
    );
  });
};

//Deleta todas as relações com agendas de certa compra
const deleteAllRelationAgendaCompra = async (id_compra) => {
  return await new Promise((resolve, reject) => {
    connection.query(
      "DELETE FROM l_agenda_compra WHERE id_compra = ?;",
      [id_compra],
      (error, results) => {
        if (error) reject(error);
        else resolve(results);
      }
    );
  });
};

//Exclui a compra sem deletar a agenda
const excludeCompraWithoutAgenda = async (id_compra) => {
  await deleteFinanceiro(id_compra);
  await deleteAllRelationAgendaCompra(id_compra);
  await deleteCompra(id_compra);
};

//Lê compra por id
const readCompraById = async (id_compra) => {
  return await new Promise((resolve, reject) => {
    connection.query(
      "SELECT * FROM l_compra WHERE id_compra = ?;",
      [id_compra],
      (error, results) => {
        if (error) reject(error);
        else {
          //Converte a data para moment
          if (results.length)
            results[0].data_hora_compra = dataHoraToMoment(
              results[0].data_hora_compra
            );
          resolve(results);
        }
      }
    );
  });
};

//Efetua baixa no banco
const realizaBaixa = async (id_compra, valor_pago) => {
  return await new Promise((resolve, reject) => {
    connection.query(
      "UPDATE l_compra SET data_hora_pagamento = ?, valor_pago = ?, situacao = ? WHERE id_compra = ?",
      [moment().format(), valor_pago, "pa", id_compra],
      (error, results) => {
        if (error) reject(error);
        else resolve(results);
      }
    );
  });
};

//Dá baixa na receita da compra
const baixaReceitaManual = async (id_conta, dados) => {
  const receita = await receitaMethods.getReceita(id_conta);
  if (!receita) return;
  const baixa = {
    movimentoCaixa: "s",
    valorBaixa: dados.valor_pago,
    dataBaixa: moment().format("YYYY-MM-DD"),
    id_usuario_baixa: dados.id_usuario_baixa,
    descontos: dados.descontos,
    acrescimos: dados.acrescimos,
    valorPrevisto: receita.valorPrevisto,
    id_categoria: -6,
    descricao: "Baixado manualmente",
  };
  return await receitaMethods.fazBaixa(id_conta, baixa);
};

//Envia alertas da compra
const enviaAlertasBaixaCompra = async (id_compra) => {
  try {
    await enviaAlertaCompra(id_compra);
  } catch (error) {
    console.error(error);
    console.error(
      "Não foi possível enviar os alertas para compra de ID: ",
      id_compra
    );
  }
};

//Realiza baixa manual da compra
const baixarManual = async (dados) => {
  //Carrega compra
  const [compra] = await readCompraById(dados.id_compra);
  //Apaga pagamentos da compra
  await deletePagamentos(compra);
  //Faz baixa da compra
  await realizaBaixa(compra.id_compra, dados.valor_pago);
  //Faz baixa da receita
  const results = await baixaReceitaManual(compra.id_conta, dados);
  //Envia os alertas
  await enviaAlertasBaixaCompra(compra.id_compra);
  //Retorna
  return results;
};

module.exports = {
  insertCompra,
  createReceita,
  relateAgendaCompra,
  createCompraInterna,
  readComprasByAgendaAndData,
  readComprasByAgenda,
  deleteFinanceiro,
  deleteCompra,
  updateCompraPix,
  deletePagamentos,
  deleteRelationAgendaCompra,
  excludeCompraWithoutAgenda,
  readCompraById,
  baixarManual,
  enviaAlertasBaixaCompra,
};
