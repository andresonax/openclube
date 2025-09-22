const bcrypt = require("bcrypt");
const util = require("util");
const path = require("path");
const fs = require("fs");
const moment = require("moment");
const conection = require("../config/database");

const banks = {
  juno: "383",
  viaCredi: "085",
  inter: "077",
  sicredi: "748",
  bb: "001",
  sicoob: "756"
};


const unauthorized = (res) => {
  res.status(401);
  res.json({
    err: true,
    message: "Você não possui autorização para realizar essa ação.",
    unauthorized: true,
  });
};

const querySuccess = (nChanges) => {
  return {
    success: true,
    didSomething: nChanges > 0,
  };
};

const strIsValidCpf = (cpf) => {
  if (typeof cpf !== "string") {
    return false;
  }

  cpf = cpf.replace(/[^\d]/g, "");
  if (cpf === "") return false;
  // Elimina CPFs invalidos conhecidos
  if (
    cpf.length !== 11 ||
    cpf === "00000000000" ||
    cpf === "11111111111" ||
    cpf === "22222222222" ||
    cpf === "33333333333" ||
    cpf === "44444444444" ||
    cpf === "55555555555" ||
    cpf === "66666666666" ||
    cpf === "77777777777" ||
    cpf === "88888888888" ||
    cpf === "99999999999"
  )
    return false;
  // Valida 1o digito
  let add = 0;
  for (let i = 0; i < 9; i++) add += parseInt(cpf.charAt(i)) * (10 - i);
  let rev = 11 - (add % 11);
  if (rev === 10 || rev === 11) rev = 0;
  if (rev !== parseInt(cpf.charAt(9))) return false;
  // Valida 2o digito
  add = 0;
  for (let i = 0; i < 10; i++) add += parseInt(cpf.charAt(i)) * (11 - i);
  rev = 11 - (add % 11);
  if (rev === 10 || rev === 11) rev = 0;
  if (rev !== parseInt(cpf.charAt(10))) return false;
  return true;
};

const strIsValidCnpj = (cnpj) => {
  if (typeof cnpj !== "string") {
    return false;
  }

  cnpj = cnpj.replace(/[^\d]+/g, "");

  // Valida a quantidade de caracteres
  if (cnpj.length !== 14) return false;

  // Elimina inválidos com todos os caracteres iguais
  if (/^(\d)\1+$/.test(cnpj)) return false;

  // Cáculo de validação
  const t = cnpj.length - 2;
  const d = cnpj.substring(t);
  const d1 = parseInt(d.charAt(0));
  const d2 = parseInt(d.charAt(1));
  const calc = (x) => {
    const n = cnpj.substring(0, x);
    let y = x - 7;
    let sF = 0;
    let r = 0;

    for (let i = x; i >= 1; i--) {
      sF += Number(n.charAt(x - i)) * y--;
      if (y < 2) y = 9;
    }

    r = 11 - (sF % 11);
    return r > 9 ? 0 : r;
  };

  return calc(t) === d1 && calc(t + 1) === d2;
};

const strIsValidEmail = (email) => {
  if (typeof email !== "string") {
    return false;
  }

  if (email.length > 150) {
    return false;
  }

  const emailRegex =
    /^(([^<>()[\]\\.,;:\s@"]+(\.[^<>()[\]\\.,;:\s@"]+)*)|(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/;

  return emailRegex.test(email);
};

  function err(error, msg) {
    console.error(error);
    console.error(msg);
    if (error.isAxiosError) {
      return {
        err: true,
        status: error.status,
        statusText: error.statusText,
        data: error.data,
      };
    } else {
      try {
        return {
          err: true,
          ...error,
        };
      } catch (e) {
        return {
          err: true,
          data: error,
        };
      }
    }
  }


const strIsValidBrPhone = (phone) => {
  if (typeof phone !== "string") {
    return false;
  }

  phone = phone.replace(/[^\d]/g, "");

  return !(phone.length < 10 || phone.length > 11);
};

class NonNumericStrError extends Error {
  constructor(message) {
    super(message);
    this.name = "Non Numeric String Error";
  }
}
class InvalidArgError extends Error {
  constructor(message, field) {
    super(message);
    this.name = "Invalid Argument Error";
    this.field = field;
  }
}

class InvalidObjectFormat extends Error {
  constructor(message, key) {
    super(message);
    this.name = "Invalid Object Format Error";
    this.key = key;
  }
}

const strToInt = (str) => {
  if (/^(\-|\+)?([0-9]+)$/.test(str)) {
    return Number(str);
  }
  throw new NonNumericStrError(`String(${str}) is not an integer`);
};

const strToFloat = (str) => {
  if (/^(\-|\+)?(([0-9]+)?((\.|,)[0-9]+)?)$/.test(str)) {
    return Number(str.toString().replace(/,/g, "."));
  }

  throw new NonNumericStrError(`String(${str}) is not a float`);
};

const createUserError = (message) => {
  return {
    err: true,
    message,
  };
};

const asyncRoute = (fn) => {
  return (req, res, next) => {
    Promise.resolve(fn(req, res, next)).catch(next);
  };
};

// Talvez vale a pena mudar apenas os argumentos passados no body no caso de um UPDATE no caso o único argumento requerido seria o 'key'

const isSet = (val) => {
  return (
    typeof val !== "undefined" && val !== null && val !== NaN && val !== ""
  );
};

const resolveObj = (path, obj, separator = ".") => {
  const properties = Array.isArray(path) ? path : path.split(separator);
  return properties.reduce((prev, curr) => prev && prev[curr], obj);
};

const parseArgs = (argsDescription, req, isUpdate) => {
  const args = [];
  let key;
  let strNames = "";
  let strQuotes = "";
  let strUpdate = "";

  for (const arg of Object.keys(argsDescription)) {
    const currArg = argsDescription[arg];
    const src = currArg.src ? resolveObj(currArg.src, req) : req.body;
    const name = currArg.altName ? currArg.altName : arg;
    let val = src ? src[name] : null;

    if (typeof currArg.literalValue !== "undefined") {
      val = currArg.literalValue;
    }

    if (!currArg.hideIfNone || isSet(val)) {
      if (!isUpdate) {
        strNames += `${arg},`;
        strQuotes += `?,`;
      } else if (!currArg.isKey) {
        strUpdate += `${arg} = ?,`;
      }
    }

    if (isSet(val) || currArg.optional || currArg.hideIfNone) {
      if (isSet(val)) {
        if (!currArg.validate || currArg.validate(val)) {
          if (currArg.transform) {
            val = currArg.transform(val);
          }

          if (currArg.numeric) {
            try {
              if (currArg.float) {
                args.push(strToFloat(val));
              } else {
                args.push(strToInt(val));
              }
            } catch (e) {
              if (e instanceof NonNumericStrError) {
                throw new InvalidArgError(
                  "Numeric argument was not valid numeric string",
                  name
                );
              }
              throw e;
            }
          } else if (currArg.date) {
            const date = new Date(val);

            if (date === "Invalid Date") {
              throw new InvalidArgError(
                "Date argument was not valid date string",
                name
              );
            }

            args.push(date);
          } else if (currArg.maxSize) {
            args.push(String(val).substring(0, currArg.maxSize));
          } else {
            args.push(val);
          }
        } else {
          throw new InvalidArgError(
            "Argument did not pass the validate function ",
            name
          );
        }
      } else {
        if (!currArg.hideIfNone) {
          args.push(null);
        }
      }

      if (currArg.isKey) {
        if (key) {
          throw new Error("Update procedure can't have more than one key");
        }
        key = {
          val: args.pop(),
          field: arg,
        };
      }
    } else {
      throw new InvalidArgError("Required argument was not defined", name);
    }
  }

  if (isUpdate) {
    if (key) {
      args.push(key.val);
      strUpdate = strUpdate.slice(0, -1);
      strUpdate += ` WHERE ${key.field} = ?`;
    } else {
      throw new Error("Update procedure requires one key field");
    }
  }

  return {
    argsUpdateStr: strUpdate,
    argsArray: args,
    argsNames: strNames.slice(0, -1),
    argsQuotes: strQuotes.slice(0, -1),
  };
};

const hashPassword = (password) => {
  return bcrypt.hashSync(password, 12);
};

const getDuplicateCollumnFromErrorMsg = (errorMessage) => {
  if (typeof errorMessage === "string") {
    const rgx = /'(\w+)_UNIQUE'/;
    const capture = errorMessage.match(rgx);
    if (capture && capture[1]) {
      return capture[1];
    }
  }

  return null;
};

const removeFile = async (basePath, file) => {
  const p = basePath + path.basename(file);

  const lstatPromise = util.promisify(fs.lstat);
  const unlinkPromise = util.promisify(fs.unlink);

  const stat = await lstatPromise(p);

  if (stat && stat.isFile()) {
    await unlinkPromise(p);
  }
};

const checkObjectForProperties = (object, properties) => {
  for (const property of properties) {
    if (!object || !isSet(object[property])) {
      throw new InvalidObjectFormat(
        `The object is missing the ${property} property!`,
        property
      );
    }
  }
};

const checkArrayOfObjectsForProperties = (arrObj, properties) => {
  if (!arrObj) {
    throw new InvalidObjectFormat(`The array has no objects!`, "array");
  }

  try {
    for (const obj of arrObj) {
      checkObjectForProperties(obj, properties);
    }
  } catch (e) {
    if (e instanceof InvalidObjectFormat) {
      throw new InvalidObjectFormat(
        `The array of objects has an object missing the ${e.key} property!`,
        e.key
      );
    }

    throw e;
  }
};

const checkUseBoleto = async () => {
  const sqlCheck = "SELECT * from parametros";
  return await new Promise((resolve, reject) => {
    conection.query(sqlCheck, async (error, results) => {
      if (error) {
        resolve(true);
      } else {
        const [parametros] = results;
        resolve(parametros.utiliza_boleto == 1);
      }
    });
  });
};

//Converte objeto Date com data e hora para Moment
const dataHoraToMoment = (data_hora) => {
  const hour = data_hora.getHours();
  const minutes = data_hora.getMinutes();
  return dateAndHourToMoment(data_hora, `${hour}/${minutes}`);
};

//Obtém a partir de um Date e uma string de horario opcional
const dateAndHourToMoment = (data, horario = null) => {
  var year, month, day, hours;
  if (moment.isMoment(data)) {
    year = data.year();
    month = data.month() + 1;
    day = data.date();
    hours = `${data.hours()}:${data.minutes()}`;
  } else {
    year = data.getFullYear();
    month = data.getMonth() + 1;
    day = data.getDate();
  }
  if (horario) hours = horario;
  if (hours)
    return moment(`${year}-${month}-${day} ${hours}`, "YYYY-MM-DD HH:mm:ss");
  return moment(`${year}-${month}-${day}`, "YYYY-MM-DD").startOf("day");
};

const getImgBase64 = (imgPath) => {
  try {
    const logoBase64 = `data:image/png;base64,${fs.readFileSync(
      imgPath,
      "base64"
    )}`;
    return logoBase64;
  } catch (error) {
    console.log("Erro ao converter imagem " + img + " para base 64");
    return null;
  }
};




module.exports = {
  err,
  dataHoraToMoment,
  dateAndHourToMoment,
  checkArrayOfObjectsForProperties,
  checkObjectForProperties,
  InvalidObjectFormat,
  removeFile,
  strIsValidCnpj,
  getDuplicateCollumnFromErrorMsg,
  resolveObj,
  isSet,
  strIsValidBrPhone,
  hashPassword,
  strIsValidEmail,
  strIsValidCpf,
  unauthorized,
  parseArgs,
  asyncRoute,
  querySuccess,
  createUserError,
  strToFloat,
  NonNumericStrError,
  InvalidArgError,
  strToInt,
  checkUseBoleto,
  banks,
  getImgBase64
};
