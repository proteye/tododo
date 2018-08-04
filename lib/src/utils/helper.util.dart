class Helper {
  static String getLogin(String username) {
    List<String> splitted = username.split('@');
    return splitted[0];
  }

  static String getNickname(String username) {
    return '@' + getLogin(username);
  }
}
