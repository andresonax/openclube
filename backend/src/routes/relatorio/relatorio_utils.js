const conection = require("../../config/database");
const { moment } = require("../../utils/moment_local");
const { getImgBase64 } = require("../../utils/utils");

//Path da logo da empresa
const logoPathAntigo = "./resources/logo/logo.png";
const logoPath = "./files/clientLogos"; 

//Obtém os dados da empresa

const getDadosEmpresa = async () => {
  return await new Promise((resolve, reject) => {
    conection.query("SELECT * FROM empresa;", (error, results) => {
      if (error) reject(error);
      else resolve(results);
    });
  });
};

const getDadosCliente = async (id_cliente) => {
  return await new Promise((resolve, reject) => {
    conection.query("SELECT * FROM cliente WHERE id_cliente = ?;", [id_cliente], (error, results) => {
      if (error) reject(error);
      else resolve(results);
    });
  });
}

/*
//Obtém o cabeçalho do relatório
const getHeader = async () => {
  //const [dadosEmpresa] = await getDadosEmpresa();
  const logoBase64 = await getImgBase64(logoPath);
  return `
      <div class="header">
        <div class="logo">
          <img src="${logoBase64}" />
        </div>
        <div class="dados">
          <span class="dado_empresa">
            <h2 class="nome_empresa">
              ${dadosEmpresa.nome_fantasia}
            </h2>
          </span>
          <span class="dado_empresa">
            <b class="data_hora">
              Data: ${moment().format("DD/MM/YYYY HH:mm")}
            </b>
          </span>
          <span class="dado_empresa">
            <b class="data_hora">
              ${dadosEmpresa.endereco_completo}. Tel: ${dadosEmpresa.telefone}
            </b>
          </span>
        </div>
      </div>
  `;
};*/

//Obtém o cabeçalho do relatório
const getHeader = async (id_cliente) => {
  const [dadosCliente] = await getDadosCliente(id_cliente);

  //corrigir logo
  const logoBase64 = await getImgBase64(logoPath+'/logo-'+dadosCliente.id_cliente+'.png');
  console.log(logoPath+'/logo-'+dadosCliente.id_cliente+'.png');

  return `
      <div class="header">
        <div class="logo">
          <img src="${logoBase64}" />
        </div>
        <div class="dados">
          <span class="dado_empresa">
            <h2 class="nome_empresa">
              ${dadosCliente.fantasia}
            </h2>
          </span>
          <span class="dado_empresa">
            <b class="data_hora">
              Data: ${moment().format("DD/MM/YYYY HH:mm")}
            </b>
          </span>
          <span class="dado_empresa">
            <b class="data_hora">
              ${dadosCliente.endereco}, ${dadosCliente.cidade}-${dadosCliente.uf}. Email: ${dadosCliente.email}
            </b>
          </span>
        </div>
      </div>
  `;
};

module.exports = {
  getHeader,
};
