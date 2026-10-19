// Utilitas kalender murni (tanpa Flutter) agar mudah diuji.

const List<String> _monthNames = [
  'Januari',
  'Februari',
  'Maret',
  'April',
  'Mei',
  'Juni',
  'Juli',
  'Agustus',
  'September',
  'Oktober',
  'November',
  'Desember',
];

const List<String> _weekdayShort = [
  'Sen',
  'Sel',
  'Rab',
  'Kam',
  'Jum',
  'Sab',
  'Min',
];

String monthName(int month) => _monthNames[month - 1];

String weekdayLabel(int weekday) => _weekdayShort[weekday - 1];

int daysInMonth(int year, int month) => DateTime(year, month + 1, 0).day;

/// Kunci tanggal tanpa komponen jam, dipakai sebagai kunci peta tugas.
DateTime dayKey(DateTime date) => DateTime(date.year, date.month, date.day);

/// Grid bulan yang dimulai hari Senin. Sel kosong di awal/akhir bernilai null.
List<List<DateTime?>> buildMonthGrid(int year, int month) {
  final firstDay = DateTime(year, month, 1);
  final leadingBlanks = firstDay.weekday - DateTime.monday;
  final totalDays = daysInMonth(year, month);

  final cells = <DateTime?>[
    for (var i = 0; i < leadingBlanks; i += 1) null,
    for (var day = 1; day <= totalDays; day += 1) DateTime(year, month, day),
  ];

  while (cells.length % 7 != 0) {
    cells.add(null);
  }

  return [
    for (var i = 0; i < cells.length; i += 7) cells.sublist(i, i + 7),
  ];
}

String formatTime(DateTime date) {
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}
