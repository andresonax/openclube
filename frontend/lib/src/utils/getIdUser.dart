import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';

//busca id do usuario
Future<String> getIdUser() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final String? token = prefs.getString('token');
  if (token != null) {
    Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
    int id = decodedToken['id_usuario'];
    return id.toString();
  }
  return '';
}