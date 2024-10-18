import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:vector_math/vector_math.dart' as v;



void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {

  const MyApp({super.key});

  @override
  State<StatefulWidget> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with SingleTickerProviderStateMixin {
  late WorldEngine engine;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: true,
      home: Column(
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                engine = WorldEngine.generic(constraints.biggest);
                Future.delayed(const Duration(milliseconds: 100), engine.run);
                return GestureDetector(
                  onTap: () => print("do what you want"),
                  child: CustomPaint(
                    size: Size.infinite,
                    willChange: true,
                    isComplex: true,
                    painter: WorldPainter(model: engine.worldModel),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(32),
            child: ElevatedButton(
              child: const Text("push"),
              onPressed: () => engine.push(0.1),
            ),
          )
        ],
      ),
    );
  }

  @override
  void dispose() {
    engine.dispose();
    super.dispose();
  }
}

class WorldEngine {
  Pendulum worldModel;

  Size layoutSize;
  bool isRunning;
  late Duration currentTime;

  Timer? timer;
  // WorldPainter painter;

  WorldEngine(
    this.layoutSize, {
    this.isRunning = false,
    required this.worldModel,
  });

  factory WorldEngine.generic(Size size) {
    final worldModel = Pendulum(
      angle: math.pi / 3,
      radius: 200,
      pos: v.Vector2(0, 0),
    );
    return WorldEngine(size, worldModel: worldModel);
  }

  void run() {
    if (isRunning) {
      return;
    }
    isRunning = true;
    currentTime = Duration.zero;
    timer = Timer.periodic(const Duration(milliseconds: 10), (_) {
      currentTime += const Duration(milliseconds: 10);
      worldModel.moveTime(0.01);
      worldModel.notify();
    });
  }

  void dispose() {
    timer?.cancel();
  }

  void push(double a) => worldModel.push(a);
}

class WorldPainter extends CustomPainter {
  Pendulum model;

  final whitePainter = Paint()
    ..style = PaintingStyle.fill
    ..color = Colors.white
    ..strokeWidth = 1
    ..isAntiAlias = true;

  WorldPainter({required this.model}) : super(repaint: model);

  double convertRadiusToSigma(double radius) => radius * 0.57735 + 0.5;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(size.width / 2, model.radius);
    canvas.drawLine(const Offset(0, 0), model.offset, whitePainter);
    canvas.drawCircle(model.offset, 20, whitePainter);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant WorldPainter oldDelegate) => false;
}

// this is just a simplified value for gravity
const G = 0.4;

// This class is the model of the pendulum
// It contains all the information about the pendulum
// and physics calculations
// movement is based on the time, angle, mass, acceleration...
class Pendulum extends ChangeNotifier {
  double radius;
  double angle;
  double aVelocity;
  double aAcceleration;

  double time;
  double mass;
  double damping; // Arbitrary damping amount

  v.Vector2 pos;

  Pendulum({
    this.time = 0,
    required this.radius,
    this.angle = 0,
    this.damping = 0.995,
    required this.pos,
    this.aAcceleration = 0,
    this.aVelocity = 0,
    this.mass = 0,
  });

  void moveTime(double time) {
    this.time += time;

    aAcceleration += (-1 * G * math.sin(angle)) / radius;
    aVelocity += aAcceleration;
    angle += aVelocity;
    aVelocity *= damping;
    aAcceleration = 0;
  }

  void push(double a) {
    if (math.sin(angle) < 0) {
      aAcceleration = -a;
    } else {
      aAcceleration = a;
    }
  }

  double get angularAcceleration => math.sin(angle) * G;

  Offset get offset => Offset(
        -1 * radius * math.cos(angle - math.pi / 2),
        -1 * radius * math.sin(angle - math.pi / 2),
      );

  void notify() {
    notifyListeners();
  }
}
