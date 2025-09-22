"use strict"

const connection = require('../config/database');
const express = require('express');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
require('dotenv').config();

module.exports = (server) => {
    const router = express.Router();

    router.post('/auth/register', (req, res) => {
        const { fullName, birthdate, email, phone, password } = req.body;

        const verifyEmailAlreadyInUse = `SELECT COUNT(*) AS cont FROM usuario WHERE email = ?`;

        connection.query(verifyEmailAlreadyInUse, [email], (emailError, emailResult, emailFields) => {
            const ans = {};

            if (emailError) {
                console.log("Error on VERIFYING EMAIL: ");
                console.error(emailError);
                emailError.err = true;
                res.json(emailError);
            } else {
                if (emailResult[0].cont === 0) {
                    bcrypt.hash(password, 12, (hashErr, hash) => {
                        if (hashErr) {
                            console.log("Error on HASHING password: ");
                            console.error(hashErr);
                            hashErr.err = true;
                            res.json(hashErr);
                        } else {
                            const query = 
                            `INSERT INTO usuario 
                            (nome_completo, nascimento, email, celular, senha) 
                            VALUES (?, ?, ?, ?, ?)`;
            
                            connection.query(query, [fullName, birthdate, email, phone, hash], (queryError, queryResult, queryFields) => {
                                if (queryError) {
                                    console.log("Error on REGISTER USER query: ");
                                    console.error(queryError);
                                    queryError.err = true;
                                    res.json(queryError);
                                } else {
                                    ans.status = "ok";
                                    ans.desc = "successfully registered"
                                    res.json(ans);
                                }
                            });
                        }
                    });
                } else {
                    ans.status = "error";
                    ans.desc = "email already in use";
                    res.json(ans);
                }
            }
        })
    });

    router.post('/auth/registerCpf', (req,res)=>{
        const { cpf, id_usuario } = req.body;

        const query = `UPDATE usuario SET cpf = ? WHERE id_usuario = ?`;

        connection.query(query, [cpf, id_usuario], (queryError, queryResult, queryFields) => {
            const ans = {};

            if (queryError) {
                console.log("Error on REGISTER CPF query: ");
                console.error(queryError);
                queryError.err = true;
                res.json(queryError).status(500);
            } else {
                ans.status = "ok";
                ans.desc = "successfully registered CPF"
                res.json(ans).status(200);
            }
        }
        )
    })

    router.post('/auth/login', (req, res) => {
        console.log("tentativa de login");
        console.log(req.body)
        const { email, password } = req.body;

        const query = `SELECT senha, id_usuario FROM usuario WHERE email = ?`;

        connection.query(query, [email], async (queryError, queryResult, queryFields) => {
            const ans = {};
            console.log(queryResult)
            if (queryError) {
                console.log("Error on USER LOGIN query: ");
                console.error(queryError);
                queryError.err = true;
                res.json(queryError);
            } else {
                if (queryResult.length > 0) {
                    await bcrypt.compare(password, queryResult[0].senha, (compareError, compareResult) => {
                        if (compareError) {
                            console.log("Error on COMPARE PASSWORD: ");
                            console.error(compareError);
                            compareError.err = true;
                            res.json(compareError);
                        } else {
                            if (compareResult === true) {
                                const token = jwt.sign(
                                    {
                                        email: email,
                                        password: password,
                                        id_usuario: queryResult[0].id_usuario
                                    },
                                    process.env.JWTSECRET,
                                    {expiresIn: '30d'}
                                );
                                
                                ans.token = token;
                                ans.status = "ok";
                                ans.desc = "successfully logged";
                                ans.idClient = queryResult[0].cliente;
                                res.json(ans);
                            } else {
                                ans.status = "error";
                                ans.desc = "noSuchUserWrongPass";
                                res.json(ans);
                            }
                        }
                    })
                } else {
                    ans.status = "error";
                    ans.desc = "noSuchUserWrongPass";
                    res.json(ans);
                    console.log(ans)
                }
            }
        })
    });

    server.use('/', router)
}