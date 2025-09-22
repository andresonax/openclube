const conection = require("../../../../config/database"); // ATENCÃO A ESTE PATH!!!
const { fetch } = require("./inter");
const criarPixEndpoint = "pix/v2/cob";
const registraWebhookEndpoint = "pix/v2/webhook";

//Obtém o txidStr
const getTxidStr = (txid, tipo_pix) => {
  var txidStr = "CA"+"1" + tipo_pix + "" + txid + "1";
  txidStr = txidStr.padEnd(35, "0");
  return txidStr;
};

//Atualiza o txid atual
const atualizaTxidAtual = async (id_bancario, txid_atual) => {
  return await new Promise((resolve, reject) => {
    conection.query(
      "UPDATE dados_banco SET txid_atual = ? WHERE id_bancario = ?",
      [txid_atual, id_bancario],
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

//Cria um pix
const criaPix = async (dadosBanco, dadosPix) => {

  var txid = parseInt(dadosBanco.txid_atual);
  var txidStr = getTxidStr(txid, dadosPix.tipo_pix);

  const data = {
    calendario: {
      expiracao: dadosPix.expiracao_minutos * 60,
    },
    devedor: {
      cpf: dadosPix.cpf,
      nome: dadosPix.nome,
    },
    valor: {
      original: dadosPix.valor.toFixed(2),
    },
    chave: dadosBanco.chave_pix,
    solicitacaoPagador: dadosPix.solicitacaoPagador,
  };

  const results = await fetch(`${criarPixEndpoint}/${txidStr}`, "PUT", data);
  //Atualiza novo txid
  await atualizaTxidAtual(dadosBanco.id_bancario, txid + 1);

  return {
    txid: txidStr,
    chave: dadosBanco.chave_pix,
    texto_qr_code: results.pixCopiaECola,
    valor: dadosPix.valor,
  };
};

//Obtém dados da empresa
const getEmpresa = async () => {
  return await new Promise((resolve, reject) => {
    conection.query("SELECT * FROM empresa", (error, results) => {
      if (error) {
        reject(error);
      } else {
        resolve(results);
      }
    });
  });
};

//Registra a url callback no webhook de pagamento
//ou seja, mostra pro banco que a url de webhook é x
const registraCallback = async (dadosBanco) => {
  console.log("registraCallback Inter PIX");
  //const [empresa] = await getEmpresa();
  const endpoint = "webhooks/inter/pix";
  //const urlCallback = `${empresa.endereco_servidor}/${endpoint}`;
  const urlCallback = `https://back.sonaxesportes.com.br:2021/${endpoint}`;
  return await fetch(
    `${registraWebhookEndpoint}/${dadosBanco.chave_pix}`,
    "PUT",
    {
      webhookUrl: urlCallback,
    }
  );
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

//Realiza a devolução de um pix
const estornaPix = async (e2eid, id_devolucao) => {
  console.log(
    `Estorno PIX Inter: e2eid= ${e2eid} / id_devolucao= ${id_devolucao}`
  );
  const route = `pix/v2/pix/${e2eid}/devolucao/${id_devolucao}`;
  return await fetch(route, "PUT");
};

module.exports = {
  criaPix,
  registraCallback,
  estornaPix,
};
