const express = require("express");
const {
  readConfigs,
  updateConfigsPagamento,
  updateConfigsAgenda,
  updateAlertaCompra,
} = require("./configs_methods");

module.exports = (server) => {
  const router = express.Router();
  //CRUD cliente

  //READ CONFIGS
  router.get("/locacao/configs", async (req, res) => {
    try {
      res.json(await readConfigs());
    } catch (error) {
      console.error(error);
      console.error("Error on READ CONFIGS configs");
      error.err = true;
      res.json(error);
    }
  });

  //UPDATE CONFIGS PAGAMENTO
  router.post("/locacao/configs/pagamento", async (req, res) => {
    try {
      const id_banco_pix = req.body.id_banco_pix
        ? parseInt(req.body.id_banco_pix)
        : null;
      const valor_obrigatorio_reserva = req.body.valor_obrigatorio_reserva
        ? parseInt(req.body.valor_obrigatorio_reserva)
        : null;
      const expiracao_minutos_pix = req.body.expiracao_minutos_pix
        ? parseInt(req.body.expiracao_minutos_pix)
        : null;
      const usa_pix = parseInt(req.body.usa_pix);
      const usa_boleto = parseInt(req.body.usa_boleto);
      const data = [
        id_banco_pix,
        valor_obrigatorio_reserva,
        expiracao_minutos_pix,
        usa_pix,
        usa_boleto,
      ];
      res.json(await updateConfigsPagamento(data));
    } catch (error) {
      console.error(error);
      console.error("Error on UPDATE CONFIGS PAGAMENTO configs");
      error.err = true;
      res.json(error);
    }
  });

  //UPDATE CONFIGS AGENDA
  router.post("/locacao/configs/agenda", async (req, res) => {
    try {
      const periodo_antecedencia_reserva = parseInt(
        req.body.periodo_antecedencia_reserva
      );
      const data = {
        periodo_antecedencia_reserva,
      };
      res.json(await updateConfigsAgenda(data));
    } catch (error) {
      console.error(error);
      console.error("Error on UPDATE CONFIGS AGENDA configs");
      error.err = true;
      res.json(error);
    }
  });

  //UPDATE CONFIGS ALERTA COMPRA
  router.post("/locacao/configs/alerta_compra", async (req, res) => {
    try {
      const id_perfil_alerta_compra = parseInt(
        req.body.id_perfil_alerta_compra
      );
      let msg_geral_alerta_compra = req.body.msg_geral;
      if (msg_geral_alerta_compra)
        msg_geral_alerta_compra = msg_geral_alerta_compra.substr(0, 500);
      let msg_agendamentos_alerta_compra = req.body.msg_agendamentos;
      if (msg_agendamentos_alerta_compra)
        msg_agendamentos_alerta_compra = msg_agendamentos_alerta_compra.substr(
          0,
          500
        );
      let assunto_alerta_compra = req.body.assunto_alerta_compra;
      if (assunto_alerta_compra)
        assunto_alerta_compra = assunto_alerta_compra.substr(0, 150);
      const data = {
        id_perfil_alerta_compra,
        msg_geral_alerta_compra,
        msg_agendamentos_alerta_compra,
        assunto_alerta_compra,
      };
      const response = await updateAlertaCompra(data);
      res.json(response);
    } catch (error) {
      console.error(error);
      console.error("Error on UPDATE CONFIGS ALERTA COMPRA configs");
      error.err = true;
      res.json(error);
    }
  });

  server.use("/", router);
};
