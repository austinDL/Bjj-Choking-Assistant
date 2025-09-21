import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

final int maxPressure = 4095; // 12-bit sensor

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
  
// TODO: Replace with actual BLE data stream
Stream<List<List<int>>> simulateBleData(int numRows, int numCols, {int delayInMilis=50}) async* {
  final rand = Random();
  while (true) {
    List<List<int>> data = [];
    for (int r = 0; r < numRows; r++) {
      List<int> bytes = [];
      bytes.add(r); // row number
      for (int c = 0; c < numCols; c++) {
        int pressure = rand.nextInt(maxPressure); // 12-bit sensor
        bytes.add(pressure & 0xFF);
        bytes.add((pressure >> 8) & 0xFF);
      }
      data.add(bytes);
    }
    yield data;
    await Future.delayed(Duration(milliseconds: delayInMilis)); // ~20fps
  }
}

List<List<int>> convertBleDataToGrid(List<List<int>> bleData) {
  final int numRows = bleData.length;
  final int numCols = bleData.isEmpty ? 0 : (bleData[0].length-1) ~/2;
  List<List<int>> grid = List.generate(numRows, 
      (index) => List.generate(numCols, (index) => 0));
  
  for (var rowData in bleData) {
    if (rowData.isNotEmpty) {
      int rowIndex = rowData[0]; // First byte is row number
      if (rowIndex < numRows) {
        for (int c = 0; c < numCols && (c * 2 + 2) < rowData.length; c++) {
          // Reconstruct 12-bit value from two bytes
          int lowByte = rowData[c * 2 + 1];
          int highByte = rowData[c * 2 + 2];
          int pressure = lowByte | (highByte << 8);
          grid[rowIndex][c] = pressure;
        }
      }
    }
  }
  
  return grid;
}


class PressurePainter extends CustomPainter {
  final List<List<int>> grid;
  final int resolution; // Controls smoothness vs performance (higher = faster)
  
  PressurePainter(this.grid, {this.resolution = 8});

  // Bilinear interpolation function
  double interpolatePressure(double x, double y) {
    if (grid.isEmpty || grid[0].isEmpty) return 0.0;
    
    // Clamp coordinates to grid bounds
    x = x.clamp(0.0, grid[0].length - 1.0);
    y = y.clamp(0.0, grid.length - 1.0);
    
    // Get the four surrounding grid points
    int x1 = x.floor();
    int y1 = y.floor();
    int x2 = (x1 + 1).clamp(0, grid[0].length - 1);
    int y2 = (y1 + 1).clamp(0, grid.length - 1);
    
    // Get the fractional parts
    double fx = x - x1;
    double fy = y - y1;
    
    // Get pressure values at the four corners
    double p11 = grid[y1][x1].toDouble();
    double p12 = grid[y2][x1].toDouble();
    double p21 = grid[y1][x2].toDouble();
    double p22 = grid[y2][x2].toDouble();
    
    // Bilinear interpolation
    double p1 = p11 * (1 - fx) + p21 * fx;  // Top edge
    double p2 = p12 * (1 - fx) + p22 * fx;  // Bottom edge
    double interpolated = p1 * (1 - fy) + p2 * fy;
    
    return interpolated;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (grid.isEmpty || grid[0].isEmpty) return;
    
    final paint = Paint();
    
    // Calculate step size based on resolution
    final stepX = resolution.toDouble();
    final stepY = resolution.toDouble();
    
    // Calculate scaling factors
    final scaleX = (grid[0].length - 1) / size.width;
    final scaleY = (grid.length - 1) / size.height;
    
    // Render pixel by pixel with interpolation
    for (double pixelY = 0; pixelY < size.height; pixelY += stepY) {
      for (double pixelX = 0; pixelX < size.width; pixelX += stepX) {
        // Convert pixel coordinates to grid coordinates
        double gridX = pixelX * scaleX;
        double gridY = pixelY * scaleY;
        
        // Get interpolated pressure value
        double pressure = interpolatePressure(gridX, gridY);
        
        // Convert to color
        final normalizedPressure = (pressure / maxPressure).clamp(0.0, 1.0);
        final color = Color.lerp(Colors.blue, Colors.red, normalizedPressure)!;
        paint.color = color;
        
        // Draw a small rectangle for this pixel region
        canvas.drawRect(
          Rect.fromLTWH(pixelX, pixelY, stepX, stepY),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}