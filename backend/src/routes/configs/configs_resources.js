const conection = require("../../config/database"); // ATENCÃO A ESTE PATH!!!

const readConfigs = async () => {
  return await new Promise((resolve, reject) => {
    conection.query("SELECT * FROM l_configs", (error, results) => {
      console.log('results configs');
      console.log(results);
      if (error) reject(error);
      else resolve(results[0]);
    });
  });
};

module.exports = {
  readConfigs,
};
