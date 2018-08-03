import 'package:tododo/src/navbar.dart';
import 'package:tododo/src/screens/auth/login.dart';
import 'package:tododo/src/screens/auth/register.dart';
import 'package:tododo/src/screens/contacts/contactAdd.dart';

class Routing {
  static routes() {
    return {
      '/': (context) => new LoginScreen(),
      '/register': (context) => new RegisterScreen(),
      '/main': (context) => new BottomNavbarScreen(),
      '/contactAdd': (context) => new ContactAddScreen(),
    };
  }
}
