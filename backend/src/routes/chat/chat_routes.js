"use strict"

require('dotenv').config()
const connection = require('../../config/database')
const express = require('express')

module.exports = (server) => {
    const router = express.Router()

    //rota para alterar se mensagem foi vista por usuario
    router.post('/messages/changeView', (req,res)=>{
      const {id_cliente, id_usuario} = req.body;

      console.log(req.query);
      const query = `UPDATE l_chat SET visto = 1 WHERE id_cliente = ? AND id_usuario = ? AND remetente = ? AND visto = 0`;
      connection.query(query, [id_cliente, id_usuario, 'cliente'], (queryError, queryResult)=>{
          if(queryError){
              console.log("Error on change view")
              console.error(queryError)
              res.json(queryError).status(500)
          }else{
              console.log(queryResult);
              res.json(queryResult).status(200)
          }
      })

    })

    router.get('/messages/isViewed/:id_user', (req,res)=>{
        const id_user = req.params.id_user;
        const query = `SELECT id_cliente, COUNT(*) as total
        FROM l_chat
        WHERE id_usuario = ? AND visto = 0 AND remetente = ?
        GROUP BY id_cliente;`;
        connection.query(query, [id_user, 'cliente'], (queryError, queryResult)=>{
            if(queryError){
                console.log("Error on get isViewd")
                console.error(queryError)
                res.json(queryError).status(500)
            }else{
                console.log('contagem de mensagens não vistas')
                console.log(queryResult);
                res.json(queryResult).status(200)
            }
        })
    })



    //busca mensagens de certo cliente com certo usuário
    router.post('/messages', (req, res)=>{
        const {id_client, id_user} = req.body;
        console.log(req.body);
        const query = `SELECT * FROM l_chat WHERE id_cliente = ${id_client} AND id_usuario = ${id_user}`;

        connection.query(query, (queryError, queryResult)=>{
            if(queryError){
                console.log("Error on get messages")
                console.error(queryError)
                res.json(queryError).status(500)
            }else{
                console.log(queryResult);
                res.json(queryResult).status(200)
            }
        })

    });

    router.post('/messages/send', (req, res)=>{
        const { id_cliente, id_usuario, mensagem, remetente, data_envio } = req.body;
        const query = `INSERT INTO l_chat (id_cliente, id_usuario, mensagem, remetente, data_envio) VALUES (?, ?, ?, ?, ?)`;

        connection.query(
            query,
            [id_cliente, id_usuario, mensagem, remetente, data_envio],
            (err, result) => {
              if (err) {
                console.error('Erro ao salvar mensagem:', err).status(500);
                return;
              }else{
                console.log(' Mensagem salva:', result);
                res.json(result).status(200);
              }
              
            }
          );
    });

    server.use('/', router)
}