"use strict"

require('dotenv').config()
const connection = require('../../config/database')
const express = require('express')

module.exports = (server) => {
    const router = express.Router()

    router.get('/cities/:name', (req,res)=>{
        const city_name = req.params.name

        const query = `SELECT DISTINCT cli.ibge, concat(nomeCidade, "/", ufcidade)
                      as cidade FROM cliente cli inner join g_cadcidades cid on
                      cli.ibge = cid.ibge where nomeCidade COLLATE latin1_general_ci
                      like "%${city_name}%"`
        connection.query(query, (queryError, queryResult, querryFields)=>{
            if(queryError){
                console.log("Error on get cities")
                console.error(queryError)
                res.json(queryError)
            }else{
                res.json(queryResult)
            }
        })
    })

        server.use('/', router)
    }