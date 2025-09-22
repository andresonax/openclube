//inverte data inserida pelo usuário para o formato do banco de dados
String dateInverter(String dateFromInput) {
  List<String> parts = dateFromInput.split("/");

  String day = parts[0];
  String month = parts[1];
  String year = parts[2];

  if (int.parse(day) > 31 ||
      int.parse(month) > 12 ||
      int.parse(year) > DateTime.now().year ||
      int.parse(year) < 1900) {
    return "invalid date";
  } else {
    return "$year/$month/$day";
  }
}


//inverte data do banco de dados pro formato brasileiro(dd/mm/aaaa)
String dateReverter(String dateFromDataBase) {
  String date = dateFromDataBase.substring(0, 10);
  List<String> parts = date.split("-");
  String day = parts[2];
  String month = parts[1];
  String year = parts[0];
  return "$day/$month/$year";
}
