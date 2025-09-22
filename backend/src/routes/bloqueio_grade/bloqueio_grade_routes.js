"use strict";
const express = require("express");
const methods = require("./bloqueio_grade_methods");
const moment = require("moment");
moment.locale("pt-br");

module.exports = (server) => {
  const router = express.Router();
  //CRUD bloqueio_grade

  //READ ALL
  router.get("/locacao/bloqueio_grade", async (req, res) => {
    try {
      res.json(await methods.read());
    } catch (error) {
      console.error("Error on READ bloqueio_grade:");
      console.error(error);
      error.err = true;
      res.json(error);
    }
  });

  //READ BY PLACE ID
  router.get("/locacao/bloqueio_grade/:id", async (req, res) => {
    try {
      const id_espaco = parseInt(req.params.id);
      res.json(await methods.readByPlaceId(id_espaco));
    } catch (error) {
      console.error("Error on READ bloqueio_grade by place ID:");
      console.error(error);
      error.err = true;
      res.json(error);
    }
  });

    //READ BY PLACE ID CLIENT
    router.get("/locacao/bloqueio_grade/perClient/:id_client", async (req, res) => {
      try {
        const id_client = parseInt(req.params.id_client);
        res.json(await methods.readByClientId(id_client));
      } catch (error) {
        console.error("Error on READ bloqueio_grade by client ID:");
        console.error(error);
        error.err = true;
        res.json(error);
      }
    });

  //CREATE
  router.post("/locacao/bloqueio_grade", async (req, res) => {
    try {
      const data = [
        req.body.inicio,
        req.body.final,
        moment(req.body.data_inicio).format("YYYY-MM-DD"),
        moment(req.body.data_fim).format("YYYY-MM-DD"),
        req.body.descricao,
        parseInt(req.body.dia_semana),
        parseInt(req.body.id_espaco),
      ];

      res.json(await methods.create(data)).status(200);
    } catch (error) {
      console.error("Error on CREATE bloqueio_grade:");
      console.error(error);
      error.err = true;
      res.json(error).status(500);
    }
  });

  //UPDATE
  router.put("/locacao/bloqueio_grade/:id", async (req, res) => {
    console.log(req.body)

    try {
      const id_bloqueio_grade = parseInt(req.params.id);
      const data = [
        req.body.inicio,
        req.body.final,
        moment(req.body.data_inicio).format("YYYY-MM-DD"),
        moment(req.body.data_fim).format("YYYY-MM-DD"),
        req.body.descricao,
        parseInt(req.body.dia_semana),
        parseInt(req.body.id_espaco),
      ];

      res.json(await methods.update(id_bloqueio_grade, data)).status(200);
    } catch (error) {
      console.error("Error on UPDATE bloqueio_grade:");
      console.error(error);
      error.err = true;
      res.json(error).status(500);
    }
  });

  //DELETE
  router.delete("/locacao/bloqueio_grade/:id", async (req, res) => {
    try {
      const id_bloqueio_grade = parseInt(req.params.id);

      res.json(await methods.deleteBloqueio(id_bloqueio_grade)).status(200);
    } catch (error) {
      console.error("Error on DELETE bloqueio_grade:");
      console.error(error);
      error.err = true;
      res.json(error).status(500);
    }
  });

  server.use("/", router);
};
