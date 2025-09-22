const axios = require("axios");
const qs = require("qs");
const fs = require("fs");
const https = require("https");
var path = require("path");
const conection = require("../../../../config/database"); // ATENCÃO A ESTE PATH!!!
const { banks, certificatesPath } = require("../../../../config/globals");

const certificateFolder = "inter/";

//Obtém o agente de requisição HTTPS
const getHttpsAgent = async (api_url) => {
  const certificatePath = path.normalize(
    `${__dirname}/../../../../../${certificatesPath}${certificateFolder}certificado.crt`
  );
  const keyPath = path.normalize(
    `${__dirname}/../../../../../${certificatesPath}${certificateFolder}chave.key`
  );

  console.log('getHttpsAgent');
  console.log(certificatePath);

  //Checa se tem arquivos de certificado e chave
  if (!fs.existsSync(certificatePath)) {
    throw {
      msg: "Inclua um arquivo de certificado do banco!",
    };
  }
  if (!fs.existsSync(keyPath)) {
    throw {
      msg: "Inclua um arquivo de chave do banco!",
    };
  }

  //Configura host do Certificado (site da API)
  httpsAgent = new https.Agent({
    cert: fs.readFileSync(certificatePath),
    key: fs.readFileSync(keyPath),
    host: api_url.replace("https://", "").replace("/", ""),
    rejectUnauthorized: false,
    passphrase: "",
  });
  return httpsAgent;
};

//Trata erro de requisição
const handleError = (error) => {
  console.error(error);
  if (error.response) {
    if (error.response.data) {
      console.error(error.response.data);
      if (error.response.data.detail)
        return { msg: `Erro Inter: ${error.response.data.detail}` };
      return { msg: `Erro Inter: ${error.response.status}` };
    }
    return { msg: `Erro Inter: ${error.response.status}` };
  }
  return error;
};

//Manda request para a API do Inter
const sendRequest = async (
  api_url,
  route,
  method,
  headers,
  data,
  httpsAgent
) => {
  return await new Promise((resolve, reject) => {
    var config = {
      url: `${api_url}${route}`,
      method,
      headers,
      data,
      httpsAgent,
    };
    axios(config)
      .then(async (results) => {
        resolve(results.data);
      })
      .catch((error) => {
        error = handleError(error);
        console.error(error);
        reject(error);
      });
  });
};

//Obtém o token de acesso
const getToken = async (api_url, client_id, client_secret) => {
  const httpsAgent = await getHttpsAgent(api_url);
  const headers = {
    "Content-Type": "application/x-www-form-urlencoded",
    Accept: "application/json",
  };
  const data = qs.stringify({
    grant_type: "client_credentials",
    scope: `boleto-cobranca.read boleto-cobranca.write cob.read cob.write webhook.write webhook.read pix.write pix.read`,
    client_id,
    client_secret,
  });
  const results = await sendRequest(
    api_url,
    "oauth/v2/token",
    "POST",
    headers,
    data,
    httpsAgent
  );
  return results.access_token;
};

//Obtém dados do banco Inter
const getDadosBancoInter = async () => {


  return await new Promise((resolve, reject) => {
    conection.query(
      "SELECT * FROM dados_banco WHERE num_banco = ?",
      [banks["inter"]],
      (error, results) => {
        if (error) reject(error);
        else resolve(results[0]);
      }
    );
  });
};

//Prepara uma requisição à API do Inter, fornecendo tudo que for necessário
const fetch = async (route, method, data) => {
  const dadosBanco = await getDadosBancoInter();
  const token = await getToken(
    dadosBanco.api_url,
    dadosBanco.client_id,
    dadosBanco.client_secret
  );
  const headers = {
    Authorization: `Bearer ${token}`,
    Accept: "application/json",
  };
  const httpsAgent = await getHttpsAgent(dadosBanco.api_url);
  return await sendRequest(
    dadosBanco.api_url,
    route,
    method,
    headers,
    data,
    httpsAgent
  );
};

module.exports = {
  getHttpsAgent,
  getToken,
  fetch,
  getDadosBancoInter,
};
