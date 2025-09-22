const connection = require("../config/database");
var nodemailer = require("nodemailer");

//Obtém o transporte do email
const getTransporte = (configsEmail) => {
  return nodemailer.createTransport({
    service: configsEmail.servico,
    auth: {
      user: configsEmail.emailRem,
      pass: configsEmail.senha, // é a senha da nossa conta
    },
  });
};

//Processa a mensagem de erro
const getErrorMsg = (error) => {
  var msg;
  if (error.response)
    msg =
      error.response.substring(0, 45) +
      (error.response.charAt(45) == " " ? "" : "...");
  return msg;
};

//Carrega as configurações do email
const loadConfigsEmail = () => {
  return new Promise((resolve, reject) => {
    connection.query("SELECT * FROM config_email", (error, results) => {
      if (error) reject(error);
      else resolve(results[0]);
    });
  });
};

/*
  dadosEmail={
    emailDest: string,
    assuntoMsg: string,
    bodyMsg: string,
    attachments?: [{
      filename: string,
      path: string
    }, ...]
  }
*/
//Envia o email
const sendEmail = async (dados) => {
  try {
    const configsEmail = await loadConfigsEmail();
    var email = {
      from: configsEmail.emailRem, // Quem enviou este e-mail
      to: dados.emailDest, // Quem receberá
      subject: dados.assuntoMsg, // Um assunto bacana :-)
      html: dados.bodyMsg, // O conteúdo do e-mail
      attachments: dados.attachments,
    };
    const transporte = getTransporte(configsEmail);
    let info = await transporte.sendMail(email);
    if (info.accepted.length == 0) throw info.rejected[0];
  } catch (error) {
    error.msg = getErrorMsg(error);
    throw error;
  }
};

module.exports = {
  sendEmail,
};
