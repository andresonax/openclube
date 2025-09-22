"use strict"

require('dotenv').config()
const connection = require('../../config/database')
const express = require('express')

module.exports = (server) => {
    const router = express.Router()

    router.post('/coupon/validate', (req,res)=>{
        const id_cliente = req.body.id_cliente;
        const cupom = req.body.cupom;

        const query = `SELECT * FROM l_cupom WHERE id_cliente = ? AND cupom = ? AND validade >= NOW()`
        connection.query(query, [id_cliente, cupom], (queryError, queryResult, querryFields)=>{
            if(queryError){
                console.log("Error on get coupon")
                console.error(queryError)
                res.json(queryError)
            }else{
                res.json(queryResult)
            }
        })
    })

    server.use('/', router)
}