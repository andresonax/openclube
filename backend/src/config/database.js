"use strict"

const mysql = require('mysql2');

const { dbConfig } = require('./globals');

const conection = mysql.createConnection(dbConfig);

module.exports = conection;

