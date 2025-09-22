"use strict"

process.env.TZ = 'UTC'

const fs = require('fs')


if(fs.existsSync('.env')){
    console.log("RUNNING FROM .ENV")
    require("dotenv").config()
}else{
    console.log("RUNNING FROM DEV FALLBACK")
    process.env.COOKIESECRET = "cookieSecretDev"
    process.env.JWTSECRET = "jwtSecretDev"
}

const { server, serverInstance } = require("./config/server")
const { corsAllow } = require('./config/globals')


const io = require("socket.io")(serverInstance)
const middleware = require('socketio-wildcard')()
io.use(middleware)


/* configuração socket io
const io = require("socket.io")(serverInstance, {
  cors: {
    origin: "*", 
    methods: ["GET", "POST"]
  }
});

const middleware = require('socketio-wildcard')();
io.use(middleware);
*/


// Rota de chat com socket
//require("./routes/chat/chat")(io);


//verifica se servidor está online
require('./routes/verifyServer/verifyServer')(server);

//permite login e registro
require('./auth/auth')(server);

//rotas de cupom
require('./routes/cupom/cupom')(server);

//permite recuperação de senha
require('./pwRecovery/pwRecovery')(server);

//rota para dados de user
require("./routes/profile/profile")(server);

//rota para buscar cidades
require("./routes/cities/cities")(server);

//rota para buscar clientes
require("./routes/clients/clients")(server);

//rota para avaliações de clientes
require("./routes/reviews/reviews")(server);

//rota para busca de timeslots
require("./routes/timeSlots/timeSlots")(server);

//rota para locação
require('./routes/agenda/agenda_routes')(server);



//rota para compra locacao
require("./routes/compra/compra_routes")(server);

//rota para mensagens do chat
require("./routes/chat/chat_routes")(server);

//rota para métodos e condições de pagamento
require("./routes/pagamento/pagamento")(server);

//rota para bloqueios de grade
require("./routes/bloqueio_grade/bloqueio_grade_routes")(server);

//rota para webhooks do inter
require("./routes/financeiro/banks/inter/inter_webhook")(server);

//rota para envio de mensagens por whatsapp
/*
require("./routes/whatsapp/whatsapp")(server);
*/
//rota padrão
require("./config/defaultRoutes")(server);

