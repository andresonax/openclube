const connection = require("../../config/database"); // ATENCÃO A ESTE PATH!!!
const { parse } = require("node-html-parser");
const moment = require("moment");
const { readById } = require("../espaco/espaco_resources");
const {
  readModalidadeById,
} = require("../modalidade_espaco/modalidade_espaco_resources");
const { readAgendasByCompra } = require("../agenda/agenda_resources");
const { readConfigs } = require("../configs/configs_resources");
const { getDadosUsuario } = require("../usuario_app/usuario_app_methods");
const { sendEmail } = require("../../utils/email");
const { dataHoraToMoment } = require("../../utils/utils");

//Formata a mensagem geral
const formatMsgGeral = (msgGeral, compra) => {
  const dataHoraCompra = moment(compra.data_hora_compra);
  msgGeral = msgGeral.replace(/{{cliente_compra}}/gi, compra.nome_usuario);
  msgGeral = msgGeral.replace(
    /{{hora_compra}}/gi,
    dataHoraCompra.format("HH:mm")
  );
  msgGeral = msgGeral.replace(
    /{{valor_compra}}/gi,
    parseFloat(compra.valor_total).toFixed(2)
  );
  return parse(msgGeral);
};

//Formata a mensagem de agendamento
const formatMsgAgendamento = async (msgAgendamentos, agenda) => {
  const [espaco] = await readById(agenda.id_espaco);
  const [modalidade] = await readModalidadeById(agenda.id_modalidade_espaco);
  const nomeEspaco = espaco ? espaco.nome : "-";
  const nomeModalidade = modalidade ? modalidade.nome_modalidade : "-";
  msgAgendamentos = msgAgendamentos.replace(/{{espaco_agenda}}/gi, nomeEspaco);
  msgAgendamentos = msgAgendamentos.replace(
    /{{modalidade_agenda}}/gi,
    nomeModalidade
  );
  msgAgendamentos = msgAgendamentos.replace(
    /{{hora_inicio}}/gi,
    agenda.horario
  );
  msgAgendamentos = msgAgendamentos.replace(
    /{{hora_fim}}/gi,
    agenda.horario_final
  );
  msgAgendamentos = msgAgendamentos.replace(
    /{{data_agenda}}/gi,
    moment(agenda.data_agenda).format("DD/MM/YYYY")
  );
  return msgAgendamentos;
};

//Obtém as mensagens para cada agendamento
const getAgendasMsg = async (msgAgendamentos, agendaList) => {
  const agendasMsg = parse(`<ul style="list-style-type: circle;"></ul>`);
  const agendasUL = agendasMsg.querySelector("ul");
  for (let i = 0; i < agendaList.length; i++) {
    const formattedMsgAgendamento = await formatMsgAgendamento(
      msgAgendamentos,
      agendaList[i]
    );
    agendasUL.appendChild(parse(`<li>${formattedMsgAgendamento}</li>`));
  }
  return agendasMsg;
};

//Formata a mensagem de alerta de compra
const formatMsgAlertaCompra = async (
  msgGeral,
  msgAgendamentos,
  compra,
  agendaList
) => {
  const msgHTML = parse("<div></div>");
  const mainDiv = msgHTML.querySelector("div");
  const formattedMsgGeral = formatMsgGeral(msgGeral, compra);
  const agendasMsg = await getAgendasMsg(msgAgendamentos, agendaList);
  mainDiv.appendChild(formattedMsgGeral);
  mainDiv.appendChild(agendasMsg);
  return msgHTML.toString();
};

//Lê compra por id
const readCompraById = async (id_compra) => {
  return await new Promise((resolve, reject) => {
    connection.query(
      "SELECT * FROM l_compra WHERE id_compra = ?;",
      [id_compra],
      (error, results) => {
        if (error) reject(error);
        else {
          //Converte a data para moment
          if (results.length)
            results[0].data_hora_compra = dataHoraToMoment(
              results[0].data_hora_compra
            );
          resolve(results);
        }
      }
    );
  });
};

//Constrói a mensagem do alerta da compra
const buildMsgAlertaCompra = async (id_compra, configs) => {
  const [compra] = await readCompraById(id_compra);
  const usuario = await getDadosUsuario(compra.id_usuario, compra.tipo_usuario);
  compra.nome_usuario = usuario.nome;
  const agendaList = await readAgendasByCompra(compra);
  const msg = await formatMsgAlertaCompra(
    configs.msg_geral_alerta_compra,
    configs.msg_agendamentos_alerta_compra,
    compra,
    agendaList
  );
  return msg;
};

//Carrega os funcionários com certo perfil
const loadFuncionarioByPerfil = async (id_perfil) => {
  return await new Promise((resolve, reject) => {
    connection.query(
      "SELECT * FROM pessoa WHERE id_perfil = ?",
      [id_perfil],
      (error, results) => {
        if (error) reject(error);
        else resolve(results);
      }
    );
  });
};

//Envia os emails
const sendEmails = async (listaFuncionario, msg, configs) => {
  const assuntoMsg = configs.assunto_alerta_compra;
  for (let i = 0; i < listaFuncionario.length; i++) {
    const emailDest = listaFuncionario[i].email;
    if (!emailDest) continue;
    const dadosEmail = {
      emailDest,
      assuntoMsg,
      bodyMsg: msg,
    };
    await sendEmail(dadosEmail);
  }
};

//Envia o alerta de compra
const enviaAlertaCompra = async (id_compra) => {
  const configs = await readConfigs();
  const msg = await buildMsgAlertaCompra(id_compra, configs);
  const listaFuncionario = await loadFuncionarioByPerfil(
    configs.id_perfil_alerta_compra
  );
  await sendEmails(listaFuncionario, msg, configs);
};

module.exports = {
  formatMsgAlertaCompra,
  enviaAlertaCompra,
};
