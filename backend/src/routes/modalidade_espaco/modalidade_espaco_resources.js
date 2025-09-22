const connection = require("../../config/database"); // ATENCÃO A ESTE PATH!!!

//Lê a modalidade pelo ID
const readModalidadeById = async (id_modalidade_espaco) => {
  return await new Promise((resolve, reject) => {
    connection.query(
      "SELECT * FROM l_modalidade_espaco WHERE id_modalidade_espaco = ?",
      [id_modalidade_espaco],
      async (error, results) => {
        if (error) reject(error);
        else resolve(results);
      }
    );
  });
};

module.exports = {
  readModalidadeById,
};
