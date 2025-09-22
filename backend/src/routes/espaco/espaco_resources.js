const connection = require("../../config/database"); // ATENCÃO A ESTE PATH!!!

//Lê o espaço pelo ID
const readById = async (id_espaco) => {
  return await new Promise((resolve, reject) => {
    connection.query(
      "SELECT * FROM l_espaco WHERE id_espaco = ?",
      [id_espaco],
      async (error, results) => {
        if (error) reject(error);
        else resolve(results);
      }
    );
  });
};

module.exports = {
  readById,
};
