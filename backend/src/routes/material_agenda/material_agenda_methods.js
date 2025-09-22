const conection = require("../../config/database"); // ATENCÃO A ESTE PATH!!!
const resources = require("./material_agenda_resources");

module.exports = {
  read: resources.read,
  deleteByAgenda: async (id_agenda) => {
    return await new Promise((resolve, reject) => {
      conection.query(
        "DELETE FROM l_material_agenda WHERE id_agenda = ?",
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
  },
};
