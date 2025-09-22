const puppeteer = require('puppeteer');
const fs = require('fs');

const { moment } = require("../../utils/moment_local");
const { uploadsPath } = require("../../config/globals");
const { getHeader } = require("../relatorio/relatorio_utils");
const { readCompraById } = require("./compra_resources");
const { readAgendasByCompra } = require("../agenda/agenda_resources");
const { readById } = require("../espaco/espaco_resources");
const {
  readModalidadeById,
} = require("../modalidade_espaco/modalidade_espaco_resources");
const { dataHoraToMoment } = require("../../utils/utils");

//Style (css) do comprovante
const style = `
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

    p,
    b,
    h1,
    h2 {
      display: inline-block;
      margin: 0;
    }

    p,
    b,
    h1,
    h2,
    td,
    th {
      font-family: "Poppins", sans-serif;
    }

    p,
    b {
      font-size: 16px;
    }

    .content {
      width: 100%;
      display: flex;
      display: -webkit-flex;
      flex-direction: column;
      -webkit-flex-direction: column;
      margin: 15px 20px;
    }

    .content div {
      margin-bottom: 10px;
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
      -ms-flex-wrap: wrap;
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

    .comprovante {
      width: 100%;
      display: flex;
      display: -webkit-flex;
      flex-direction: column;
      -webkit-flex-direction: column;
      -ms-flex-direction: column;
      gap: 20px;
      -webkit-row-gap: 20px;
      -ms-row-gap: 20px;
    }

    .titulo {
      font-size: 12px;
    }

    .dados_compra {
      width: 100%;
      display: flex;
      display: -webkit-flex;
      flex-direction: column;
      -webkit-flex-direction: column;
    }

    .row_dados {
      display: flex;
      display: -webkit-flex;
      flex-direction: row;
      -webkit-flex-direction: row;
    }

    .row_dados span {
      flex: 1;
      -webkit-flex: 1;
    }

    .dados_agenda h2 {
      font-size: 18px;
    }

    .agenda {
      page-break-inside: avoid !important;
    }

    .agenda div {
      display: flex;
      display: -webkit-flex;
      flex-direction: row;
      -webkit-flex-direction: row;
      flex-wrap: wrap;
      -webkit-flex-wrap: wrap;
      -ms-flex-wrap: wrap;
      page-break-inside: avoid !important;
    }

    .agenda div span {
      margin-right: 10px;
      page-break-inside: avoid !important;
    }
  </style>
`;

//Obtém o HTML de uma agenda
const getAgendaHtml = (data, inicio, fim, espaco, modalidade) => {
  return `
    <li class="agenda">
      <div>
        <span class="data_agenda">
          <p class="label">Data: </p>
          <p class="value">${data}</p>
        </span>
        <span class="separator">|</span>
        <span class="data_agenda">
          <p class="label">Início: </p>
          <p class="value">${inicio}</p>
        </span>
        <span class="separator">|</span>
        <span class="data_agenda">
          <p class="label">Fim: </p>
          <p class="value">${fim}</p>
        </span>
        <span class="separator">|</span>
        <span class="espaco">
          <p class="label">Espaço: </p>
          <p class="value">${espaco}</p>
        </span>
        <span class="separator">|</span>
        <span class="modalidade">
          <p class="label">Modalidade: </p>
          <p class="value">${modalidade}</p>
        </span>
      </div>
    </li>
  `;
};

//Obtém os dados de uma agenda
const getAgenda = async (agenda) => {
  var data = moment.utc(agenda.data_agenda, "YYYY-MM-DD").format("DD/MM/YYYY");
  var inicio = moment(agenda.horario, "HH:mm").format("HH:mm");
  var fim = moment(agenda.horario_final, "HH:mm").format("HH:mm");
  var nomeEspaco = "-";
  const [espaco] = await readById(agenda.id_espaco);
  if (espaco) nomeEspaco = espaco.nome;
  var nomeModalidade = "-";
  const [modalidade] = await readModalidadeById(agenda.id_modalidade_espaco);
  if (modalidade) nomeModalidade = modalidade.nome_modalidade;
  return getAgendaHtml(data, inicio, fim, nomeEspaco, nomeModalidade);
};

//Obtém os dados dos agendamentos
const getDadosAgenda = async (id_compra) => {
  const [compra] = await readCompraById(id_compra);
  const agendaList = await readAgendasByCompra(compra);
  var HTML = `
    <div class="dados_agenda">
      <h2>Agendamentos: </h2>
      <ul class="lista_agenda">
  `;
  for (let agenda of agendaList) {
    const agendaHTML = await getAgenda(agenda);
    HTML += agendaHTML;
  }
  HTML += `
      </ul>
    </div>
  `;
  return HTML;
};

//Obtém o HTML dos dados da compra
const getHTMLCompra = (responsavel, data_hora_pagamento, valor, valor_pago) => {
  return `
    <div class="dados_compra">
      <div class="row_dados">
        <span class="responsavel">
          <h3>Responsável: </h3>
          <p>${responsavel}</p>
        </span>
        <span class="dia_pagamento">
          <h3>Data-Hora Pagamento: </h3>
          <p>${data_hora_pagamento}</p>
        </span>
      </div>
      <div class="row_dados">
        <span class="valor">
          <h3>Valor: </h3>
          <p>R$${valor}</p>
        </span>
        <span class="valor_pago">
          <h3>Valor Pago: </h3>
          <p>R$${valor_pago}</p>
        </span>
      </div>
    </div>
  `;
};

//Obtém os dados da compra
const getDadosCompra = async (id_compra) => {
  const [compra] = await readCompraById(id_compra);
  var responsavel = "-";
  if (compra.nome_responsavel) responsavel = compra.nome_responsavel;
  var valor = Number(compra.valor_total || 0).toFixed(2);
  var valorPago = "-";
  if (compra.valor_pago) valorPago = compra.valor_pago;
  var dataHoraPagamento = "-";
  if (compra.data_hora_pagamento)
    var dataHoraPagamento = dataHoraToMoment(compra.data_hora_pagamento).format(
      "DD/MM/YYYY HH:mm"
    );
  return getHTMLCompra(responsavel, dataHoraPagamento, valor, valorPago);
};

//Obtém o HTML do comprovante de compra
const getHtmlComprovante = async (id_compra, id_cliente) => {
  const header = await getHeader(id_cliente);
  const dadosCompra = await getDadosCompra(id_compra);
  const dadosAgenda = await getDadosAgenda(id_compra);
  return `
    <!DOCTYPE html>
    <html lang="en">
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>Comprovante</title>
      ${style}
    </head>
    <body>
      <div class="content">
        ${header}
        <div class="comprovante">
          <div class="titulo">
            <h1>Comprovante de Compra</h1>
          </div>
          ${dadosCompra}
          ${dadosAgenda}
        </div>
      </div>
    </body>
    </html>
  `;
};

//Obtém o caminho para o arquivo do comprovante de compra
const getFilePath = (id_compra) => {
  return `./${uploadsPath}/comprovante_compra_${id_compra}.pdf`;
};

const generatePdf = async (outputPath, html) => {
  const browser = await puppeteer.launch();
  const page = await browser.newPage();
  await page.setContent(html);
  await page.pdf({ path: outputPath, format: 'A4' });
  await browser.close();
};

//Gera o comprovante da compra
const geraComprovante = async (id_compra, id_cliente) => {
  console.log('Gerando comprovante para compra no compra_comprovante:', id_compra, 'e cliente:', id_cliente);
  const html = await getHtmlComprovante(id_compra, id_cliente);
  const path = getFilePath(id_compra);
  await generatePdf(path, html);
  return {
    path,
  };
};

module.exports = {
  geraComprovante,
  
};
