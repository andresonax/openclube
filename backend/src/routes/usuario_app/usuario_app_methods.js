/* eslint-disable no-undef */
const conection = require("../../config/database"); // ATENCÃO A ESTE PATH!!!
const bcrypt = require("bcrypt");
const {
  matchPasswords,
  encryptPassword,
} = require("../../utils/password");

const readUsuarioApp = async (id_usuario) => {
  return await new Promise((resolve, reject) => {
    conection.query(
      "SELECT * FROM usuario WHERE id_usuario = ?",
      [id_usuario],
      (error, results) => {
        if (error) reject(error);
        else resolve(results);
      }
    );
  });
};

const readPessoa = async (id_usuario) => {
  return await new Promise((resolve, reject) => {
    conection.query(
      "SELECT p.*, contato FROM pessoa p LEFT JOIN contato c ON c.id_pessoa = p.id_pessoa AND c.eTelefonePrincipal = 1 WHERE p.id_pessoa = ?",
      [id_usuario],
      (error, results) => {
        if (error) reject(error);
        else resolve(results);
      }
    );
  });
};

//alterar pra quando entender tipo_usuario;
const getDadosUsuario = async (id_usuario, tipo_usuario) => {

  console.log('getdadosUsuario');
  console.log(id_usuario)
  console.log(tipo_usuario)


  if (tipo_usuario == "u") {
    const [usuarioApp] = await readUsuarioApp(id_usuario);
    console.log(usuarioApp)
    return {
      id_usuario,
      nome: usuarioApp.nome_completo,
      cpf: usuarioApp.cpf, //gravou não pede cpf
      email: usuarioApp.email,
      contato: usuarioApp.contato,
      tipo_usuario,
    };

  }
  const [pessoa] = await readPessoa(id_usuario);
  return {
    id_usuario,
    nome: pessoa.nome_pessoa,
    cpf: pessoa.cpf_pessoa,
    email: pessoa.email,
    contato: pessoa.contato,
    tipo_usuario,
  };
};

//Atualiza a senha do usuário
const updatePasswordUsuario = async (id_usuario, hash) => {
  return await new Promise((resolve, reject) => {
    conection.query(
      "UPDATE usuario SET senha = ? WHERE id_usuario = ?",
      [hash, id_usuario],
      (error, results) => {
        if (error) reject(error);
        else resolve(results);
      }
    );
  });
};

//Altera a senha do usuário
const alterarSenhaUsuario = async (id_usuario, senha_atual, senha_nova) => {
  const [usuario] = await readUsuarioApp(id_usuario);
  const passwordsMatch = await matchPasswords(usuario.senha, senha_atual);
  if (!passwordsMatch) throw { msg: "Senha atual incorreta!" };
  const hash = await encryptPassword(senha_nova);
  await updatePasswordUsuario(id_usuario, hash);
};

module.exports = {
  read: async () => {
    return await new Promise((resolve, reject) => {
      conection.query("SELECT * FROM usuario", (error, results) => {
        if (error) {
          reject(error);
        } else {
          resolve(results);
        }
      });
    });
  },
  create: async (data) => {
    return await new Promise((resolve, reject) => {
      conection.query(
        "INSERT INTO usuario(nome, cpf, email, contato, senha) VALUES (?, ?, ?, ?, ?)",
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
  },
  searchHasEmail: async (email) => {
    return await new Promise((resolve, reject) => {
      conection.query(
        "SELECT * FROM usuario WHERE email = ?",
        [email],
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
  searchHasCpf: async (cpf) => {
    return await new Promise((resolve, reject) => {
      conection.query(
        "SELECT * FROM usuario WHERE cpf = ?",
        [cpf],
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
  login: async (email, senha) => {
    return await new Promise((resolve, reject) => {
      conection.query(
        "SELECT * FROM usuario WHERE email = ?",
        [email],
        (error, results) => {
          if (error) {
            reject(error);
          } else {
            const usuario = results[0];
            if (!usuario) {
              conection.query(
                "SELECT * FROM pessoa WHERE email = ?",
                [email],
                (error, results2) => {
                  if (error) {
                    reject(error);
                  } else {
                    const pessoa = results2[0];
                    if (!pessoa) {
                      resolve({ authenticated: false });
                    } else {
                      const buffer = new Buffer.from(pessoa.senha, "binary");
                      bcrypt
                        .compare(senha, buffer.toString())
                        .then((bResult) => {
                          if (pessoa.id_perfil == -2) {
                            resolve({
                              authenticated: bResult,
                              data: pessoa,
                              tipo_usuario: "r",
                            });
                          } else if (pessoa.id_perfil == -1) {
                            resolve({
                              authenticated: bResult,
                              data: pessoa,
                              tipo_usuario: "a",
                            });
                          } else {
                            resolve({
                              authenticated: bResult,
                              data: pessoa,
                              tipo_usuario: "o",
                            });
                          }
                        })
                        .catch((e) => {
                          reject(e);
                        });
                    }
                  }
                }
              );
            } else {
              const buffer = new Buffer.from(usuario.senha, "binary");
              bcrypt
                .compare(senha, buffer.toString())
                .then((bResult) => {
                  resolve({
                    authenticated: bResult,
                    data: usuario,
                    tipo_usuario: "u",
                  });
                })
                .catch((e) => {
                  reject(e);
                });
            }
          }
        }
      );
    });
  },
  getDadosUsuario,
  alterarSenhaUsuario,
};
