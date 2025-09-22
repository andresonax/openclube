const connection = require("../../config/database"); // ATENCÃO A ESTE PATH!!!
const { readByDay, readForTable } = require("../agenda/agenda_resources");
const moment = require("moment");
const { readConfigs } = require("../configs/configs_methods");
const {
  isHorarioPassado,
  isHorarioReservado,
} = require("../horario/horario_resources");
const { dateAndHourToMoment } = require("../../utils/utils");

/*
//Lê os horários do carrinho
const readHorarioList = async (id_usuario, tipo_usuario) => {
  return await new Promise((resolve, reject) => {
    connection.query(
      "SELECT * FROM l_horario_carrinho WHERE id_usuario = ? AND tipo_usuario = ? ORDER BY data, inicio;",
      [id_usuario, tipo_usuario],
      (error, results) => {
        if (error) reject(error);
        else resolve(results);
      }
    );
  });
};

//Lê os materiais de um horário
const readMaterialList = async (id_horario_carrinho) => {
  return await new Promise((resolve, reject) => {
    connection.query(
      "SELECT * FROM l_material_horario_carrinho WHERE id_horario_carrinho = ?;",
      [id_horario_carrinho],
      (error, results) => {
        if (error) reject(error);
        else resolve(results);
      }
    );
  });
};

//Checa se horário está no passado/indisponível devido ao período de antecedência requerido para reserva
const checkIsHorarioPassado = async (horario) => {
  //Lê as configurações de locação
  const configs = await readConfigs();
  return isHorarioPassado(horario, configs);
};

//Checa se horário está reservado
const checkIsHorarioReservado = async (horario) => {
  const agendaList = await readForTable(horario.id_espaco, horario.data);
  //Se horário estiver comprado, deleta do carrinho
  return isHorarioReservado(horario, agendaList);
};

//Lê o carrinho
const readCarrinho = async (id_usuario, tipo_usuario) => {
  //Lê a lista de horários do carrinho
  const horarioList = await readHorarioList(id_usuario, tipo_usuario);
  //Cria a lista de horários fitrados
  const filteredList = [];
  for (var i = 0; i < horarioList.length; i++) {
    //Se for horário do passado, deleta do carrinho
    if (await checkIsHorarioPassado(horarioList[i])) {
      await removeHorario(horarioList[i].id_horario_carrinho);
      continue;
    }
    if (await checkIsHorarioReservado(horarioList[i])) {
      await removeHorario(horarioList[i].id_horario_carrinho);
      continue;
    }
    horarioList[i].material_list = await readMaterialList(
      horarioList[i].id_horario_carrinho
    );
    filteredList.push(horarioList[i]);
  }
  return filteredList;
};

//Insere um material de um horário
const insertMaterialHorario = async (id_horario_carrinho, material) => {
  return await new Promise((resolve, reject) => {
    connection.query(
      "INSERT INTO l_material_horario_carrinho(id_horario_carrinho, id_material, quantidade) VALUES(?, ?, ?);",
      [id_horario_carrinho, material.id_material, material.quantidade],
      (error, results) => {
        if (error) reject(error);
        else resolve(results);
      }
    );
  });
};

//Insere um horário no carrinho
const insertHorarioCarrinho = async (id_usuario, tipo_usuario, horario) => {
  if (horario.data) horario.data = horario.data.substring(0, 10);
  return await new Promise((resolve, reject) => {
    connection.query(
      "INSERT INTO l_horario_carrinho(id_usuario, tipo_usuario, id_espaco, data, inicio, final, valor, valor_base, observacao, id_modalidade_espaco) VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?, ?);",
      [
        id_usuario,
        tipo_usuario,
        horario.id_espaco,
        horario.data,
        horario.inicio,
        horario.final,
        horario.valor,
        horario.valor_base,
        horario.observacao,
        horario.id_modalidade_espaco,
      ],
      (error, results) => {
        if (error) reject(error);
        else resolve(results);
      }
    );
  });
};

//Salva um horário no carrinho
const salvaHorarioCarrinho = async (id_usuario, tipo_usuario, horario) => {
  const result = await insertHorarioCarrinho(id_usuario, tipo_usuario, horario);
  if (!horario.material_list) return;
  for (var i = 0; i < horario.material_list.length; i++)
    await insertMaterialHorario(result.insertId, horario.material_list[i]);
};

//Checa se horário já existe no carrinho
const checaHorarioExiste = async (carrinho, novo) => {
  const existe = carrinho.find((horario) => {
    horario.data = moment.utc(horario.data).format("YYYY-MM-DD");
    novo.data = novo.data.substring(0, 10);
    novo.id_espaco = parseInt(novo.id_espaco);
    return (
      horario.inicio == novo.inicio &&
      horario.final == novo.final &&
      horario.data == novo.data &&
      horario.id_espaco == novo.id_espaco
    );
  });
  return existe;
};

//Salva os novos itens no carrinho
const salvarCarrinho = async (id_usuario, tipo_usuario, horarioList) => {
  const carrinho = await readCarrinho(id_usuario, tipo_usuario);
  for (var i = 0; i < horarioList.length; i++) {
    const existe = await checaHorarioExiste(carrinho, horarioList[i]);
    if (!existe) {
      await salvaHorarioCarrinho(id_usuario, tipo_usuario, horarioList[i]);
    }
  }
};

//Checa se o usuário possui itens no carrinho (retorna quantos)
const checaTemCarrinho = async (id_usuario, tipo_usuario) => {
  return await new Promise((resolve, reject) => {
    connection.query(
      "SELECT * FROM l_horario_carrinho WHERE id_usuario = ? AND tipo_usuario = ?;",
      [id_usuario, tipo_usuario],
      (error, results) => {
        if (error) reject(error);
        else {
          resolve({ num_items: results.length });
        }
      }
    );
  });
};

//Deleta os materiais de um horário
/*
const deleteMateriaisHorario = async (id_horario_carrinho) => {
  return await new Promise((resolve, reject) => {
    connection.query(
      "DELETE FROM l_material_horario_carrinho WHERE id_horario_carrinho = ?;",
      [id_horario_carrinho],
      (error, results) => {
        if (error) reject(error);
        else resolve(results);
      }
    );
  });
};

//Deleta um horário do carrinho
const deleteHorario = async (id_horario_carrinho) => {
  return await new Promise((resolve, reject) => {
    connection.query(
      "DELETE FROM l_horario_carrinho WHERE id_horario_carrinho = ?;",
      [id_horario_carrinho],
      (error, results) => {
        if (error) reject(error);
        else resolve(results);
      }
    );
  });
};

//Remove um horário e seus materiais
const removeHorario = async (id_horario_carrinho) => {
  //await deleteMateriaisHorario(id_horario_carrinho);
  await deleteHorario(id_horario_carrinho);
};

//Limpa todos os horários e materiais do carrinho
const limpaCarrinho = async (id_usuario, tipo_usuario) => {
  const horarioList = await readHorarioList(id_usuario, tipo_usuario);
  for (var i = 0; i < horarioList.length; i++) {
    await removeHorario(horarioList[i].id_horario_carrinho);
  }
};

//Sobrescreve itens do carrinho com novos
const sobrescreveCarrinho = async (id_usuario, tipo_usuario, horarioList) => {
  await limpaCarrinho(id_usuario, tipo_usuario);
  await salvarCarrinho(id_usuario, tipo_usuario, horarioList);
};

//Insere um horário no carrinho
const updateHorarioCarrinho = async (horario) => {
  return await new Promise((resolve, reject) => {
    connection.query(
      "UPDATE l_horario_carrinho SET valor = ?, observacao = ?, id_modalidade_espaco = ? WHERE id_horario_carrinho = ?;",
      [
        horario.valor,
        horario.observacao,
        horario.id_modalidade_espaco,
        horario.id_horario_carrinho,
      ],
      (error, results) => {
        if (error) reject(error);
        else resolve(results);
      }
    );
  });
};

//Realiza edição de um horário e seus materiais
const editHorarioCarrinho = async (horario) => {
  await updateHorarioCarrinho(horario);
  //await deleteMateriaisHorario(horario.id_horario_carrinho);
  if (!horario.material_list) return;
  for (var i = 0; i < horario.material_list.length; i++)
    await insertMaterialHorario(
      horario.id_horario_carrinho,
      horario.material_list[i]
    );
};

module.exports = {
  readCarrinho,
  salvarCarrinho,
  checaTemCarrinho,
  sobrescreveCarrinho,
  salvaHorarioCarrinho,
  limpaCarrinho,
  editHorarioCarrinho,
  removeHorario,
};
*/