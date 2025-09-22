const conection = require("../../../../config/database"); // ATENCÃO A ESTE PATH!!!

//Obtém dados do banco Sicoob
const getDadosBancoSicoob = async () => {
  return await new Promise((resolve, reject) => {
    conection.query(
      "SELECT * FROM dados_banco WHERE num_banco = ?",
      [banks["sicoob"]],
      (error, results) => {
        if (error) reject(error);
        else resolve(results[0]);
      }
    );
  });
};


module.exports = {

    getDadosBancoSicoob
}







