const bcrypt = require("bcrypt");

const encryptPassword = async (senha) => {
  return await new Promise((resolve, reject) => {
    bcrypt.hash(senha, 12, (err, hash) => {
      if (err) reject(err);
      else resolve(hash);
    });
  });
};

const matchPasswords = async (hash, senha) => {
  return await new Promise((resolve, reject) => {
    const passwordBuffer = new Buffer.from(hash, "binary");
    bcrypt.compare(senha, passwordBuffer.toString(), (error, resp) => {
      if (error) reject(error);
      else resolve(resp);
    });
  });
};

module.exports = {
  encryptPassword,
  matchPasswords,
};
