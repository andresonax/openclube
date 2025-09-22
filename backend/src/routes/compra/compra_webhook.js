const connection = require("../../config/database.js");
const moment = require("moment");
const receitaMethods = require("../financeiro/receitas_methods.js");
const { enviaAlertaCompra } = require("../alertas/alertas_methods.js");

//Localiza a compra pelo id_pix
const readCompraByPix = async (id_pix) => {
  return await new Promise((resolve, reject) => {
    connection.query(
      "SELECT c.* FROM l_compra c INNER JOIN pix p ON c.id_pix = p.id_pix WHERE p.id_pix = ?",
      [id_pix],
      (error, results) => {
        if (error) reject(error);
        else resolve(results);
      }
    );
  });
};

//Efetua baixa parcial no banco
const realizaBaixaParcial = async (id_compra, valor_pago) => {
  return await new Promise((resolve, reject) => {
    connection.query(
      "UPDATE l_compra SET data_hora_pagamento = ?, valor_pago = ?, situacao = ? WHERE id_compra = ?",
      [moment().format(), valor_pago, "pp", id_compra],
      (error, results) => {
        if (error) reject(error);
        else resolve(results);
      }
    );
  });
};

//Efetua baixa no banco
const realizaBaixaTotal = async (id_compra, valor_pago) => {
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

//Baixar a receita pelo pagamento do pix
const baixaReceitaPix = async (id_conta, valor_pago) => {
  const receita = await receitaMethods.getReceita(id_conta);
  //Se não tem conta, sai
  if (!receita) return;
  const dadosBaixa = {
    movimentoCaixa: "s",
    valorBaixa: valor_pago,
    dataBaixa: moment().format("YYYY-MM-DD"),
    id_usuario_baixa: -1,
    descontos: 0,
    acrescimos: 0,
    valorPrevisto: receita.valorPrevisto,
    id_categoria: -6,
    descricao: "Pago por Pix",
  };
  await receitaMethods.fazBaixa(id_conta, dadosBaixa);
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

//Baixar a compra pelo pagamento do pix
/*
  dadosPagamento={
    valor_pago: number
  }
*/
const baixaCompraByIdPix = async (id_pix, dadosPagamento) => {
  const [compra] = await readCompraByPix(id_pix);
  //Se pix é para o valor inteiro, dá baixa
  if (compra.valor_total == dadosPagamento.valor_pago) {
    await realizaBaixaTotal(compra.id_compra, dadosPagamento.valor_pago);
    await baixaReceitaPix(compra.id_conta, dadosPagamento.valor_pago);
  } else {
    //Se não, realiza baixa parcial
    await realizaBaixaParcial(compra.id_compra, dadosPagamento.valor_pago);
  }
  await enviaAlertasBaixaCompra(compra.id_compra);
};

module.exports = {
  baixaCompraByIdPix,
};
