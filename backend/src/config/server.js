"use strict"

const { corsAllow, port } = require('./globals')
const cookieParser = require('cookie-parser')
const express = require('express')
const server = express()
const cors = require('cors')

const setupSocket = require('../routes/chat/chat'); //arquivo que usa socket.io

const corsOptions = {
    credentials: true,
    origin: corsAllow,
    optionSuccessStatus: 200
}

server.use(cookieParser("cookieSecretDev"))
server.use(cors(corsOptions))
server.use(express.json({ limit: "50mb" }))
server.use(express.urlencoded({ extended: true, limit: "50mb" }))

const serverInstance = server.listen(port, ()=>{})

/*
// Inicializa o Socket.IO com esse servidor
const { Server } = require('socket.io');
const io = new Server(serverInstance, {
  cors: {
    origin: corsAllow,
    credentials: true,
  },
});

// Configura o Socket.IO (chat.js)
setupSocket(io);

const middleware = require('socketio-wildcard')()
io.use(middleware)
*/
module.exports = {server,serverInstance}
