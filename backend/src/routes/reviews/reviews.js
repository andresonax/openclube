"use strict"

require('dotenv').config()
const connection = require('../../config/database')
const express = require('express')

module.exports = (server) => {
    const router = express.Router()

    //cria ou atualiza avaliações de arenas/clientes
    router.post('/reviews', (req, res) => {
        console.log(req.body);
        const id_usuario = req.body.id_usuario;
        const id_cliente = req.body.id_cliente;
        const stars = req.body.stars;
    
        // Verifica se a avaliação já existe
        const checkQuery = 'SELECT * FROM l_avaliacoes WHERE id_usuario = ? AND id_cliente = ?';
        connection.query(checkQuery, [id_usuario, id_cliente], (checkError, checkResult) => {
            if (checkError) {
                console.error("Error on checking existing review:");
                return res.status(500).json(checkError);
            }
    
            const updateOrInsertReview = () => {
                const query = checkResult.length > 0 ?
                    `UPDATE l_avaliacoes SET quantidade_estrelas = ? WHERE id_usuario = ? AND id_cliente = ?` :
                    `INSERT INTO l_avaliacoes (id_usuario, id_cliente, quantidade_estrelas) VALUES (?, ?, ?)`;
    
                const params = checkResult.length > 0 ?
                    [stars, id_usuario, id_cliente] :
                    [id_usuario, id_cliente, stars];
    
                connection.query(query, params, (error, result) => {
                    if (error) {
                        console.error("Error on updating/inserting review:");
                        return res.status(500).json(error);
                    }
    
                    // Calcula a nova média e quantidade de avaliações
                    const statsQuery = `
                        SELECT COUNT(*) AS total_reviews, AVG(quantidade_estrelas) AS average_stars
                        FROM l_avaliacoes
                        WHERE id_cliente = ?
                    `;
                    connection.query(statsQuery, [id_cliente], (statsError, statsResult) => {
                        if (statsError) {
                            console.error("Error on calculating stats:");
                            return res.status(500).json(statsError);
                        }
    
                        const totalReviews = statsResult[0].total_reviews;
                        const averageStars = statsResult[0].average_stars;
    
                        // Atualiza a tabela l_cliente_detalhes
                        const updateDetailsQuery = `
                            UPDATE l_cliente_detalhes
                            SET quantidade_avaliacoes = ?, estrelas = ?
                            WHERE id_cliente = ?
                        `;
                        connection.query(updateDetailsQuery, [totalReviews, averageStars, id_cliente], (updateDetailsError) => {
                            if (updateDetailsError) {
                                console.error("Error on updating l_cliente_detalhes:");
                                return res.status(500).json(updateDetailsError);
                            }
                            res.status(200).json({ status: "ok", desc: "review processed and details updated" });
                        });
                    });
                });
            };
    
            updateOrInsertReview();
        });
    });

    //busca quantidade de estrelas e quantidade de avaliações de arena/cliente por ibge
    router.get('/reviews/:ibge', (req,res)=>{
        const ibge = req.params.ibge
        const query = `SELECT estrelas, quantidade_avaliacoes
                       FROM l_cliente_detalhes as d
                       JOIN cliente as c
                       WHERE c.id_cliente = d.id_cliente
                       AND c.ibge = ?
                       ORDER BY c.id_cliente`
        connection.query(query, [ibge], (error, result)=>{
            if(error){
                console.error("Error on reading reviews");
                return res.status(500).json(error);
            }else{
                return res.status(200).json(result);
            }
        })
    })
    
    
    server.use('/', router);
}