const { moment } = require("../../utils/moment_local");
const gradeMethods = require("../grade_agenda/grade_agenda_methods");
const bloqueioMethods = require("../bloqueio_grade/bloqueio_grade_methods");
const agendaMethods = require("../agenda/agenda_methods");
const { readConfigs } = require("../configs/configs_methods");
const { isHorarioPassado, isHorarioReservado } = require("./horario_resources");

const checkVigencia = (inicio, final, day) => {
  inicio = moment(inicio, "YYYY-MM-DD").startOf("day");
  final = moment(final, "YYYY-MM-DD").startOf("day");
  return day >= inicio && day <= final;
};

const checkIntersection = (h1, h2) => {
  const h1EndsBeforeh2 =
    moment(h1.final, "HH:mm:ss").startOf("minute") <=
    moment(h2.inicio, "HH:mm:ss").startOf("minute");
  const h1StartsAfterh2 =
    moment(h1.inicio, "HH:mm:ss").startOf("minute") >=
    moment(h2.final, "HH:mm:ss").startOf("minute");
  return !h1EndsBeforeh2 && !h1StartsAfterh2;
};

const checkBlock = (block, horario, day) => {
  const vigente = checkVigencia(block.data_inicio, block.data_fim, day);
  if (vigente) {
    if (
      day.day() == block.dia_semana - 1 &&
      horario.id_espaco == block.id_espaco
    ) {
      if (checkIntersection(horario, block)) {
        return true;
      }
    }
  }
  return false;
};

const applyBloqueios = async (horarios, day) => {
  const bloqueios = await bloqueioMethods.read();
  const available = [];
  horarios.map((horario) => {
    var blocked = false;
    for (var i = 0; i < bloqueios.length; i++) {
      blocked = checkBlock(bloqueios[i], horario, day);
      if (blocked) break;
    }
    if (!blocked) {
      available.push(horario);
    }
  });
  return available;
};

const createHorario = (indexHorario, grade, inicio, day) => {
  const horario = {
    id_horario: indexHorario,
    ...grade,
  };
  const final = moment(inicio);
  final.add(grade.grade_minutos, "minutes");
  horario.inicio = inicio.format("HH:mm:ss");
  horario.final = final.format("HH:mm:ss");
  horario.data = day;
  return horario;
};

const breakGrade = (grade, horarios, indexHorario, day) => {
  var initHour = moment(grade.inicio, "HH:mm:ss");
  var endHour = moment(grade.final, "HH:mm:ss");
  const tempoTotalGrade = endHour.diff(initHour, "minutes");
  if (!grade.grade_minutos) return indexHorario;
  for (var i = 0; i < tempoTotalGrade; i += grade.grade_minutos) {
    const inicio = moment(initHour);
    inicio.add(i, "minutes");
    const horario = createHorario(indexHorario, grade, inicio, day);
    horarios.push(horario);

    indexHorario++;
  }
  return indexHorario;
};

const gradesToHorarios = (grades, day) => {
  const horarios = [];
  var indexHorario = 0;
  grades.map((grade) => {
    indexHorario = breakGrade(grade, horarios, indexHorario, day);
  });
  return horarios;
};

//Filtra os horários que estão agendados (não disponíveis)
const filterDisponiveis = async (horarios, day) => {
  const agendaList = await agendaMethods.readByDay(day);
  return horarios.filter((horario) => !isHorarioReservado(horario, agendaList));
};

//Filtra os horários passados/indisponíveis devido ao período de antecedência requerido para reserva
filterPassados = async (horarios, day) => {
  const configs = await readConfigs();
  return horarios.filter((horario) => {
    return !isHorarioPassado(horario, configs);
  });
};

//Realiza os processamentos na grade, transformando-as em horários
const processGrades = async (grades, day) => {
  const vigentes = grades.filter((grade) =>
    checkVigencia(grade.vigencia_inicio, grade.vigencia_final, day)
  );
  var horarios = gradesToHorarios(vigentes, day);
  horarios = await applyBloqueios(horarios, day);
  horarios = await filterDisponiveis(horarios, day);
  horarios = await filterPassados(horarios, day);
  return horarios;
};

const getHorarios = async (dia) => {
  const day = moment(dia, "YYYY-MM-DD").startOf("day");
  const weekday = day.day() + 1;
  const grades = await gradeMethods.readByDay(weekday);
  const horarios = await processGrades(grades, day);
  return horarios;
};

const getHorariosByEspaco = async (dia, id_espaco) => {
  const day = moment(dia, "YYYY-MM-DD").startOf("day");
  const weekday = day.day() + 1;
  const grades = await gradeMethods.readByDayAndEspaco(weekday, id_espaco);
  const horarios = await processGrades(grades, day);
  return horarios;
};

module.exports = {
  getHorarios,
  getHorariosByEspaco,
};
