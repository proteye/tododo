const WEEKDAYS = {
  DateTime.monday: 'Monday',
  DateTime.tuesday: 'Tuesday',
  DateTime.wednesday: 'Wednesday',
  DateTime.thursday: 'Thursday',
  DateTime.friday: 'Friday',
  DateTime.saturday: 'Saturday',
  DateTime.sunday: 'Sunday',
};

const MONTHS = {
  DateTime.january: 'January',
  DateTime.february: 'February',
  DateTime.march: 'March',
  DateTime.april: 'April',
  DateTime.may: 'May',
  DateTime.june: 'June',
  DateTime.july: 'July',
  DateTime.august: 'August',
  DateTime.september: 'September',
  DateTime.october: 'October',
  DateTime.november: 'November',
  DateTime.december: 'December',
};

String dayOfWeek(int weekday) {
  return WEEKDAYS[weekday];
}

String monthOfYear(int month) {
  return MONTHS[month];
}
