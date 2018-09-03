class Helper {
  static String getNickname(String username) {
    if (username == null || username.isEmpty) {
      return '';
    }

    List<String> splitted = username.split('@');
    return splitted[0];
  }

  static String getAtNickname(String username) {
    if (username == null || username.isEmpty) {
      return '';
    }

    return '@' + getNickname(username);
  }

  static int sortByUsername(a, b) {
    return a['username'].toLowerCase().compareTo(b['username'].toLowerCase());
  }
}
