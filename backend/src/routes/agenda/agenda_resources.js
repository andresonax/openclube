const conection = require("../../config/database"); // ATENCÃO A ESTE PATH!!!
const { dateAndHourToMoment } = require("../../utils/utils");
const materialAgenda = require("../material_agenda/material_agenda_methods");
const moment = require("moment");

//Lê as agendas por dia
//Faz tratamentos para reconhecer agendamentos repetidos
const selectByDay = async (day) => {
  day = moment(day).format("YYYY-MM-DD");
  return await new Promise((resolve, reject) => {
    conection.query(
      "SELECT a.*, ac.id_compra, c.data_agenda 'data_compra', es.nome 'nome_espaco', m.nome_modalidade FROM l_agenda a LEFT JOIN l_espaco es ON es.id_espaco = a.id_espaco LEFT JOIN l_modalidade_espaco m ON m.id_modalidade_espaco = a.id_modalidade_espaco LEFT JOIN l_agenda_compra ac ON ac.id_agenda = a.id_agenda LEFT JOIN l_compra c ON c.id_compra = ac.id_compra AND c.data_agenda = ? LEFT JOIN l_exclusao_agenda e ON e.id_agenda = a.id_agenda AND dia_exclusao = ? WHERE ISNULL(dia_exclusao) AND (ISNULL(c.data_agenda) OR c.data_agenda = ?) AND ( (NOT repeticao AND a.data_agenda =  ?) OR (repeticao = 1 AND a.data_agenda <=  ? AND a.data_fim >=  ? AND WEEKDAY( ?) = WEEKDAY(a.data_agenda)) ) GROUP BY a.id_agenda ORDER BY a.horario;",
      [day, day, day, day, day, day, day],
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

//Retorna o sql e os valores para a leitura de agendas por espaço e dia, para tabela de agendas
const getSqlReadForTable = (id_espaco, day) => {
  var sql =
    "SELECT a.*, ac.id_compra, c.data_agenda 'data_compra' FROM l_agenda a LEFT JOIN l_agenda_compra ac ON ac.id_agenda = a.id_agenda LEFT JOIN l_compra c ON c.id_compra = ac.id_compra AND c.data_agenda = ? LEFT JOIN l_exclusao_agenda e ON e.id_agenda = a.id_agenda AND dia_exclusao = ? WHERE ISNULL(dia_exclusao) AND (ISNULL(c.data_agenda) OR c.data_agenda = ?) AND ( (NOT repeticao AND a.data_agenda =  ?) OR (repeticao = 1 AND a.data_agenda <=  ? AND a.data_fim >=  ? AND WEEKDAY( ?) = WEEKDAY(a.data_agenda)) )";
  var values = [day, day, day, day, day, day, day];
  if (id_espaco != -1) {
    sql += " AND id_espaco = ?";
    values.push(id_espaco);
  }
  sql += " GROUP BY a.id_agenda;";
  return { sql, values };
};

//Seleciona agendas por espaço e dia, para tabela de agendas. Faz tratamentos para reconhecer agendamentos repetidos
const selectForTable = async (id_espaco, day) => {
  return await new Promise((resolve, reject) => {
    const { sql, values } = getSqlReadForTable(id_espaco, day);
    conection.query(sql, values, (error, results) => {
      if (error) {
        reject(error);
      } else {
        resolve(results);
      }
    });
  });
};

//Lê agendas por espaço e dia, para tabela de agendas
const readForTable = async (id_espaco, day) => {
  const agendaList = await selectForTable(id_espaco, day);
  for (var i = 0; i < agendaList.length; i++) {
    agendaList[i].data_agenda = moment(day).format("YYYY-MM-DD");
  }
  return agendaList;
};

//Lê as agendas por dia
const readByDay = async (day) => {
  const agendaList = await selectByDay(day);
  for (var i = 0; i < agendaList.length; i++)
    agendaList[i].data_agenda = moment(day).format("YYYY-MM-DD");
  return agendaList;
};

//Insere a exclusão de uma única instância de uma agenda recorrente na tabela l_exclusao_agenda
const insertExclusaoAgenda = async (id_agenda, dia) => {
  return await new Promise((resolve, reject) => {
    conection.query(
      "INSERT INTO l_exclusao_agenda (id_agenda, dia_exclusao) VALUES(?, ?);",
      [id_agenda, dia],
      (error, results) => {
        if (error) reject(error);
        else resolve(results);
      }
    );
  });
};

//Checa a exclusão de uma agenda recorrente em certo dia
const checkExclusaoDia = async (id_agenda, dia) => {
  return await new Promise((resolve, reject) => {
    conection.query(
      "SELECT * FROM l_exclusao_agenda WHERE id_agenda = ? AND dia_exclusao = ?;",
      [id_agenda, dia],
      (error, results) => {
        if (error) reject(error);
        else {
          resolve(results.length > 0);
        }
      }
    );
  });
};

//Verifica se uma agenda possui compra no dia (em uma única instância)
const temCompraNoDia = async (id_agenda, dia) => {
  return await new Promise((resolve, reject) => {
    conection.query(
      "SELECT * FROM l_compra c INNER JOIN l_agenda_compra ac ON ac.id_compra = c.id_compra WHERE id_agenda = ? AND data_agenda = ?;",
      [id_agenda, dia],
      (error, results) => {
        if (error) reject(error);
        else {
          resolve(results.length > 0);
        }
      }
    );
  });
};

//Obtém a data da próxima instância de uma agenda recorrente
const getDataNextInstance = async (agenda, dataBase) => {
  var excluida = false;
  var temCompra;
  var data = moment(dataBase).startOf("day");
  const dataFim = dateAndHourToMoment(agenda.data_fim).startOf("day");
  do {
    data.add(7, "days");
    //Checa se a data está excluída
    excluida = await checkExclusaoDia(
      agenda.id_agenda,
      data.format("YYYY-MM-DD")
    );
    //Checa se já existe compra no dia
    temCompra = await temCompraNoDia(
      agenda.id_agenda,
      data.format("YYYY-MM-DD")
    );
  } while (data <= dataFim && (excluida || temCompra));
  return data;
};

//Lê as agendas por compra
const selectByCompra = async (id_compra) => {
  return await new Promise((resolve, reject) => {
    conection.query(
      "SELECT a.* FROM l_agenda a INNER JOIN l_agenda_compra ac ON ac.id_agenda = a.id_agenda WHERE id_compra = ?",
      [id_compra],
      (error, results) => {
        if (error) reject(error);
        else resolve(results);
      }
    );
  });
};

//Lê as agendas por compra, corrigindo a data se for agendamento recorrente
const readAgendasByCompra = async (compra) => {
  const agendaList = await selectByCompra(compra.id_compra);
  for (var i = 0; i < agendaList.length; i++) {
    if (agendaList[i].repeticao) agendaList[i].data_agenda = compra.data_agenda;
  }
  return agendaList;
};

//Deleta uma agenda do banco
const deleteAgenda = async (id_agenda) => {
  return await new Promise(async (resolve, reject) => {
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
};

//Deleta todas as exclusões de uma agenda recorrente
const deleteExclusoesAgenda = async (id_agenda) => {
  return await new Promise(async (resolve, reject) => {
    conection.query(
      "DELETE FROM l_exclusao_agenda WHERE id_agenda = ?",
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
};

//Remove toda a agenda, com todos seus derivados
const removeAgenda = async (id_agenda) => {
  await materialAgenda.deleteByAgenda(id_agenda);
  //Deleta todas as exclusoes, pro caso de ser uma agenda recorrente
  await deleteExclusoesAgenda(id_agenda);
  return await deleteAgenda(id_agenda);
};

module.exports = {
  readByDay,
  insertExclusaoAgenda,
  getDataNextInstance,
  readAgendasByCompra,
  deleteAgenda,
  removeAgenda,
  readForTable,
};
