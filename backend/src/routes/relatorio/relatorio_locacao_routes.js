const express = require("express");
const moment = require("moment");
const utils = require("../../utils/utils");
const methods = require("./relatorio_locacao_methods");

module.exports = (server) => {
  const router = express.Router();

  //RELATORIO AGENDA
  router.get("/locacao/relatorio/agenda", async (req, res) => {

    console.log("Relatório de agenda solicitado");
    try {
      const data = moment(req.body.data);
      const response = await methods.relatorioAgenda(data);
      res.json(response);
    } catch (error) {
      error = utils.err(error, "ERROR ON RELATORIO AGENDA relatorio_locacao");
      res.json(error);
    }
  });

  server.use("/", router);
};
