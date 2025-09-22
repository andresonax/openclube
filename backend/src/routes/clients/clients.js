"use strict"
require('dotenv').config()
const connection = require('../../config/database')
const express = require('express')
const path = require('path');

module.exports = (server) => {
    const router = express.Router()

    //busca todos clientes/arenas de determinada cidade
    router.get('/clients/:IBGE', (req,res)=>{
        const city_IBGE = req.params['IBGE']
        const query = `
         SELECT
         c.fantasia, c.id_cliente, c.cep, c.endereco, d.info, d.descricao
         FROM cliente as c
         JOIN l_cliente_detalhes as d
         ON c.id_cliente = d.id_cliente
         WHERE ibge = ?
        `
        connection.query(query, [city_IBGE], (queryError, queryResult, queryFields)=>{
            if(queryError){
                console.log("ERROR on reading client:")
                console.error(queryError)
                queryError.err = true;
                res.json(queryError).status(500)
            }else{
                res.json(queryResult).status(200)
            }
        })  
    })

    //busca todos dados de determinado cliente pelo id
    router.get('/client/:id', (req,res)=>{
        const id = req.params['id']
        
        const query = `
            SELECT
            c.fantasia, c.id_cliente, c.cep, c.endereco, d.info, d.descricao, d.cancelamento
            FROM cliente as c
            JOIN l_cliente_detalhes as d
            ON c.id_cliente = d.id_cliente
            WHERE c.id_cliente = ?
        `
        connection.query(query, [id], (queryError, queryResult, queryFields)=>{
            if(queryError){
                console.log("ERROR on reading client:")
                console.error(queryError)
                queryError.err = true;
                res.json(queryError).status(500)
            }else{
                res.json(queryResult).status(200)
            }
        })  
    })

    /*
    router.get('/clients/:IBGE', (req,res)=>{
        const city_IBGE = req.params['IBGE']
        const query = `SELECT fantasia, id_cliente, description, info FROM cliente WHERE ibge = ?`
        connection.query(query, [city_IBGE], (queryError, queryResult, queryFields)=>{
            if(queryError){
                console.log("ERROR on reading client:")
                console.error(queryError)
                queryError.err = true;
                res.json(queryError).status(500)
            }else{
                res.json(queryResult).status(200)
            }
        })  
    })*/

    //busca logo de determinado cliente pelo id
    router.get('/clients/getLogo/:id', (req, res) => {
        const id_cliente = req.params.id
        const fullPath = path.join(__dirname + `../../../../files/clientLogos/logo-${id_cliente}.png`)
        res.sendFile(fullPath)
    })

    
    //busca imagem de quadras pelo id da quadra
    router.get('/clients/courts/picture/:idCourt', (req,res) => {
        const id_quadra = req.params.idCourt
        const fullPath = path.join(__dirname + `../../../../files/courtsPics/pic-${id_quadra}.png`)
        res.sendFile(fullPath)
    })

    
    //busca quadras de determinado cliente pelo id
    router.get('/clients/courts/:id', (req, res) => {
        const id_cliente = req.params.id;
        const query = `
            SELECT 
                l_espaco.*,
                l_modalidade_espaco.*
                
            FROM 
                l_espaco
            JOIN 
                l_espaco_modalidade ON l_espaco.id_espaco = l_espaco_modalidade.id_espaco
            JOIN 
                l_modalidade_espaco ON l_espaco_modalidade.id_modalidade_espaco = l_modalidade_espaco.id_modalidade_espaco
            WHERE 
                l_espaco.id_cliente = ?;
        `;
        
        connection.query(query, [id_cliente], (queryError, queryResult) => {
            if (queryError) {
                console.log('ERROR on reading courts');
                console.error(queryError);
                queryError.err = true;
                res.status(500).json(queryError);
            } else {
                res.status(200).json(queryResult);
            }
        });
    });
        
    server.use('/', router);
}