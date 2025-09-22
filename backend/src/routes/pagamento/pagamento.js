"use strict";
const express = require("express");
const connection = require('../../config/database')



module.exports = (server) => {
    const router = express.Router();


    //lê metodos de pagamento usados por determinado cliente
    router.get('/pagamento/metodos/usados/:id_client', (req,res)=>{
        const id_cliente = req.params.id_client
        console.log(req.params)
        console.log(id_cliente);
        const query = `SELECT * FROM l_cliente_forma_pagamento as cfp INNER JOIN l_forma_pagamento as fp WHERE cfp.id_cliente = ? AND fp.id_forma_pagamento = cfp.id_forma_pagamento`
        connection.query(query, [id_cliente], (error, queryResult)=>{
            if(error){
                console.error("Error on FETCH PAYMENT METHODS")
                console.error(error);
                error.err = true;
                res.status(500).json({ error: 'Não foi possível buscar métodos de pagamento' });
            }else{
                res.status(200).send(queryResult);
            }
        })
    })


    //lê condições de pagamento usados por determinado cliente
    router.get('/pagamento/condicoes/usados/:id_client', (req,res)=>{
        const id_cliente = req.params.id_client
        const query = `SELECT * FROM l_cliente_condicao_pagamento as ccp INNER JOIN l_condicao_pagamento as cp WHERE ccp.id_cliente = ? AND cp.id_condicao_pagamento = ccp.id_condicao_pagamento`
        connection.query(query, [id_cliente], (error, queryResult)=>{
            if(error){
                console.error("Error on FETCH PAYMENT CONDITIONS")
                console.error(error);
                error.err = true;
                res.status(500).json({ error: 'Não foi possível buscar condições de pagamento' });
            }else{
                res.status(200).send(queryResult);
            }
        })
    })


    server.use('/', router);


}

