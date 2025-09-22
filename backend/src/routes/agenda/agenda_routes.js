"use strict";
const express = require("express");
const methods = require("./agenda_methods");
const utils = require("../../utils/utils");
const usuarioMethods = require("../usuario_app/usuario_app_methods");


module.exports = (server) => {
  const router = express.Router();

  const {

  readForTable,
} = require("../agenda/agenda_resources.js");

const {
  isHorarioPassado,
  isHorarioReservado,
} = require("../horario/horario_resources.js");

  //Checa se horário está no passado/indisponível devido ao período de antecedência requerido para reserva
  const checkIsHorarioPassado = async (horario) => {
    //Lê as configurações de locação
    const configs = await configsMethods.readConfigs();
    return isHorarioPassado(horario, configs);
  };

  //Checa se horário está reservado
  const checkIsHorarioReservado = async (horario) => {

    const agendaList = await readForTable(horario.id_espaco, horario.data);
    //Se horário estiver comprado, deleta do carrinho
    return isHorarioReservado(horario, agendaList);
  };


  //Valida os horários do antes de realizar a compra
  const validaHorarios = async (horarioList) => {

    console.log("Validando horários da agenda...");
    console.log(horarioList);
  
    var invalidos = false;
    for (var i = 0; i < horarioList.length; i++) {
      const horario = horarioList[i];
      horario.data = new Date(horario.data.substring(0, 10));
      if (await checkIsHorarioPassado(horario)) {
        invalidos = true;
        //await carrinhoMethods.removeHorario(horario.id_horario_carrinho);
      } else if (await checkIsHorarioReservado(horario)) {
        invalidos = true;
        //await carrinhoMethods.removeHorario(horario.id_horario_carrinho);
      }
    }
    if (invalidos)
      throw {
        msg: "Um ou mais horários inválidos. Tente novamente!",
      };
  };

  
  //READ ALL
  router.get("/locacao/agenda", async (req, res) => {
    try {
      res.json(await methods.read());
    } catch (error) {
      console.error("Error on READ ALL agenda:");
      console.error(error);
      error.err = true;
      res.json(error);
    }
  });

  //READ FOR TABLE
  router.post("/locacao/agenda/table", async (req, res) => {
    try {
      const id_espaco = parseInt(req.body.id_espaco);
      const day = req.body.day;
      const results = await methods.readForTable(id_espaco, day);
      res.json(results);
    } catch (error) {
      console.error("Error on READ FOR TABLE agenda:");
      console.error(error);
      error.err = true;
      res.json(error);
    }
  });

  //READ BY COMPRA
  router.get("/locacao/agenda/compra/:id_compra", async (req, res) => {
    try {
      const id_compra = parseInt(req.params.id_compra);
      res.json(await methods.readByCompraMethod(id_compra));
    } catch (error) {
      error = utils.err(error, "Error on READ BY COMPRA agenda:");
      res.json(error);
    }
  });

  //READ BY USUARIO
  router.post("/locacao/agenda/usuario", async (req, res) => {
    console.log(req.body);
    try {
      const id_usuario = parseInt(req.body.id_usuario);
      const tipo_usuario = req.body.tipo_usuario;

      res.json(await methods.readByUsuario(id_usuario, tipo_usuario));
    } catch (error) {
      console.error("Error on READ BY USUARIO agenda:");
      console.error(error);
      error.err = true;
      res.json(error);
    }
  });

  //READ BY ID AGENDA
  router.get("/locacao/agenda/:id_agenda", async (req, res) => {
    try {
      const id_agenda = parseInt(req.params.id_agenda);

      res.json(await methods.readAgendaById(id_agenda));
    } catch (error) {
      console.error(error);
      console.error("Error on READ BY ID AGENDA agenda");
      error.err = true;
      res.json(error);
    }
  });

  //CREATE AGENDAMENTO
  router.post("/locacao/agenda", async (req, res) => {
    try {
      const id_usuario = parseInt(req.body.id_usuario);
      const tipo_usuario = req.body.tipo_usuario;
      const agenda = {
        id_espaco: parseInt(req.body.id_espaco),
        data: req.body.data_agenda,
        inicio: req.body.horario,
        final: req.body.horario_final,
        valor: parseFloat(req.body.valor),
        observacao: req.body.observacao,
        id_modalidade_espaco: parseInt(req.body.id_modalidade_espaco),
        repeticao: req.body.repeticao ? parseInt(req.body.repeticao) : null,
        data_fim: req.body.data_fim ? req.body.data_fim : null,
        nome_responsavel: '',
        id_forma_pagamento: req.body.id_forma_pagamento ? parseInt(req.body.id_forma_pagamento) : null,
        id_condicao_pagamento: req.body.id_condicao_pagamento ? parseInt(req.body.id_condicao_pagamento) : null,
      };
      if (!req.body.materiais) agenda.material_list = [];
      else agenda.material_list = req.body.materiais;


      //Valida se não há nenhum horário inválido na agenda
      await validaHorarios(agenda);
      //busca dados do usuario
      const usuario = await usuarioMethods.getDadosUsuario(
        id_usuario,
        tipo_usuario
      );
      agenda.nome_responsavel = usuario.nome


      const results = await methods.createAgendaInterna(
        id_usuario,
        tipo_usuario,
        agenda
      );
      res.json(results).status(200);
    } catch (error) {
      console.error(error);
      console.error("Error on CREATE AGENDAMENTO agenda:");
      res.json({
        err: true,
        data: error,
      }).status(500);
    }
  });

  //DELETE
  router.delete("/locacao/agenda/:id_agenda", async (req, res) => {
    try {
      const id_agenda = parseInt(req.params.id_agenda);

      res.json(await methods.removeAgenda(id_agenda));
    } catch (error) {
      console.error("Error on DELETE agenda:");
      console.error(error);
      error.err = true;
      res.json(error);
    }
  });

  //DELETE ALL REPETICAO
  router.delete("/locacao/agenda/all/:id_agenda", async (req, res) => {
    try {
      const id_agenda = parseInt(req.params.id_agenda);
      res.json(await methods.deleteRepeticaoAll(id_agenda));
    } catch (error) {
      console.error("Error on DELETE ALL REPETICAO agenda:");
      console.error(error);
      error.err = true;
      res.json(error);
    }
  });

  //DELETE ONE REPETICAO
  router.post("/locacao/agenda/one", async (req, res) => {
    try {
      const id_agenda = parseInt(req.body.id_agenda);
      const dia = req.body.dia;
      res.json(await methods.deleteRepeticaoOne(id_agenda, dia));
    } catch (error) {
      console.error("Error on DELETE ONE REPETICAO agenda:");
      console.error(error);
      error.err = true;
      res.json(error);
    }
  });

  //BAIXA DE AGENDAMENTO COM REPETIÇÃO
  router.post("/locacao/agenda/baixa/repeticao", async (req, res) => {
    try {
      const dadosBaixa = {
        id_agenda: parseInt(req.body.id_agenda),
        dia: req.body.dia,
        valor_pago: parseFloat(req.body.valor_pago),
        descontos: parseFloat(req.body.descontos),
        acrescimos: parseFloat(req.body.acrescimos),
        id_usuario_baixa: parseInt(req.body.id_usuario_baixa),
      };
      const response = await methods.baixaRepeticao(dadosBaixa);
      res.json(response);
    } catch (error) {
      console.error("Error on BAIXA DE AGENDAMENTO COM REPETIÇÃO agenda:");
      console.error(error);
      error.err = true;
      res.json(error);
    }
  });

  //EDIÇÃO DE AGENDAMENTO
  router.put("/locacao/agenda/:id_agenda", async (req, res) => {
    try {
      const id_agenda = parseInt(req.params.id_agenda);
      const { nome_responsavel, observacao } = req.body;
      const response = await methods.editAgenda(
        id_agenda,
        nome_responsavel,
        observacao
      );
      res.json(response);
    } catch (error) {
      console.error("Error on EDIÇÃO DE AGENDAMENTO agenda:");
      console.error(error);
      error.err = true;
      res.json(error);
    }
  });

  server.use("/", router);
};
