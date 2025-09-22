"use strict";

require('dotenv').config();
const express = require('express');
const venom = require('venom-bot');

module.exports = (server) => {
    const router = express.Router();

    // Criar o client ao iniciar o app
    venom.create({
            session: 'whatsapp-session', 
            headless: true,
            puppeteerOptions: {
            args: ['--headless=new'], 
            },
        })
        .then((client) => {
            // Rota para enviar o código PIX
            router.post('/whatsapp/send-pix-code', async (req, res) => {
                const phoneNumber = req.body.phone_number; 
                const pixCode = req.body.pix_code;

                try {
                    await client.sendText(`${phoneNumber}@c.us`, `Olá! Esse é o seu código PIX para pagamento do seu agendamento de quadra:\n\n${pixCode}`);
                    console.log(`PIX enviado para ${phoneNumber}`);
                    res.status(200).json({ message: 'Código PIX enviado com sucesso!' });
                } catch (error) {
                    console.error('Erro ao enviar PIX:', error);
                    res.status(500).json({ message: 'Erro ao enviar o código PIX.' });
                }
            });

            // Rota para confirmação de pagamento
            router.post('/whatsapp/send-payment-confirmation', async (req, res) => {
                const phoneNumber = req.body.phone_number;

                try {
                    await client.sendText(`${phoneNumber}@c.us`, `✅ Pagamento confirmado! Obrigado.`);
                    console.log(`Confirmação enviada para ${phoneNumber}`);
                    res.status(200).json({ message: 'Confirmação de pagamento enviada com sucesso!' });
                } catch (error) {
                    console.error('Erro ao enviar confirmação:', error);
                    res.status(500).json({ message: 'Erro ao enviar confirmação de pagamento.' });
                }
            });

            server.use('/', router);
        })
        .catch((err) => {
            console.error('Erro ao iniciar sessão do WhatsApp:', err);
        });
};
