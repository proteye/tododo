class Helper {
  static String getNickname(String username) {
    List<String> splitted = username.split('@');
    return splitted[0];
  }

  static String getAtNickname(String username) {
    return '@' + getNickname(username);
  }

  static int sortByUsername(a, b) {
    return a['username'].toLowerCase().compareTo(b['username'].toLowerCase());
  }
}
