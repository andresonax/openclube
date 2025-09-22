"use strict";

const {sharedResourcesUrl} = require('../config/globals');
const express = require("express");
const proxy = require('express-http-proxy');

module.exports = (server) => {
    const router = express.Router();

    router.get('/uploads/shared/', proxy(sharedResourcesUrl));

    router.get('/uploads/shared/object/*', proxy(sharedResourcesUrl));

    server.use("/", router);
};
