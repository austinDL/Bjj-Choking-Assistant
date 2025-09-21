import 'dart:async';
import 'dart:math';

class PressureRow {
  final int row;
  final List<int> pressures; // values for each column
  PressureRow(this.row, this.pressures);
}

class PressureProfile {
  final DateTime timestamp;
  final List<PressureRow> rows;
  PressureProfile(this.timestamp, this.rows);
}

Stream<List<int>> simulateBleData(int numRows, int numCols) async* {
  final rand = Random();
  while (true) {
    for (int r = 0; r < numRows; r++) {
      List<int> bytes = [];
      bytes.add(r); // row number
      for (int c = 0; c < numCols; c++) {
        int pressure = rand.nextInt(4095); // 12-bit sensor
        bytes.add(pressure & 0xFF);
        bytes.add((pressure >> 8) & 0xFF);
      }
      yield bytes;
    }
    await Future.delayed(const Duration(milliseconds: 50)); // ~20fps
  }
}