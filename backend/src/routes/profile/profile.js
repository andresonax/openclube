"use strict"

require('dotenv').config()
const connection = require('../../config/database')
const express = require('express')
const moment = require('moment')
const path = require('path');
const fs = require('fs');

module.exports = (server) => {
    const router = express.Router()

    // Função para encontrar imagem de perfil com base no ID do usuário
    function findUserImageFile(userId) {
        return new Promise((resolve, reject) => {
            const uploadsDir = path.join(__dirname, '../../../files/uploads');
            
            fs.readdir(uploadsDir, (err, files) => {
                if (err) {
                    reject(err);
                    return;
                }
    
                // Filtra arquivos que terminam com `_userId.png`
                const userImageFile = files.find(file => file.endsWith(`_${userId}.png`));
                resolve(userImageFile ? path.join(uploadsDir, userImageFile) : null);
            });
        });
    }

    //busca foto de perfil de user
    router.get('/profile/getPicture/:id', async (req, res) => {
        const id = parseInt(req.params.id);
        try {
            const imagePath = await findUserImageFile(id);
            if (!imagePath) {
                return res.status(404).send('Imagem não encontrada');
            }
            res.sendFile(imagePath);
        } catch (error) {
            console.error('Erro ao buscar imagem:', error);
            res.status(500).send('Erro ao buscar imagem');
        }
    });



    //apaga conta de usuário
    router.delete('/profile/:id', (req,res)=> {
        const id = parseInt(req.params.id);
        const query = `DELETE FROM usuario WHERE id_usuario = ?`;
        connection.query(query, [id], (error, results, fields) => {
            if (error) {
                console.error("Error on DELETE BY ID profile:")
                console.error(error);
                error.err = true;
                res.status(500).json({ error: 'Não foi possível apagar usuário' });
            }
            else {
                res.status(200).send();
            }
        });
    })

    //atualiza perfil de usuário
    router.post('/profile/:id', (req, res) => {
        const { nome_completo, email, celular, imagem, nome_imagem } = req.body;
        console.log(req.body);
        const nascimento = moment(req.body.nascimento, 'YYYY/MM/DD').format('YYYY-MM-DD');
        const id = parseInt(req.params.id);

        const imageBuffer = Buffer.from(imagem, 'base64');
        const imagePath = path.join(__dirname, '../../../files/uploads', Date.now() + '_' + nome_imagem);

        // Verifica se o e-mail já está cadastrado na base de dados
        const emailCheckQuery = 'SELECT id_usuario FROM usuario WHERE email = ? AND id_usuario != ?';
        connection.query(emailCheckQuery, [email, id], async (emailCheckError, emailCheckResults) => {
            if (emailCheckError) {
                res.status(500).json(emailCheckError);
            } else if (emailCheckResults.length > 0) {
                // Se encontrar algum registro com o mesmo e-mail e diferente id, significa que o e-mail já está em uso
                res.status(400).json({ error: 'Email já está em uso' });
            } else {
                // Se o e-mail não estiver em uso, continua com a atualização
                // Verifica se existe necessidade de troca da imagem guardada no server
                if(imageBuffer != ''){
                    const oldImagePath = await findUserImageFile(id);
                    if (oldImagePath) {
                        fs.unlink(oldImagePath, (unlinkErr) => {
                            if (unlinkErr) {
                                console.error('Error deleting old image:', unlinkErr);
                            }
                        });
                    }
                     // Salva a nova imagem
                     if (imageBuffer.length > 0) {
                        fs.writeFile(imagePath, imageBuffer, (writeErr) => {
                            if (writeErr) {
                                res.status(500).json(writeErr);
                                return;
                            }
                        });
                    }
                }
                
                const updateQuery = `UPDATE usuario SET nome_completo = ?, nascimento = ?, email = ?, celular = ? WHERE id_usuario = ?`;
                connection.query(updateQuery, [nome_completo, nascimento, email, celular, id], (updateError, updateResult) => {
                    if (updateError) {
                        console.log("Error on UPDATE USER: ");
                        console.error(updateError);
                        res.status(500).json(updateError);
                    } else {
                        res.json({"imagePath": imagePath, "nome_completo": nome_completo});
                        res.status(200);
                    }
                });
            }
        });
    });

    //pega dados de usuário com base no id
    router.get('/profile/:id', (req,res)=>{
        const { id } = req.params
        const query = 'SELECT * FROM usuario WHERE id_usuario = ?'
        connection.query(query, [id], (queryError, queryResult, queryFields) => {
            if (queryError) {
                console.log("Error on QUERY: ");
                console.error(queryError);
                queryError.err = true;
                res.json(queryError).status(500);
            } else {
                if (queryResult.length > 0) {
                    res.json(queryResult).status(200)
                } else {
                    res.json({ err: true, message: 'usuario não encontrado' }).status(404)
                }
            }
        })
    })
    
    server.use('/', router);

}