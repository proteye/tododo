import 'package:tododo/src/auth/login.dart';
import 'package:tododo/src/auth/register.dart';

class Routing {
  static routes(websocket) {
    return {
      '/': (context) => new LoginScreen(websocket: websocket),
      '/register': (context) => new RegisterScreen()
    };
  }
}
