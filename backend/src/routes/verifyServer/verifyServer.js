"use strict"

const express = require('express');
require('dotenv').config();

module.exports = (server) => {
    const router = express.Router();

    router.get('/verifyServer', (req, res) => {
        console.log("verificando servidor")
        res.status(200).send();
    })

    server.use('/', router)
}