import 'package:flutter/material.dart';
import 'pressure_readings.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BJJ Choker App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
      ),
      home: const MyHomePage(title: 'BJJ Choker Training App'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late Stream<List<List<int>>> _pressureStream;
  final int _numRows = 3;
  final int _numCols = 16;
  final int _delay = 50;
  int pressureProfileResolution = 8;

  @override
  void initState() {
    super.initState();
    _pressureStream = simulateBleData(_numRows, _numCols, delayInMilis: _delay);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'Real-time Pressure Sensor Data',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: StreamBuilder<List<List<int>>>(
                stream: _pressureStream,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    // Convert the BLE data format to a pressure grid
                    List<List<int>> grid = convertBleDataToGrid(snapshot.data!);
                    return Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CustomPaint(
                          painter: PressurePainter(grid, resolution: pressureProfileResolution),
                          size: Size.infinite,
                        ),
                      ),
                    );
                  } else {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }
                },
              ),
            ),
            const SizedBox(height: 20),
            // Resolution control slider
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      'Pixel Resolution: ${pressureProfileResolution}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 10),
                    Slider(
                      value: pressureProfileResolution.toDouble(),
                      min: 4,
                      max: 24,
                      divisions: 20,
                      label: pressureProfileResolution.toString(),
                      onChanged: (double value) {
                        setState(() {
                          pressureProfileResolution = value.round();
                        });
                      },
                    ),
                    const Text(
                      'Lower values = Higher quality (slower)\nHigher values = Lower quality (faster)',
                      style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Blue = Low Pressure, Red = High Pressure',
              style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }
}
