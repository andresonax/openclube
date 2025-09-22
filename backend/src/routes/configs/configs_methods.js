const conection = require("../../config/database"); // ATENCÃO A ESTE PATH!!!
const { readConfigs } = require("./configs_resources");

const updateConfigsPagamento = async (data) => {
  return await new Promise((resolve, reject) => {
    conection.query(
      "UPDATE l_configs SET id_banco_pix = ?, valor_obrigatorio_reserva = ?, expiracao_minutos_pix = ?, usa_pix = ?, usa_boleto = ?",
      data,
      (error, results) => {
        if (error) reject(error);
        else resolve(results);
      }
    );
  });
};

const updateConfigsAgenda = async (data) => {
  return await new Promise((resolve, reject) => {
    conection.query(
      "UPDATE l_configs SET periodo_antecedencia_reserva = ?",
      [data.periodo_antecedencia_reserva],
      (error, results) => {
        if (error) reject(error);
        else resolve(results);
      }
    );
  });
};

//Atualiza as configurações do alerta de compra
const updateAlertaCompra = async (data) => {
  return await new Promise((resolve, reject) => {
    conection.query(
      "UPDATE l_configs SET id_perfil_alerta_compra = ?, msg_geral_alerta_compra = ?, msg_agendamentos_alerta_compra = ?, assunto_alerta_compra = ?",
      [
        data.id_perfil_alerta_compra,
        data.msg_geral_alerta_compra,
        data.msg_agendamentos_alerta_compra,
        data.assunto_alerta_compra,
      ],
      (error, results) => {
        if (error) reject(error);
        else resolve(results);
      }
    );
  });
};

module.exports = {
  readConfigs,
  updateConfigsPagamento,
  updateConfigsAgenda,
  updateAlertaCompra,
};
