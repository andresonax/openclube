"use strict"
require('dotenv').config()
const connection = require('../../config/database'); 

// Função que configura o Socket.IO caso o chat precise mais tarde
// Não usado atualmente
function setupSocket(io) {
  io.on('connection', (socket) => {
    console.log('Novo socket conectado');

    socket.on('sendMessage', (data) => {
      const { id_cliente, id_usuario, mensagem, remetente, data_envio } = data;

      if (!id_cliente || !id_usuario || !mensagem || !remetente) {
        console.error('Dados incompletos para salvar mensagem.');
        return;
      }


      connection.query(
        'INSERT INTO l_chat (id_cliente, id_usuario, mensagem, remetente, data_envio) VALUES (?, ?, ?, ?, ?)',
        [id_cliente, id_usuario, mensagem, remetente, data_envio],
        (err, result) => {
          if (err) {
            console.error('Erro ao salvar mensagem:', err);
            return;
          }

          const novaMensagem = {
            id: result.insertId,
            id_cliente,
            id_usuario,
            mensagem,
            remetente,
            data_envio,
          };

          console.log(' Mensagem salva:', novaMensagem);

          io.emit('receiveMessage', novaMensagem);
        }
      );
    });

    socket.on('disconnect', () => {
      console.log('Socket desconectado');
    });
  });
}

module.exports = setupSocket;
