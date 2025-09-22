"use strict";

require('dotenv').config();
const express = require('express');
const venom = require('venom-bot');

module.exports = (server) => {
    const router = express.Router();
    const clients = {}; 

    // Criar uma nova sessão e retornar o QR Code
    router.post('/whatsapp/create-session', async (req, res) => {
        const sessionName = req.body.session_name;

        if (!sessionName) {
            return res.status(400).json({ message: 'session_name é obrigatório' });
        }

        if (clients[sessionName]) {
            return res.status(200).json({ message: 'Sessão já criada.' });
        }

        venom.create(
            sessionName,
            (base64Qrimg, asciiQR, attempts, urlCode) => {
                // Retornar o QR Code pro frontend
                res.status(200).json({ qr: base64Qrimg, message: 'Escaneie o QR code para conectar' });
            },
            (statusSession, session) => {
                console.log(`Status da sessão ${session}: ${statusSession}`);
            },
            {
                headless: true,
                useChrome: false,
                logQR: false, // não loga no terminal
                browserArgs: ['--headless=new'],
            }
        ).then((client) => {
            clients[sessionName] = client;
        }).catch((err) => {
            console.error('Erro ao criar sessão:', err);
            res.status(500).json({ message: 'Erro ao criar sessão' });
        });
    });

    // Enviar mensagem via sessão específica
    router.post('/whatsapp/send-message', async (req, res) => {
        const { session_name, phone_number, message } = req.body;

        const client = clients[session_name];
        if (!client) {
            return res.status(404).json({ message: 'Sessão não encontrada.' });
        }

        try {
            await client.sendText(`${phone_number}@c.us`, message);
            res.status(200).json({ message: 'Mensagem enviada com sucesso!' });
        } catch (error) {
            console.error('Erro ao enviar mensagem:', error);
            res.status(500).json({ message: 'Erro ao enviar mensagem.' });
        }
    });

    server.use('/', router);
};
