const conection = require("../../config/database"); // ATENCÃO A ESTE PATH!!!
const moment = require("moment");
const materialAgenda = require("../material_agenda/material_agenda_methods");
const {
  createCompraInterna,
  readComprasByAgendaAndData,
  excludeCompraWithoutAgenda,
  deleteRelationAgendaCompra,
  readCompraById,
  readComprasByAgenda,
  baixarManual,
} = require("../compra/compra_resources");
const { dateAndHourToMoment } = require("../../utils/utils");
const {
  readByDay,
  insertExclusaoAgenda,
  readAgendasByCompra,
  removeAgenda,
  getDataNextInstance,
  readForTable,
} = require("./agenda_resources");

//Lê as agendas por dia
const readAgendaById = async (id_agenda) => {
  return await new Promise((resolve, reject) => {
    conection.query(
      "SELECT * FROM l_agenda WHERE id_agenda = ?",
      [id_agenda],
      (error, results) => {
        if (error) {
          reject(error);
        } else {
          try {
            resolve(results[0]);
          } catch (error) {
            reject(error);
          }
        }
      }
    );
  });
};

//Insere um material na agenda
const insertMaterial = async (id_agenda, material) => {
  await new Promise((resolve, reject) => {
    conection.query(
      "INSERT INTO l_material_agenda(id_agenda, id_material, quantidade) VALUES (?, ?, ?)",
      [id_agenda, material.id_material, material.quantidade],
      (error, results2) => {
        if (error) {
          console.error("Erro! Material não registrado!");
          console.error(error);
          reject(error);
        } else {
          resolve(results2);
        }
      }
    );
  });
};

//Insere uma agenda no banco
const insertAgenda = async (id_usuario, tipo_usuario, agenda) => {
  return await new Promise((resolve, reject) => {
    conection.query(
      "INSERT INTO l_agenda(id_espaco, id_usuario, tipo_usuario, data_agenda, horario, horario_final, valor, observacao, id_modalidade_espaco, nome_responsavel, repeticao, data_fim, id_forma_pagamento, id_condicao_pagamento) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);",
      [
        agenda.id_espaco,
        id_usuario,
        tipo_usuario,
        agenda.data,
        agenda.inicio,
        agenda.final,
        agenda.valor,
        agenda.observacao,
        agenda.id_modalidade_espaco,
        agenda.nome_responsavel,
        agenda.repeticao ? 1 : 0,
        agenda.data_fim,
        agenda.id_forma_pagamento,
        agenda.id_condicao_pagamento
      ],
      async (error, results) => {
        if (error) reject(error);
        else resolve(results.insertId);
      }
    );
  });
};

//Cria uma agenda
const createAgenda = async (id_usuario, tipo_usuario, agenda) => {
  console.log('chegou no create agenda no agenda_methods')
  console.log(id_usuario)
  console.log(tipo_usuario)
  console.log('agenda e seus materiais')
  console.log(agenda)
  const id_agenda = await insertAgenda(id_usuario, tipo_usuario, agenda);
  
  if (agenda.material_list) {
    for (let i = 0; i < agenda.material_list.length; i++) {
      const material = agenda.material_list[i];
      await insertMaterial(id_agenda, material);
    }
  }
  return { id_agenda };
};

//Cria uma agenda interna (gerando pagamento)
const createAgendaInterna = async (id_usuario, tipo_usuario, agenda) => {
  const { id_agenda } = await createAgenda(id_usuario, tipo_usuario, agenda);
  var data_agenda_compra;
  if (agenda.repeticao) data_agenda_compra = agenda.data;
  await createCompraInterna(
    id_agenda,
    id_usuario,
    tipo_usuario,
    agenda.valor,
    data_agenda_compra,
    agenda.nome_responsavel
  );
  return { id_agenda };
};

//Lê todas as agendas
const read = async () => {
  return await new Promise((resolve, reject) => {
    conection.query("SELECT * FROM l_agenda", (error, results) => {
      if (error) {
        reject(error);
      } else {
        resolve(results);
      }
    });
  });
};


const selectByUsuario = async (id_usuario, tipo_usuario) => {
  return await new Promise((resolve, reject) => {
    conection.query(
      `SELECT 
        a.*, 
        fp.descricao AS descricao_forma_pagamento,
        cp.descricao AS descricao_condicao_pagamento,
        e.*, 
        c.*
      FROM l_agenda AS a
      INNER JOIN l_forma_pagamento AS fp ON a.id_forma_pagamento = fp.id_forma_pagamento
      INNER JOIN l_condicao_pagamento AS cp ON a.id_condicao_pagamento = cp.id_condicao_pagamento
      INNER JOIN l_espaco AS e ON e.id_espaco = a.id_espaco
      INNER JOIN cliente AS c ON e.id_cliente = c.id_cliente
      WHERE a.id_usuario = ? AND a.tipo_usuario = ?
      ORDER BY data_agenda, horario;`,
      [id_usuario, tipo_usuario],
      (error, results) => {
        if (error) {
          reject(error);
        } else {
          resolve(results);
        }
      }
    );
  });
};


//Checa se horário é do passado
const isAgendaPassada = (agenda) => {
  const dataHora = dateAndHourToMoment(agenda.data_agenda, agenda.horario);
  return dataHora < moment();
};

//Filtra as agendas passadas
const filterAgendasPassadas = (agendaList) => {
  return agendaList.filter((agenda) => !isAgendaPassada(agenda));
};

//Lê as agendas por usuário
const readByUsuario = async (id_usuario, tipo_usuario) => {
  const agendaList = await selectByUsuario(id_usuario, tipo_usuario);
  console.log('teste agenda list');
  console.log(agendaList)
  return agendaList;//filterAgendasPassadas(agendaList);
};

//Lê os materiais de uma agenda
const readMateriais = async (id_agenda) => {
  const results = await new Promise(async (resolve, reject) => {
    await materialAgenda.deleteByAgenda(id_agenda);
    conection.query(
      "DELETE FROM l_agenda WHERE id_agenda = ?",
      [id_agenda],
      (error, results) => {
        if (error) {
          reject(error);
        } else {
          resolve(results);
        }
      }
    );
  });
  return results;
};

//Método para ler a agenda por id da compra
const readByCompraMethod = async (id_compra) => {
  const [compra] = await readCompraById(id_compra);
  return await readAgendasByCompra(compra);
};

//Cria a nova compra para a próxima instância de uma agenda recorrente
const criarNovaCompraRecorrencia = async (id_agenda, data) => {
  const agenda = await readAgendaById(id_agenda);
  const dataFim = dateAndHourToMoment(agenda.data_fim).startOf("day");
  const nextData = await getDataNextInstance(agenda, data);
  //Se próxima instância é antes do fim da recorrência, cria a compra
  if (nextData <= dataFim) {
    await createCompraInterna(
      id_agenda,
      agenda.id_usuario,
      agenda.tipo_usuario,
      agenda.valor,
      nextData.format("YYYY-MM-DD"),
      agenda.nome_responsavel
    );
  }
};

//Deleta a compra de uma agenda, sem deletar a agenda
const deleteCompraAgenda = async (id_compra) => {
  //Desvincula as agendas da compra
  const agendaList = await readByCompraMethod(id_compra);
  for (var i = 0; i < agendaList.length; i++)
    await deleteRelationAgendaCompra(id_compra, agendaList[i].id_agenda);
  await excludeCompraWithoutAgenda(id_compra);
};

//Deleta uma única instância de um agendamento recorrente
const deleteRepeticaoOne = async (id_agenda, dia) => {
  const [compra] = await readComprasByAgendaAndData(id_agenda, dia);
  if (compra) {
    await deleteCompraAgenda(compra.id_compra);
    //Cria a nova compra para a próxima instância (se houver)
    await criarNovaCompraRecorrencia(id_agenda, dia);
  }
  //Insere a exclusão do dia na tabela l_exclusao_agenda
  await insertExclusaoAgenda(id_agenda, dia);
};

//Atualiza a data_fim de uma agenda recorrente
const updateDataFim = async (id_agenda, data_fim) => {
  return await new Promise((resolve, reject) => {
    conection.query(
      "UPDATE l_agenda SET data_fim = ? WHERE id_agenda = ?",
      [data_fim, id_agenda],
      (error, results) => {
        if (error) reject(error);
        else resolve(results);
      }
    );
  });
};

//Deleta todas as instâncias futuras de agendamentos com repetição, sem se preocupar com as compras (pois já foram tratadas)
const deleteInstanciasFuturas = async (id_agenda) => {
  const agenda = await readAgendaById(id_agenda);
  const data_agenda = dateAndHourToMoment(agenda.data_agenda, agenda.horario);
  const now = moment();
  const yesterday = moment(now).subtract(1, "days");
  //Se não tem agendamento no dia de hoje, atualiza a data_fim da agenda para hoje
  if (data_agenda.day() != now.day())
    await updateDataFim(id_agenda, now.format("YYYY-MM-DD"));
  else {
    //Verifica se horário não passou ainda
    if (
      now.hours() < data_agenda.hours() ||
      (now.hours() == data_agenda.hours() &&
        now.minutes() < data_agenda.minutes())
    ) {
      //Se for antes da primeira agenda, deleta a agenda toda
      if (now.startOf("day") <= data_agenda.startOf("day"))
        await removeAgenda(id_agenda);
      //Senão, joga data_fim pra ontem
      else await updateDataFim(id_agenda, yesterday.format("YYYY-MM-DD"));
    } else {
      //Se já passou, define data_fim para hoje
      await updateDataFim(id_agenda, now.format("YYYY-MM-DD"));
    }
  }
};

//Filtra apenas as compras futuras de uma agenda
const filterComprasFuturas = async (id_agenda, compraList) => {
  const agenda = await readAgendaById(id_agenda);
  return compraList.filter((compra) => {
    const data_agenda = dateAndHourToMoment(compra.data_agenda, agenda.horario);
    return data_agenda > moment();
  });
};

//Deleta todas as compras futuras de uma agenda (não pagas)
const deleteComprasFuturas = async (id_agenda) => {
  var compraList = await readComprasByAgenda(id_agenda);
  compraList = await filterComprasFuturas(id_agenda, compraList);
  for (var i = 0; i < compraList.length; i++)
    await deleteCompraAgenda(compraList[i].id_compra);
};

//Deleta todas as instâncias futuras de agendamentos com repetição e suas compras
const deleteRepeticaoAll = async (id_agenda) => {
  await deleteComprasFuturas(id_agenda);
  await deleteInstanciasFuturas(id_agenda);
};

//Realiza a baixa de uma agenda recorrente
const baixaRepeticao = async (dadosBaixa) => {
  //Lê a compra da agenda
  const [compra] = await readComprasByAgendaAndData(
    dadosBaixa.id_agenda,
    dadosBaixa.dia
  );
  var id_compra;
  //Se tem compra, pega o id
  if (compra) id_compra = compra.id_compra;
  //Se não tem compra, cria uma nova
  if (!compra) {
    const agenda = await readAgendaById(dadosBaixa.id_agenda);
    id_compra = await createCompraInterna(
      dadosBaixa.id_agenda,
      dadosBaixa.id_usuario_baixa,
      "o",
      dadosBaixa.valor_pago,
      dadosBaixa.dia,
      agenda.nome_responsavel
    );
  }
  //Atribui o id da compra aos dados de baixa
  dadosBaixa.id_compra = id_compra;
  //Faz a baixa da compra
  await baixarManual(dadosBaixa);
};

//Lê as agendas para a tabela de agendamentos
const readAgendaForTable = async (id_espaco, day) => {
  const agendaList = await readForTable(id_espaco, day);
  for (var i = 0; i < agendaList.length; i++) {
    const [compra] = await readComprasByAgendaAndData(
      agendaList[i].id_agenda,
      day
    );
    if (compra) agendaList[i].situacao = compra.situacao;
    else agendaList[i].situacao = "ng";
  }
  return agendaList;
};

//Edita uma agenda
const editAgenda = (id_agenda, nome_responsavel, observacao) => {
  return new Promise((resolve, reject) => {
    conection.query(
      "UPDATE l_agenda SET nome_responsavel = ?, observacao = ? WHERE id_agenda = ?",
      [nome_responsavel, observacao, id_agenda],
      (error, results) => {
        if (error) reject(error);
        else resolve(results);
      }
    );
  });
};


module.exports = {
  read,
  readForTable: readAgendaForTable,
  readByUsuario,
  readMateriais,
  readAgendaById,
  createAgenda,
  readByDay,
  readByCompraMethod,
  deleteRepeticaoAll,
  deleteRepeticaoOne,
  createAgendaInterna,
  baixaRepeticao,
  editAgenda,
  
};
