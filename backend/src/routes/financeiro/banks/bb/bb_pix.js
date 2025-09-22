const qs = require("qs");
const axios = require("axios");
const conection = require("../../../../config/database");

const getTxidStr = (txid, tipo_pix) => {
  var txidStr = "0" + tipo_pix + "" + txid;
  txidStr = txidStr.padEnd(35, "0");
  return txidStr;
};

const getTokenPix = async (api_url, client_id, client_secret) => {
  var configAuth = {
    url: `https://oauth.${api_url}/oauth/token`,
    method: "POST",
    headers: {
      "Content-Type": "application/x-www-form-urlencoded",
    },
    auth: {
      username: client_id,
      password: client_secret,
    },
    data: qs.stringify({
      grant_type: "client_credentials",
      scope: "cob.read cob.write pix.write pix.read",
    }),
  };

  return await new Promise((resolve, reject) => {
    axios(configAuth)
      .then((data) => {
        resolve(data.data.access_token);
      })
      .catch((e) => {
        console.error(e.response ? e.response.data : e.response);
        reject(e);
      });
  });
};

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

//tipo_pix 1 = Locação / 2 = Torneio
const criaPix = async (dadosBanco, dadosPix) => {
  return await new Promise(async (resolve, reject) => {
    try {
      const token = await getTokenPix(
        dadosBanco.api_url,
        dadosBanco.client_id,
        dadosBanco.client_secret
      );

      var txid = parseInt(dadosBanco.txid_atual);
      var txidStr = getTxidStr(txid, dadosPix.tipo_pix);

      const data = {
        calendario: {
          expiracao: dadosPix.expiracao_minutos,
        },
        devedor: {
          cpf: dadosPix.cpf,
          nome: dadosPix.nome,
        },
        valor: {
          original: dadosPix.valor,
        },
        chave: dadosBanco.chave_pix,
        solicitacaoPagador: dadosPix.solicitacaoPagador,
      };

      var config = {
        url: `https://api.${dadosBanco.api_url}/pix/v1/cobqrcode/${txidStr}`,
        method: "PUT",
        headers: {
          Authorization: `Bearer ${token}`,
        },
        params: {
          "gw-dev-app-key": dadosBanco.developer_key,
        },
        data,
      };

      axios(config)
        .then(async (data) => {
          await atualizaTxidAtual(dadosBanco.id_bancario, txid + 1);
          const returnData = {
            txid: txidStr,
            chave: dadosBanco.chave_pix,
            texto_qr_code: data.data.textoImagemQRcode,
            valor: dadosPix.valor,
          };
          resolve(returnData);
        })
        .catch((e) => {
          if (e.response) {
            e = e.response.data;
            console.error(e);
            if (e.erros) e.msg = e.erros[0].mensagem;
            reject(e);
          } else {
            console.error(e);
            reject(e);
          }
        });
    } catch (error) {
      reject(error);
    }
  });
};

const consultaPix = async (dadosBanco, idPix) => {
  const token = await getTokenPix(
    dadosBanco.api_url,
    dadosBanco.client_id,
    dadosBanco.client_secret
  );

  var config = {
    url: `https://api.${dadosBanco.api_url}/pix/v1/cob/${idPix}`,
    method: "GET",
    headers: {
      Authorization: `Bearer ${token}`,
    },
    params: {
      "gw-dev-app-key": dadosBanco.developer_key,
    },
  };

  return await new Promise((resolve, reject) => {
    axios(config)
      .then((data) => {
        resolve(data.data);
      })
      .catch((e) => {
        console.error(e.response ? e.response.data : e);
        reject(e);
      });
  });
};

module.exports = {
  criaPix,
  consultaPix,
};
