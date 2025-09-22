const express = require("express");
const methods = require("./carrinho_methods.js");

readCarrinho = async (req, res) => {
  try {
    const id_usuario = parseInt(req.body.id_usuario);
    const tipo_usuario = req.body.tipo_usuario;
    const response = await methods.readCarrinho(id_usuario, tipo_usuario);
    res.json(response);
  } catch (error) {
    error.err = true;
    console.error("ERROR ON READ CARRINHO carrinho");
    console.error(error);
    res.json(error);
  }
};

salvarCarrinho = async (req, res) => {
  try {
    const id_usuario = parseInt(req.body.id_usuario);
    const tipo_usuario = req.body.tipo_usuario;
    const horarioList = req.body.horarioList;
    const response = await methods.salvarCarrinho(
      id_usuario,
      tipo_usuario,
      horarioList
    );
    res.json(response);
  } catch (error) {
    error.err = true;
    console.error("ERROR ON SALVAR CARRINHO carrinho");
    console.error(error);
    res.json(error);
  }
};

checaTemCarrinho = async (req, res) => {
  try {
    const id_usuario = parseInt(req.body.id_usuario);
    const tipo_usuario = req.body.tipo_usuario;
    const response = await methods.checaTemCarrinho(id_usuario, tipo_usuario);
    res.json(response);
  } catch (error) {
    error.err = true;
    console.error("ERROR ON CHECA TEM CARRINHO carrinho");
    console.error(error);
    res.json(error);
  }
};

sobrescreveCarrinho = async (req, res) => {
  try {
    const id_usuario = parseInt(req.body.id_usuario);
    const tipo_usuario = req.body.tipo_usuario;
    const horarioList = req.body.horarioList;
    const response = await methods.sobrescreveCarrinho(
      id_usuario,
      tipo_usuario,
      horarioList
    );
    res.json(response);
  } catch (error) {
    error.err = true;
    console.error("ERROR ON SOBRESCREVE CARRINHO carrinho");
    console.error(error);
    res.json(error);
  }
};

addHorarioCarrinho = async (req, res) => {
  try {
    const id_usuario = parseInt(req.body.id_usuario);
    const tipo_usuario = req.body.tipo_usuario;
    const horario = req.body.horario;
    const response = await methods.salvaHorarioCarrinho(
      id_usuario,
      tipo_usuario,
      horario
    );
    res.json(response);
  } catch (error) {
    error.err = true;
    console.error("ERROR ON ADD HORÁRIO carrinho");
    console.error(error);
    res.json(error);
  }
};

clearCarrinho = async (req, res) => {
  try {
    const id_usuario = parseInt(req.body.id_usuario);
    const tipo_usuario = req.body.tipo_usuario;
    const response = await methods.limpaCarrinho(id_usuario, tipo_usuario);
    res.json(response);
  } catch (error) {
    error.err = true;
    console.error("ERROR ON CLEAR CARRINHO carrinho");
    console.error(error);
    res.json(error);
  }
};

editHorarioCarrinho = async (req, res) => {
  try {
    const horario = req.body.horario;
    const response = await methods.editHorarioCarrinho(horario);
    res.json(response);
  } catch (error) {
    error.err = true;
    console.error("ERROR ON EDITAR HORÁRIO carrinho");
    console.error(error);
    res.json(error);
  }
};

removeHorarioCarrinho = async (req, res) => {
  try {
    const id_horario_carrinho = req.params.id_horario_carrinho;
    const response = await methods.removeHorario(id_horario_carrinho);
    res.json(response);
  } catch (error) {
    error.err = true;
    console.error("ERROR ON REMOVER HORÁRIO carrinho");
    console.error(error);
    res.json(error);
  }
};

module.exports = (server) => {
  const router = express.Router();

  //READ CARRINHO
  router.post("/locacao/carrinho/read", readCarrinho);

  //SALVAR CARRINHO
  router.post("/locacao/carrinho/salvar", salvarCarrinho);

  //CHECA TEM CARRINHO
  router.post("/locacao/carrinho/checa", checaTemCarrinho);

  //SOBRESCREVE CARRINHO
  router.post("/locacao/carrinho/sobrescreve", sobrescreveCarrinho);

  //ADD HORÁRIO
  router.post("/locacao/carrinho/add", addHorarioCarrinho);

  //CLEAR CARRINHO
  router.post("/locacao/carrinho/clear", clearCarrinho);

  //EDITAR HORÁRIO
  router.post("/locacao/carrinho/edit", editHorarioCarrinho);

  //REMOVER HORÁRIO
  router.delete(
    "/locacao/carrinho/remove/:id_horario_carrinho",
    removeHorarioCarrinho
  );

  server.use(router);
};
