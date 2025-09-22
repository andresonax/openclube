const conection = require("../../../config/database"); // ATENCÃO A ESTE PATH!!!
const moment = require("moment");
const utils = require("../../../utils/utils");
const bank = {};
bank[utils.banks.bb] = require("../banks/bb/bb_pix");
bank[utils.banks.inter] = require("../banks/inter/inter_pix");
const { baixaCompraByIdPix } = require("../../compra/compra_webhook");
//const pagamentoTorneioWebhook = require("../../torneios/pagamento_torneio/pagamento_webhook");

//Insere pix no banco
const insertPixEntry = async (pixData, id_banco) => {
  return await new Promise((resolve, reject) => {
    conection.query(
      "INSERT INTO pix(txid, chave, texto_qr_code, valor, id_banco, data_hora_geracao, expiracao_minutos) VALUES(?, ?, ?, ?, ?, ?, ?);",
      [
        pixData.txid,
        pixData.chave,
        pixData.texto_qr_code,
        pixData.valor,
        id_banco,
        pixData.data_hora_geracao,
        pixData.expiracao_minutos,
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

//Pega dados do banco
const getDadosBanco = async (id_cliente) => {

  return await new Promise((resolve, reject) => {
    conection.query(
      "SELECT * FROM dados_banco WHERE id_cliente = ?",
      [id_cliente],
      (error, results) => {
        if (error) reject(error);
        else {
          try {
            resolve(results[0]);
          } catch (error) {
            reject(error);
          }
        }
      }
    );
  });
};

//Pega pix pelo id
const getPix = async (id_pix) => {
  return await new Promise((resolve, reject) => {
    conection.query(
      "SELECT * FROM pix WHERE id_pix = ?",
      [id_pix],
      (error, results) => {
        if (error) {
          reject(error);
        } else {
          try {
            resolve(results[0]);
          } catch (error) {
            reject(error);
          }
        }
      }
    );
  });
};

//Pega pix pelo txid
const getPixByTxid = async (txid) => {
  return await new Promise((resolve, reject) => {
    conection.query(
      "SELECT * FROM pix WHERE txid = ?",
      [txid],
      (error, results) => {
        if (error) {
          reject(error);
        } else {
          try {
            resolve(results[0]);
          } catch (error) {
            reject(error);
          }
        }
      }
    );
  });
};

/*
  PARAMETRO:
  dadosPix = {
    cpf,
    nome,
    valor,
    solicitacaoPagador(mensagem),
    tipo_pix: 1(Locação) / 2 (Torneio)
  }

  SAIDA:
  pixData = {
    id_pix,
    valor,
    txid,
    chave,
    texto_qr_code
  }
*/
//Gera pix
const gerarPix = async (id_cliente, dadosPix) => {
  console.log('no arquivo pix.js');
  console.log(dadosPix);
  const dadosBanco = await getProcessedDadosBanco(id_cliente);
  dadosPix.data_hora_geracao = moment().format();
  const pixData = await bank[dadosBanco.num_banco].criaPix(
    dadosBanco,
    dadosPix
  );
  pixData.data_hora_geracao = moment().format("YYYY-MM-DD HH:mm:ss");
  pixData.expiracao_minutos = dadosPix.expiracao_minutos;
  const { insertId } = await insertPixEntry(pixData, dadosBanco.id_bancario);
  pixData.id_pix = insertId;
  return pixData;
};

//Deleta pix
const deletePix = async (id_pix) => {
  return await new Promise((resolve, reject) => {
    conection.query(
      "DELETE FROM pix WHERE id_pix = ?",
      id_pix,
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

//Exclui o pix, realizando o estorno antes se for necessário
const excludePix = async (id_pix) => {
  const pix = await getPix(id_pix);
  if (pix.valor_pago) await estornaPix(id_pix);
  await deletePix(id_pix);
};

//Pega os dados do banco e verifica se o banco possui integração com Pix
const getProcessedDadosBanco = async (id_cliente) => {
  const dadosBanco = await getDadosBanco(id_cliente);
  if (dadosBanco) {
    if (!bank[dadosBanco.num_banco])
      throw { msg: "Banco não possui integração com Pix!" };
    return dadosBanco;
  } else {
    throw { msg: "Banco não existente!" };
  }
};

//Aplica delay
const delay = async (time) => {
  return await new Promise((resolve, reject) => {
    setTimeout(resolve, time);
  });
};

//Emite pix em massa
const emitirEmMassa = async (lotePix, id_banco) => {
  const dadosBanco = await getProcessedDadosBanco(id_banco);
  const respostas = [];
  const dataGeracao = moment().format("YYYY-MM-DD HH:mm:ss");
  for (var i = 0; i < lotePix.length; i++) {
    var resposta;
    try {
      const pixData = await bank[dadosBanco.num_banco].criaPix(
        dadosBanco,
        lotePix[i]
      );
      pixData.expiracao_minutos = lotePix[i].expiracao_minutos;
      pixData.data_hora_geracao = dataGeracao;
      const { insertId } = await insertPixEntry(pixData, id_banco);
      resposta = {
        success: true,
        id_pix: insertId,
        ...lotePix[i],
        ...pixData,
      };
    } catch (error) {
      console.error(error);
      resposta = {
        success: false,
        info: error.msg,
        ...lotePix[i],
      };
    }
    respostas.push(resposta);
    await delay(200);
  }
  return respostas;
};

//Verifica se o pix está expirado
const checkPixExpirado = (pix) => {
  const horaExpiracao = moment(pix.data_hora_geracao, "YYYY-MM-DD HH:mm:ss")
    .add(pix.expiracao_minutos, "minutes")
    .add(3, "hours");
  const agora = moment();
  return agora >= horaExpiracao && !pix.valor_pago;
};

//Visualiza o pix e verifica se está expirado
const visualizarPix = async (id_pix) => {
  const pix = await getPix(id_pix);
  if (!checkPixExpirado(pix)) return pix;
  else
    throw {
      expirado: true,
      msg: "Pix expirado!",
    };
};

//Realiza a baixa do pix
const baixaPix = async (id_pix, baixa) => {
  return await new Promise((resolve, reject) => {
    conection.query(
      "UPDATE pix SET valor_pago = ?, data_hora_pagamento = ? WHERE id_pix = ?",
      [baixa.valor_pago, baixa.data_hora_pagamento, id_pix],
      (error, results) => {
        if (error) reject(error);
        else resolve(results);
      }
    );
  });
};

//Realiza a baixa do pix pelo callback
const baixaPixCallback = async (id_pix, e2eid, valor_pago) => {
  return await new Promise((resolve, reject) => {
    conection.query(
      "UPDATE pix SET e2eid = ?, valor_pago = ?, data_hora_pagamento = ? WHERE id_pix = ?",
      [e2eid, valor_pago, moment().format(), id_pix],
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

//Processa o recebimento do callback de baixa de pix
const processCallbackBaixaPix = async (txid, e2eid, valor_pago) => {
  const pix = await getPixByTxid(txid);
  await baixaPixCallback(pix.id_pix, e2eid, valor_pago);
  const digito = txid.substr(1, 1);
  if (digito == "1") {
    await baixaCompraByIdPix(pix.id_pix, { valor_pago });
  } else if (digito == "2") {
    await pagamentoTorneioWebhook.baixaTorneioByIdPix(pix.id_pix, {
      valor_pago,
    });
  }
  console.log(`Baixa de pix ${txid} feita!`);
  return "Baixa feita";
};

//Atualiza as informações de devolução do pix
const updateDevolucaoPix = async (id_pix, id_devolucao) => {
  return await new Promise((resolve, reject) => {
    conection.query(
      "UPDATE pix SET id_devolucao = ?, data_hora_devolucao = ? WHERE id_pix = ?",
      [id_devolucao, moment().format("YYYY-MM-DD HH:mm:ss"), id_pix],
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

//Atualiza o id_devolucao atual do banco
const updateCurrentIdDevolucao = async (id_banco, newIdDevolucao) => {
  return await new Promise((resolve, reject) => {
    conection.query(
      "UPDATE dados_banco SET current_id_devolucao = ? WHERE id_bancario = ?",
      [newIdDevolucao, id_banco],
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

//Realiza o estorno do pix
const estornaPix = async (id_pix) => {
  const pix = await getPix(id_pix);
  const dadosBanco = await getDadosBanco(pix.id_banco);
  //Se banco não possui função de estorno, retorna mensagem de erro
  if (!bank[dadosBanco.num_banco].estornaPix)
    throw {
      msg: "Banco não possui estorno de Pix implementado!",
    };
  const results = await bank[dadosBanco.num_banco].estornaPix(
    pix.e2eid,
    dadosBanco.current_id_devolucao
  );
  await updateDevolucaoPix(id_pix, dadosBanco.current_id_devolucao);
  const newIdDevolucao = dadosBanco.current_id_devolucao + 1;
  await updateCurrentIdDevolucao(pix.id_banco, newIdDevolucao);
  return results;
};

module.exports = {
  visualizarPix,
  gerarPix,
  excludePix,
  getPix,
  getPixByTxid,
  emitirEmMassa,
  checkPixExpirado,
  baixaPix,
  processCallbackBaixaPix,
  estornaPix,
};
