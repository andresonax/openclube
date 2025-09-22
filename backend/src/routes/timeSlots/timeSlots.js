"use strict";
require('dotenv').config()
const connection = require('../../config/database')
const express = require('express')


module.exports = (server) => {
  const router = express.Router();


    //busca timeslots cadastrados por cliente
    router.get('/booking/timeslots/booked/perClient/:id_client', (req,res)=>{
        const id_client = req.params.id_client
        const query = `
            SELECT a.*,
            fp.descricao as descricao_forma_pagamento,
            cp.descricao as descricao_condicao_pagamento
            FROM l_agenda as a
            INNER JOIN l_espaco as e
            INNER JOIN l_forma_pagamento as fp ON a.id_forma_pagamento = fp.id_forma_pagamento
            INNER JOIN l_condicao_pagamento as cp ON a.id_condicao_pagamento = cp.id_condicao_pagamento
            WHERE e.id_espaco = a.id_espaco AND e.id_cliente = ?
        `
        connection.query(query, [id_client],(queryError, queryResult)=>{
            if(queryError){     
                console.error(queryError)
                res.json(queryError).status(500)
            }else{
                res.json(queryResult).status(200)
            }
        })
    })

    router.get('/booking/timeslots/perClient/:id_client', (req,res)=>{
        const id_client = req.params.id_client
        const query = `SELECT * FROM l_grade_agenda WHERE id_espaco IN (SELECT id_espaco FROM l_espaco WHERE id_cliente = ?)`
        connection.query(query, [id_client],(queryError, queryResult)=>{
            if(queryError){     
                console.error(queryError)
                res.json(queryError).status(500)
            }else{
                res.json(queryResult).status(200)
            }
        })
    })


    router.get('/booking/timeslots/:id_espaco', (req,res)=>{
        const id_espaco = req.params.id_espaco

        const query = `SELECT * FROM l_grade_agenda WHERE id_espaco = ?`
        connection.query(query, [id_espaco],(queryError, queryResult)=>{
            if(queryError){     
                console.error(queryError)
                res.json(queryError).status(500)
            }else{
                res.json(queryResult).status(200)
            }
        })
    })

    router.get('/booking/timeslots/booked/:id_espaco', (req,res) =>{
        const id_espaco = req.params.id_espaco

        const query = `SELECT data_agenda, horario, horario_final, data_fim, repeticao FROM l_agenda WHERE id_espaco = ?`
        connection.query(query, [id_espaco],(queryError, queryResult)=>{
            if(queryError){     
                console.error(queryError)
                res.json(queryError).status(500)
            }else{
                res.json(queryResult).status(200)
            }
        })
    })

    router.get('/booking/material/:id_modalidade', (req,res)=>{
        const id_modalidade = req.params.id_modalidade

        const query = `SELECT * FROM l_material WHERE id_modalidade_espaco = ?`
        connection.query(query, [id_modalidade], (queryError, queryResult)=>{
            if(queryError){     
                console.error(queryError)
                res.json(queryError).status(500)
            }else{
                res.json(queryResult).status(200)
            }
        })
    })

    router.get('/booking/paymentMethods', (req,res)=>{
        const id_modalidade = req.params.id_modalidade

        const query = `SELECT * FROM l_forma_pagamento`
        connection.query(query, [id_modalidade], (queryError, queryResult)=>{
            if(queryError){     
                console.error(queryError)
                res.json(queryError).status(500)
            }else{
                res.json(queryResult).status(200)
            }
        })
    })

    router.get('/booking/userCpf/:idUser', (req,res)=>{
        const idUser = req.params.idUser
        console.log(idUser);

        const query = `SELECT cpf FROM usuario WHERE usuario.id_usuario = ?`;
        connection.query(query, [idUser], (queryError, queryResult)=>{
            if(queryError){     
                console.error(queryError)
                res.json(queryError).status(500)
            }else{
                res.json(queryResult).status(200)
            }
        })
    })


    server.use("/", router);


}