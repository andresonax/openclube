const conection = require("../../config/database"); // ATENCÃO A ESTE PATH!!!

read = async () => {
  return await new Promise((resolve, reject) => {
    conection.query("SELECT * FROM l_bloqueio_grade", (error, results) => {
      if (error) {
        reject(error);
      } else {
        resolve(results);
      }
    });
  });
};

readByPlaceId = async (id_espaco) => {
  return await new Promise((resolve, reject) => {
    conection.query(
      "SELECT * FROM l_bloqueio_grade WHERE id_espaco = ?",
      [id_espaco],
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

create = async (data) => {
  return await new Promise((resolve, reject) => {
    conection.query(
      "INSERT INTO l_bloqueio_grade(inicio, final, data_inicio, data_fim, descricao, dia_semana, id_espaco) VALUES (?, ?, ?, ?, ?, ?, ?)",
      data,
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

update = async (id_bloqueio_grade, data) => {
  return await new Promise((resolve, reject) => {
    conection.query(
      "UPDATE l_bloqueio_grade SET inicio = ?, final = ?, data_inicio = ?, data_fim = ?, descricao = ?, dia_semana = ?, id_espaco = ? WHERE id_bloqueio_grade = ?",
      [...data, id_bloqueio_grade],
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

deleteBloqueio = async (id_bloqueio_grade) => {
  const results = await new Promise((resolve, reject) => {
    conection.query(
      "DELETE FROM l_bloqueio_grade WHERE id_bloqueio_grade = ?",
      [id_bloqueio_grade],
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

module.exports = {
  read,
  readByPlaceId,
  create,
  update,
  deleteBloqueio,
};
