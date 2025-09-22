"use strict"

const connection = require('../config/database');
const express = require('express');
const jwt = require('jsonwebtoken');
const nodemailer = require('nodemailer');
const bcrypt = require('bcrypt');
require("dotenv").config();

const generateRecoveryCode = () => {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    let recoveryCode = '';
    for (let i = 0; i < 5; i++) {
        const randomI = Math.floor(Math.random() * chars.length);
        recoveryCode += chars.charAt(randomI);
    }

    return recoveryCode;
}

const transporter = nodemailer.createTransport({
    service: 'gmail',
    auth: {
        user: "gravou@sonaxsistemas.com.br",
        pass: "zemynrcmrnhjlcrd"
    } 
});

var mailOptions = {
    from: 'Clube da Areia',
    to: '',
    subject: 'Recuperação de senha',
    html: ''
}

module.exports = (server) => {
    const router = express.Router();

    router.post('/pwRecovery/sendCode', (req, res) => {
        const { email } = req.body;
        console.log(email)

        const verifyEmail = `SELECT id_usuario FROM usuario WHERE email = ?`;

        connection.query(verifyEmail, [email], (emailError, emailResult, emailFields) => {
            const ans = {};

            if (emailError) {
                console.log("Error on VERIFYING EMAIL: ");
                console.error(emailError);
                emailError.err = true;
                res.json(emailError);
            } else {
                if (emailResult.length > 0) {
                    const recoveryCode = generateRecoveryCode();

                    const token = jwt.sign(
                        {id: emailResult[0].id_usuario,
                        recoveryCode: recoveryCode},
                        process.env.JWTSECRET,
                        {expiresIn: 300}
                    );

                    var emailContent = 
                    `<body>
                        <h1>Código de Recuperação</h1>
                        <p>Aqui está o seu código de recuperação:</p>
                        
                        <p> ${recoveryCode} </p>

                        <p> Para recuperar sua senha, insira esse código no aplicativo. </p>
                    </body>`

                    mailOptions.to = email;
                    mailOptions.html = emailContent;

                    transporter.sendMail(mailOptions, (sendEmailError, sendEmailResult) => {
                        if (sendEmailError) {
                            console.log("Error on SENDING EMAIL: ");
                            console.error(sendEmailError);
                            sendEmailError.err = true;
                            res.json(sendEmailError);
                        } else {
                            ans.status = "ok";
                            ans.desc = "email sent";
                            ans.token = token;
                            res.json(ans);
                        }
                    });
                } else {
                    ans.status = "error";
                    ans.desc = "email not found";
                    res.json(ans);
                }
            }
        });
    });

    router.post("/pwRecovery/verifyCode", (req, res) => {
        const { code, token } = req.body;
        const ans = {};

        try {
            jwt.verify(token, process.env.JWTSECRET);
            if ((jwt.decode(token, process.env.JWTSECRET)).recoveryCode == code) {
                ans.status = "ok";
                ans.desc = "code is valid";
            } else {
                ans.status = "error";
                ans.desc = "code isnt valid";
            }

            res.json(ans);
        } catch (tokenError) {
            ans.status = "error";
            ans.desc = "token isnt valid";
            res.json(ans);
        }
    });

    router.patch("/pwRecovery/changePw/:id", (req, res) => {
        const id = parseInt(req.params.id);
        const password = req.body.password;
        const ans = {};

        const query = `UPDATE usuario SET senha = ? WHERE id_usuario = ?`;

        bcrypt.hash(password, 12, (hashErr, hash) => {
            if (hashErr) {
                console.log("Error on HASHING password: ");
                console.error(hashErr);
                hashErr.err = true;
                res.json(hashErr);
            } else {
                connection.query(query, [hash, id], (passwordError, passwordResult, passwordFields) => {
                    if (passwordError) {
                        console.error("Error on UPDATE PASSWORD: ");
                        console.error(passwordError);
                        passwordError.err = true;
                        res.json(passwordError);
                    } else {
                        ans.status = "ok";
                        ans.desc = "password updated";
                        res.json(ans);
                    }
                });
            }
        });
    });

    server.use('/', router);
};