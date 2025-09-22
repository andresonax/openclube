const pdf = require("html-pdf");
const moment = require("moment");
const { uploadsPath } = require("../../config/globals");
const { getDadosUsuario } = require("../usuario_app/usuario_app_methods");
const { readByDay } = require("../agenda/agenda_resources");
const { splitArrayInChunks, getImgBase64 } = require("../../utils/utils");
const conection = require("../../config/database");
const { getHeader } = require("./relatorio_utils");

//Número de agendamentos por página
const numAgendasPerPage = 40;
//CSS do relatório
const styleRelatorio = `
  <style>
    @import url('https://fonts.googleapis.com/css2?family=Poppins:ital,wght@0,100;0,200;0,300;0,400;0,500;0,600;0,700;0,800;0,900;1,100;1,200;1,300;1,400;1,500;1,600;1,700;1,800;1,900&display=swap')
  </style>
  <style>
    .page {
      page-break-after: always;
    }

    .page:last-of-type {
      page-break-after: avoid;
    }

    p, b, h1, h2 {
      display: inline-block;
      margin: 0;
    }

    p, b, h1, h2, td, th {
      font-family: "Poppins", sans-serif;
    }

    .content {
      display: flex;
      display: -webkit-flex;
      flex-direction: column;
      -webkit-flex-direction: column;
      margin: 20px 50px;
    }

    .content div {
      margin-bottom: 20px;
    }

    .header {
      display: flex;
      display: -webkit-flex;
      flex-direction: row;
    }

    .logo img {
      height: 100px;
    }

    .dados {
      display: flex;
      display: -webkit-flex;
      flex-direction: column;
      -webkit-flex-direction: column;
      flex-wrap: wrap;
      -webkit-flex-wrap: wrap;
      justify-content: end;
      -webkit-justify-content: end;
      padding: 10px 30px;
    }

    .dado_empresa {
      margin: 0;
    }

    .dado_empresa b {
      font-size: 14px;
    }

    .dado_empresa h2 {
      font-size: 20px;
    }

    .title {
      display: flex;
      display: -webkit-flex;
      justify-content: center;
      -webkit-justify-content: center;
    }

    .title h1 {
      font-size: 23px;
    }

    .body table {
      width: 100%;
      border-collapse: collapse;
    }

    .body tr {
      border-bottom: 1px solid black;
    }

    .body th {
      text-align: left;
    }
  </style>
`;

//Função que gera o PDF
const generatePdf = async (relatorioPath, html) => {
  return await new Promise((resolve, reject) => {
    pdf
      .create(html, { format: "A3" })
      .toFile(relatorioPath, function (err, res) {
        if (err) return reject(err);
        resolve(res);
      });
  });
};

//Lê os agendamentos, divididos por página
const readAgendamentos = async (data) => {
  const agendas = await readByDay(data.format("YYYY-MM-DD"));
  for (var i = 0; i < agendas.length; i++) {
    const dadosUsuario = await getDadosUsuario(
      agendas[i].id_usuario,
      agendas[i].tipo_usuario
    );
    agendas[i].nome_usuario = dadosUsuario.nome;
  }
  //Se não houver agendamentos, gera ao menos uma página vazia
  if (!agendas.length) return [[]];
  return splitArrayInChunks(agendas, numAgendasPerPage);
};

//Obtém as entradas do relatório
const getEntries = (agendas) => {
  var entries = "";
  for (var i = 0; i < agendas.length; i++) {
    entries += `
      <tr>
        <td>${moment(agendas[i].horario, "HH:mm").format("HH:mm")}</td>
        <td>${moment(agendas[i].horario_final, "HH:mm").format("HH:mm")}</td>
        <td>${agendas[i].nome_usuario}</td>
        <td>${agendas[i].nome_espaco}</td>
        <td>${agendas[i].nome_modalidade}</td>
      </tr>
    `;
  }
  return entries;
};

//Obtém uma única página do relatório
const getPage = async (data, agendas, header) => {
  var entries = getEntries(agendas);
  return `
    <div class="content">
      ${header}
      <div class="title">
        <h1>
          Relatório de Agendamentos - ${data.format("DD/MM/YYYY")}
        </h1>
      </div>
      <div class="body">
        <table>
          <tr>
            <th>Início</th>
            <th>Fim</th>
            <th>Solicitante</th>
            <th>Espaço</th>
            <th>Modalidade</th>
          </tr>
          ${entries}
        </table>
      </div>
    </div>
  `;
};

//Obtém todas as páginas do relatório
const getAllPages = async (data, header) => {
  const agendasPorPag = await readAgendamentos(data);
  var pages = "";
  for (var i = 0; i < agendasPorPag.length; i++)
    pages += await getPage(data, agendasPorPag[i], header);
  return pages;
};

//Obtém o HTML do relatório
const getHtml = async (data) => {
  const header = await getHeader();
  const pages = await getAllPages(data, header);
  const html = `
    <!DOCTYPE html>
    <html lang="en">
      <head>
        <meta charset="UTF-8">
        <meta http-equiv="X-UA-Compatible" content="IE=edge">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Relatório de Agendamentos</title>
        ${styleRelatorio}
      </head>
      <body>
        ${pages}
      </body>
    </html>
  `;
  return html;
};

//Obtém o path do arquivo do relatório
const getFilePath = (data) => {
  var txtData = data.format("DD_MM_YYYY");
  return `./${uploadsPath}/relatorio_agenda_${txtData}.pdf`;
};

//Gera o relatório de agendamentos
const relatorioAgenda = async (data) => {
  const html = await getHtml(data);
  const path = getFilePath(data);
  await generatePdf(path, html);
  return {
    path,
  };
};

module.exports = {
  relatorioAgenda,
};
