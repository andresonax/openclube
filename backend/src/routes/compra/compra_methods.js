const connection = require("../../config/database");
const usuarioMethods = require("../usuario_app/usuario_app_methods");
const pixMethods = require("../financeiro/pix/pix");
const configsMethods = require("../configs/configs_methods");
const agendaMethods = require("../agenda/agenda_methods.js");
const carrinhoMethods = require("../carrinho/carrinho_methods.js");
const {
  relateAgendaCompra,
  createReceita,
  insertCompra,
  deleteRelationAgendaCompra,
  updateCompraPix,
  readComprasByAgendaAndData,
  readCompraById,
  baixarManual,
  createCompraInterna,
  excludeCompraWithoutAgenda,
} = require("./compra_resources.js");
const {
  insertExclusaoAgenda,
  getDataNextInstance,
  readAgendasByCompra,
  removeAgenda,
  readForTable,
} = require("../agenda/agenda_resources.js");
const {
  isHorarioPassado,
  isHorarioReservado,
} = require("../horario/horario_resources.js");
const { dateAndHourToMoment } = require("../../utils/utils.js");

//Cria os agendamentos da compra
const createAgendamentos = async (
  id_usuario,
  tipo_usuario,
  id_compra,
  horarioList,
  nome_responsavel
) => {


  for (var i = 0; i < horarioList.length; i++) {
    horarioList[i].nome_responsavel = nome_responsavel;
    const { id_agenda } = await agendaMethods.createAgenda(
      id_usuario,
      tipo_usuario,
      horarioList[i]
    );
    await relateAgendaCompra(id_compra, id_agenda);
  }
};

//Cria o pagamento da compra
const createPagamento = async (
  id_compra,
  id_usuario,
  valor,
  tipo_pagamento,
  id_cliente
) => {

  //Lê as configurações
  const configs = await configsMethods.readConfigs();
  //Aplica ao pagamento somente o valor adiantado obrigatório

  //verificar se isso é necessário depois
  //valor_pagamento = (valor / 100) * configs.valor_obrigatorio_reserva;


  //Retorno, diferente para cada tipo de pagamento gerado
  var documento;
  //Se for pix
  if (tipo_pagamento == 1) {
    const dadosPix = await gerarPix(id_compra, valor, id_cliente);
    //const dadosPix = await gerarPix(id_compra, valor_pagamento);
    documento = dadosPix.txid;
  }else if(tipo_pagamento == 2) {
    const dadosPix = await gerarPix(id_compra, valor/2, id_cliente);
    //const dadosPix = await gerarPix(id_compra, valor_pagamento);
    documento = dadosPix.txid;
  }
  //Cria a receita
  await createReceita(id_compra, id_usuario, valor, documento);
};

//Checa se horário está no passado/indisponível devido ao período de antecedência requerido para reserva
const checkIsHorarioPassado = async (horario) => {
  //Lê as configurações de locação
  const configs = await configsMethods.readConfigs();
  return isHorarioPassado(horario, configs);
};

//Checa se horário está reservado
const checkIsHorarioReservado = async (horario) => {

  const agendaList = await readForTable(horario.id_espaco, horario.data);
  //Se horário estiver comprado, deleta do carrinho
  return isHorarioReservado(horario, agendaList);
};

//Valida os horários do antes de realizar a compra
const validaHorarios = async (horarioList) => {

  console.log("Validando horários da agenda...");
  console.log(horarioList);

  var invalidos = false;
  for (var i = 0; i < horarioList.length; i++) {
    const horario = horarioList[i];
    horario.data = new Date(horario.data.substring(0, 10));
    if (await checkIsHorarioPassado(horario)) {
      invalidos = true;
      //await carrinhoMethods.removeHorario(horario.id_horario_carrinho);
    } else if (await checkIsHorarioReservado(horario)) {
      invalidos = true;
      //await carrinhoMethods.removeHorario(horario.id_horario_carrinho);
    }
  }
  if (invalidos)
    throw {
      msg: "Um ou mais horários inválidos. Tente novamente!",
    };
};

//Cria a compra
const createCompra = async (
  id_usuario,
  tipo_usuario,
  tipo_pagamento,
  valor_total,
  horarioList,
  id_cliente
) => {
  var id_compra;
  try {
    //Valida se não há nenhum horário inválido no carrinho
    await validaHorarios(horarioList);
    const usuario = await usuarioMethods.getDadosUsuario(
      id_usuario,
      tipo_usuario
    );
    id_compra = await insertCompra(
      id_usuario,
      tipo_usuario,
      tipo_pagamento,
      valor_total,
      null,
      usuario.nome,
    );
    await createPagamento(id_compra, id_usuario, valor_total, tipo_pagamento, id_cliente);
    await createAgendamentos(
      id_usuario,
      tipo_usuario,
      id_compra,
      horarioList,
      usuario.nome
    );
    return { id_compra };
  } catch (error) {
    //Se der erro no meio do processo, exclui o que foi criado
    if (id_compra) await excludeCompra(id_compra);
    throw error;
  }
};

//Faz select de compras em um período
const selectComprasInPeriod = async (dataInicial, dataFinal) => {
  return await new Promise((resolve, reject) => {
    connection.query(
      "SELECT c.* FROM l_compra c WHERE c.data_hora_compra >= ? AND c.data_hora_compra <= ?;",
      [dataInicial, dataFinal],
      (error, results) => {
        if (error) reject(error);
        else resolve(results);
      }
    );
  });
};

//Lê compras em um período
const readComprasInPeriod = async (dataInicial, dataFinal) => {
  const compraList = await selectComprasInPeriod(dataInicial, dataFinal);
  for (var i = 0; i < compraList.length; i++) {
    const dadosUsuario = await usuarioMethods.getDadosUsuario(
      compraList[i].id_usuario,
      compraList[i].tipo_usuario
    );
    compraList[i].nome_usuario = dadosUsuario.nome;
  }
  return compraList;
};

//Lê compras por usuário
const readComprasByUsuario = async (id_usuario, tipo_usuario) => {
  return await new Promise((resolve, reject) => {
    connection.query(
      "SELECT * FROM l_compra WHERE id_usuario = ? AND tipo_usuario = ? ORDER BY data_hora_compra;",
      [id_usuario, tipo_usuario],
      (error, results) => {
        if (error) reject(error);
        else resolve(results);
      }
    );
  });
};

//Deleta todos os agendamentos de uma compra
const deleteAgendas = async (agendaList) => {
  for (var i = 0; i < agendaList.length; i++) {
    //Exclui a agenda
    await removeAgenda(agendaList[i].id_agenda);
  }
};

//Exclui compra sem agendamento recorrente
const excludeCompraNoRecorrente = async (id_compra) => {
  //Lê a compra
  const [compra] = await readCompraById(id_compra);
  //Lê a lista de agendas
  const agendaList = await readAgendasByCompra(compra);
  //Exclui financeiro, compra e relações com agenda
  await excludeCompraWithoutAgenda(id_compra);
  //Exclui agendamentos
  await deleteAgendas(agendaList);
};

//Cria uma nova compra para a próxima instância de um agendamento recorrente
const criarNovaCompraRecorrencia = async (agenda, dataBase) => {
  const dataFim = dateAndHourToMoment(agenda.data_fim).startOf("day");
  const nextData = await getDataNextInstance(agenda, dataBase);
  //Se próxima instância é antes do fim da recorrência, cria a compra
  if (nextData <= dataFim) {
    await createCompraInterna(
      agenda.id_agenda,
      agenda.id_usuario,
      agenda.tipo_usuario,
      agenda.valor,
      nextData.format("YYYY-MM-DD"),
      agenda.nome_responsavel
    );
  }
};

//Exclui compra de agendamento recorrente
const excludeCompraRecorrente = async (id_compra) => {
  //Lê a compra
  const [compra] = await readCompraById(id_compra);
  //Carrega a lista de agendamentos
  const agendaList = await readAgendasByCompra(compra);
  for (var i = 0; i < agendaList.length; i++) {
    //Exclui a relação entre a compra e o agendamento
    await deleteRelationAgendaCompra(id_compra, agendaList[i].id_agenda);
    const data_agenda = dateAndHourToMoment(compra.data_agenda);
    //Insere a exclusão da instância do agendamento
    await insertExclusaoAgenda(
      agendaList[i].id_agenda,
      data_agenda.format("YYYY-MM-DD")
    );
    //Cria uma nova compra para a próxima instância do agendamento
    await criarNovaCompraRecorrencia(agendaList[i], data_agenda);
  }
  //Exclui a compra sem excluir a agenda
  await excludeCompraWithoutAgenda(id_compra);
};

//Exclui compra completamente
const excludeCompra = async (id_compra) => {
  const [compra] = await readCompraById(id_compra);
  //Se a compra for de um agendamento recorrente, exclui somente a instância atual
  if (compra.data_agenda) await excludeCompraRecorrente(id_compra);
  else await excludeCompraNoRecorrente(id_compra);
};

//Gera um pix
const gerarPix = async (id_compra, valor_pagamento, id_cliente) => {
  const [compra] = await readCompraById(id_compra);
  const dadosUsuario = await usuarioMethods.getDadosUsuario(
    compra.id_usuario,
    compra.tipo_usuario
  );

  const configs = await configsMethods.readConfigs();

  const dadosPix = await pixMethods.gerarPix(id_cliente, {
    cpf: dadosUsuario.cpf,
    nome: dadosUsuario.nome,
    valor: valor_pagamento,
    solicitacaoPagador: "Cobrança da locação de espaço.",
    tipo_pix: 1,
    expiracao_minutos: configs.expiracao_minutos_pix,
  });
  await updateCompraPix(id_compra, dadosPix.id_pix, "ge", 1);
  return dadosPix;
};

//Visualiza o pix
const visualizarPix = async (id_compra) => {
  try {
    const [compra] = await readCompraById(id_compra);
    return await pixMethods.visualizarPix(compra.id_pix);
  } catch (error) {
    if (error.expirado) {
      await excludeCompra(id_compra);
    }
    throw error;
  }
};

//Processa os Pix que estão expirados
const processPixExpirado = async (compraPix) => {
  try {
    //Se for pago parcial sai
    if (compraPix.situacao == "pp") return;
    //Se for pago sai
    if (compraPix.situacao == "pa") return;
    console.log("PIX " + compraPix.id_pix + " EXPIRADO!");
    await excludeCompra(compraPix.id_compra);
  } catch (error) {
    console.error(error);
    console.error("Erro ao processar pix expirado: " + compraPix.id_pix);
  }
};

//Obtém todos os pix associados a compras
const getAllCompraPix = async () => {
  return await new Promise((resolve, reject) => {
    connection.query(
      "SELECT * FROM pix p INNER JOIN l_compra c ON c.id_pix = p.id_pix",
      (error, results) => {
        if (error) reject(error);
        else resolve(results);
      }
    );
  });
};

//Deleta todos os pix de compra expirados (e suas compras)
const deleteAllPixExpirados = async () => {
  const compraPixList = await getAllCompraPix();
  for (var i = 0; i < compraPixList.length; i++)
    if (pixMethods.checkPixExpirado(compraPixList[i]))
      await processPixExpirado(compraPixList[i]);
};

//Gera pix manualmente
const gerarPixManual = async (id_compra) => {
  const [compra] = await readCompraById(id_compra);
  const configs = await configsMethods.readConfigs();
  const valor = (compra.valor_total / 100) * configs.valor_obrigatorio_reserva;
  return await gerarPix(id_compra, valor);
};

//Verifica se a compra tem mais de um agendamento
const isCompraMultipla = async (id_compra) => {
  return await new Promise((resolve, reject) => {
    connection.query(
      "SELECT * FROM l_agenda_compra WHERE id_compra = ?",
      [id_compra],
      (error, results) => {
        if (error) reject(error);
        else {
          resolve({
            isMultipla: results.length > 1,
          });
        }
      }
    );
  });
};

//Faz a baixa da compra
const baixaCompra = async (dadosBaixa) => {
  await baixarManual(dadosBaixa);
  const [compra] = await readCompraById(dadosBaixa.id_compra);
  if (compra.data_agenda) {
    const [agenda] = await readAgendasByCompra(compra);
    await criarNovaCompraRecorrencia(agenda, compra.data_agenda);
  }
};

const idCompraPorIdAgenda = async (id_agenda) => {
  return await new Promise((resolve, reject) => {
    connection.query(
      "SELECT c.* FROM l_compra as c INNER JOIN l_agenda_compra as ac ON c.id_compra = ac.id_compra INNER join l_agenda as a ON ac.id_agenda = a.id_agenda WHERE a.id_agenda = ?",
      [id_agenda],
      (error, results) => {
        if (error) reject(error);
        else resolve(results[0]);
      }
    );
  });
}

const comprasData = async (id_compra) => {
  return await new Promise((resolve, reject) => {
    connection.query(
      "SELECT * FROM l_compra WHERE id_compra = ?",
      [id_compra],
      (error, results) => {
        if (error) reject(error);
        else resolve(results);
      }
    );
  });
};

module.exports = {
  createCompra,
  readComprasInPeriod,
  gerarPix,
  visualizarPix,
  deleteAllPixExpirados,
  excludeCompra,
  readComprasByUsuario,
  readComprasByAgendaAndData,
  gerarPixManual,
  isCompraMultipla,
  baixaCompra,
  idCompraPorIdAgenda,
  comprasData
};
