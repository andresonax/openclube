"use strict";
const express = require("express");
const methods = require("./material_agenda_methods");

module.exports = (server) => {
  const router = express.Router();

  //READ ALL
  router.get("/locacao/material_agenda/agenda/:id_agenda", async (req, res) => {
    try {
      const id_agenda = req.params.id_agenda;
      res.json(await methods.read(id_agenda));
    } catch (error) {
      console.error("Error on READ agenda:");
      console.error(error);
      error.err = true;
      res.json(error);
    }
  });

  server.use("/", router);
};
