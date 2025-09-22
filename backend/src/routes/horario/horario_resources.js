const { moment } = require("../../utils/moment_local");
const { dateAndHourToMoment } = require("../../utils/utils");

//Checa se horário é do passado/indisponível devido ao período de antecedência requerido para reserva
const isHorarioPassado = (horario, configs) => {
  const dataHora = dateAndHourToMoment(horario.data, horario.inicio);
  const dataHoraAntecedencia = moment().add(
    configs.periodo_antecedencia_reserva,
    "hours"
  );
  return dataHora < dataHoraAntecedencia;
};

//Checa se o horário foi reservado por outro usuário
const isHorarioReservado = (horario, agendaList) => {

  
  //console.log('isHorarioReservado!');
  //console.log('horario' + horario.inicio + 'espaco' + horario.espaco);
  //console.log('agendaList' + agendaList[0].horario);

  const agenda = agendaList.find(
    (agenda) =>
      agenda.horario == horario.inicio+':00' && agenda.id_espaco == horario.id_espaco
  );
  return agenda ? true : false;
};

module.exports = {
  isHorarioPassado,
  isHorarioReservado,
};
