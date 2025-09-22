const express = require("express");
const pixMethods = require("../../pix/pix");
const { err } = require("../../../../utils/utils");
const { registraCallback } = require("./inter_pix");

module.exports = (server) => {
  const router = express.Router();

  //rota para receber o webhook do inter de confirmação de pagamento pix
  router.post("/webhooks/inter/pix", async (req, res) => {
    try {
      const txid = req.body.pix[0].txid;
      const e2eid = req.body.pix[0].endToEndId;
      const valor_pago = req.body.pix[0].valor;
      const results = await pixMethods.processCallbackBaixaPix(
        txid,
        e2eid,
        valor_pago
      );
      res.json(results);
    } catch (error) {
      error = err(error, "Erro na baixa de Pix do Inter!");
      
      res.json(error);
    }
  });

  //rota para registrar o callback do webhook de pagamento
  router.get("/webhooks/inter/register", async (req, res) => {
    console.log("Registrando callback do Inter...");
    try {
      const dadosBanco = {
        chave_pix: "44185764000174"
      };

      const result = await registraCallback(dadosBanco);
      res.json({ success: true, result });
    } catch (error) {
      res.status(500).json({ error: "Erro ao registrar callback", detalhes: error });
    }
  });

  server.use("/", router);
};
