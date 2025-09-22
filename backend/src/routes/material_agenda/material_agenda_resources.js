const conection = require("../../config/database"); // ATENCÃO A ESTE PATH!!!

const read = async (id_agenda) => {
  return await new Promise((resolve, reject) => {
    conection.query(
      "SELECT * FROM l_material_agenda WHERE id_agenda = ?",
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

module.exports = {
  read,
};
