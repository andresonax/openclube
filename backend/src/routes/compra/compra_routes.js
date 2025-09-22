const express = require("express");
const methods = require("./compra_methods.js");
const { geraComprovante } = require("./compra_comprovante.js");
const utils = require("../../utils/utils");
const path = require('path');
const fs = require('fs');
const CronJob = require("cron").CronJob;

new CronJob(
  //"0 9,18 * * *", //antes rodava duas vezes ao dia, às 9h e às 18h
  //"0 * * * * *",    //alterado pra verificar de minuto em minuto
  "*/30 * * * * *",
  methods.deleteAllPixExpirados,
  null,
  true,
  "America/Sao_Paulo"
);

const createCompra = async (req, res) => {

  try {
    const id_usuario = parseInt(req.body.id_usuario);
    const tipo_usuario = req.body.tipo_usuario;
    //tipo_pagamento: 1 = Total, 2 = Parcial
    const tipo_pagamento = parseInt(req.body.tipo_pagamento);
    const valor_total = parseFloat(req.body.valor_total);
    const horarioList = req.body.horarioList;
    const id_cliente = parseInt(req.body.id_cliente);

    const results = await methods.createCompra(
      id_usuario,
      tipo_usuario,
      tipo_pagamento,
      valor_total,
      horarioList,
      id_cliente
    );

    res.json(results);
  } catch (error) {
    error = utils.err(error, "ERROR ON CRIAR COMPRA compra");
    res.json(error);
  }
};

const readComprasInPeriod = async (req, res) => {
  try {
    const dataInicial = req.body.data_inicial;
    const dataFinal = req.body.data_final;
    const response = await methods.readComprasInPeriod(dataInicial, dataFinal);
    res.json(response);
  } catch (error) {
    error = utils.err(error, "ERROR ON LER COMPRAS EM PERÍODO compra");
    res.json(error);
  }
};

//Gera o Pix manualmente
const geraPix = async (req, res) => {
  try {
    const id_compra = parseInt(req.body.id_compra);
    const response = await methods.gerarPixManual(id_compra);
    res.json(response);
  } catch (error) {
    error = utils.err(error, "ERROR ON GERA PIX compra");
    res.json(error);
  }
};

const visualizaPix = async (req, res) => {
  try {
    const id_compra = parseInt(req.params.id_compra);
    const response = await methods.visualizarPix(id_compra);
    res.json(response);
  } catch (error) {
    error = utils.err(error, "ERROR ON VISUALIZA PIX compra");
    res.json(error);
  }
};

const baixaManual = async (req, res) => {
  try {
    const dadosBaixa = {
      id_compra: parseInt(req.body.id_compra),
      valor_pago: parseFloat(req.body.valor_pago),
      descontos: parseFloat(req.body.descontos),
      acrescimos: parseFloat(req.body.acrescimos),
      id_usuario_baixa: parseInt(req.body.id_usuario_baixa),
    };
    const response = await methods.baixaCompra(dadosBaixa);
    res.json(response);
  } catch (error) {
    error = utils.err(error, "ERROR ON BAIXA MANUAL compra");
    res.json(error);
  }
};

const deleteCompra = async (req, res) => {
  try {
    const id_compra = parseInt(req.params.id_compra);
    const response = await methods.excludeCompra(id_compra);
    res.json(response);
  } catch (error) {
    error = utils.err(error, "ERROR ON EXCLUIR COMPRA compra");
    res.json(error);
  }
};

const readComprasByUsuario = async (req, res) => {
  try {
    const id_usuario = parseInt(req.body.id_usuario);
    const tipo_usuario = req.body.tipo_usuario;
    const response = await methods.readComprasByUsuario(
      id_usuario,
      tipo_usuario
    );
    res.json(response);
  } catch (error) {
    error = utils.err(error, "ERROR ON LER COMPRAS POR USUÁRIO compra");
    res.json(error);
  }
};

//Lê uma compra por meio de uma agenda vinculada a ela em certa data
const readComprasByAgendaAndData = async (req, res) => {
  try {
    const id_agenda = parseInt(req.body.id_agenda);
    const data = req.body.data;
    const response = await methods.readComprasByAgendaAndData(id_agenda, data);
    res.json(response);
  } catch (error) {
    error = utils.err(error, "ERROR ON LER COMPRAS POR AGENDA compra");
    res.json(error);
  }
};

//Checa se compra é múltipla
const isCompraMultipla = async (req, res) => {
  try {
    const id_compra = parseInt(req.params.id_compra);
    const response = await methods.isCompraMultipla(id_compra);
    res.json(response);
  } catch (error) {
    error = utils.err(error, "ERROR ON CHECA SE COMPRA É MÚLTIPLA compra");
    res.json(error);
  }
};

//Gera comprovante da compra
const comprovanteCompra = async (req, res) => {

  try {
    const id_compra = parseInt(req.params.id_compra);
    const id_cliente = parseInt(req.params.id_cliente);
    const response = await geraComprovante(id_compra, id_cliente);
    res.json(response);
  } catch (error) {
    error = utils.err(error, "ERROR ON GERA COMPROVANTE COMPRA compra");
    res.json(error);
  }
};

const openComprovanteCompra = async (req,res) => {
  const id = req.params.id_compra;
    try {
        const imagePath = await findPdfComprovante(id);
        if (!imagePath) {
            return res.status(404).send('pdf não encontrado');
        }
        res.sendFile(imagePath);
    } catch (error) {
        console.error('Erro ao buscar pdf:', error);
        res.status(500).send('Erro ao buscar pdf');
    }
}

// Função para encontrar pdf de comprovante
function findPdfComprovante(idCompra) {
    return new Promise((resolve, reject) => {
        const uploadsDir = path.join(__dirname, '../../../files/uploads');
        
        fs.readdir(uploadsDir, (err, files) => {
            if (err) {
                reject(err);
                return;
            }

            // Filtra arquivos que terminam com `_idCompra.pdf`
            const pdfComprovante = files.find(file => file.endsWith(`_${idCompra}.pdf`));
            resolve(pdfComprovante ? path.join(uploadsDir, pdfComprovante) : null);
        });
    });
}

const idCompraPorIdAgenda = async (req, res) => {
  try {
    const id_agenda = parseInt(req.params.id_agenda);
    const response = await methods.idCompraPorIdAgenda(id_agenda);
    
    res.json(response);
  } catch (error) {
    error = utils.err(error, "ERROR ON RETORNA ID COMPRA PELO ID DE AGENDA compra");
    res.json(error);
  }
}

const comprasData = async (req, res) => {
  try {
    const id_compra = parseInt(req.params.id_compra);
    const response = await methods.comprasData(id_compra);
    res.json(response);
  } catch (error) {
    error = utils.err(error, "ERROR ON LER DADOS DA COMPRA");
    res.json(error);
  }
};

module.exports = (server) => {
  const router = express.Router();

  //CRIAR COMPRA
  router.post("/locacao/compra", createCompra);

  //LER COMPRAS EM PERÍODO
  router.post("/locacao/compra/period", readComprasInPeriod);

  //LER COMPRAS POR USUÁRIO
  router.post("/locacao/compra/user", readComprasByUsuario);

  //GERA PIX
  router.post("/locacao/compra/pix", geraPix);

  //VISUALIZA PIX
  router.get("/locacao/compra/pix/:id_compra", visualizaPix);

  //BAIXA MANUAL
  router.post("/locacao/compra/baixa", baixaManual);

  //EXCLUIR COMPRA
  router.delete("/locacao/compra/:id_compra", deleteCompra);

  //LER COMPRAS POR AGENDA
  router.post("/locacao/compra/agenda", readComprasByAgendaAndData);

  //CHECA SE COMPRA É MÚLTIPLA
  router.get("/locacao/compra/isMultipla/:id_compra", isCompraMultipla);

  //PERMITE ACESSAR O COMPROVANTE DE COMPRA GERADO POR ID
  router.get('/locacao/compra/comprovante/open/:id_compra', openComprovanteCompra);
  
  //GERA COMPROVANTE DE COMPRA
  router.get("/locacao/compra/comprovante/:id_compra/:id_cliente", comprovanteCompra);

  //RETORNA ID COMPRA PELO ID DE AGENDA
  router.get("/locacao/compra/agenda/:id_agenda", idCompraPorIdAgenda);

  router.get('/locacao/compra/:id_compra', comprasData);

  server.use(router);
};
