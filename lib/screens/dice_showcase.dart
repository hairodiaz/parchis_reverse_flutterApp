import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';

class DiceShowcase extends StatelessWidget {
  const DiceShowcase({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        title: const Text(
          ' Prueba de Animaciones',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF16213E),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            const Text(
              'Presiona cada botón para comparar las animaciones',
              style: TextStyle(color: Colors.white, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Row(
                children: const [
                  Expanded(child: DiceDecelerateBounce()),
                  SizedBox(width: 12),
                  Expanded(child: DiceFlip3D()),
                  SizedBox(width: 12),
                  Expanded(child: DiceRollTranslate()),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class DiceDecelerateBounce extends StatefulWidget {
  const DiceDecelerateBounce({super.key});
  @override
  State<DiceDecelerateBounce> createState() => _DiceDecelerateBounceState();
}

class _DiceDecelerateBounceState extends State<DiceDecelerateBounce> 
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  final Random _rnd = Random();
  int _value = 1;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _roll() {
    _ctrl.reset();
    _ctrl.forward();
    _timer = Timer.periodic(const Duration(milliseconds: 80), (timer) {
      if (!mounted) return timer.cancel();
      setState(() => _value = _rnd.nextInt(6) + 1);
    });
    Timer(const Duration(milliseconds: 2000), () {
      _timer?.cancel();
      if (!mounted) return;
      setState(() => _value = _rnd.nextInt(6) + 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('DESACELERACIÓN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        const SizedBox(height: 15),
        AnimatedBuilder(
          animation: _ctrl,
          builder: (context, child) {
            final double t = Curves.elasticOut.transform(_ctrl.value);
            final double scale = 1.0 + (0.3 * sin(t * pi * 3));
            return Transform.scale(scale: scale, child: _buildDiceWidget(_value, Colors.red));
          },
        ),
        const SizedBox(height: 15),
        ElevatedButton(
          onPressed: _roll,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
          child: const Text('Lanzar A'),
        ),
      ],
    );
  }
}

class DiceFlip3D extends StatefulWidget {
  const DiceFlip3D({super.key});
  @override
  State<DiceFlip3D> createState() => _DiceFlip3DState();
}

class _DiceFlip3DState extends State<DiceFlip3D> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  int _value = 1;
  final Random _rnd = Random();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _roll() {
    _ctrl.reset();
    _ctrl.forward();
    _timer = Timer.periodic(const Duration(milliseconds: 70), (timer) {
      if (!mounted) return timer.cancel();
      setState(() => _value = _rnd.nextInt(6) + 1);
    });
    Timer(const Duration(milliseconds: 2400), () {
      _timer?.cancel();
      if (!mounted) return;
      setState(() => _value = _rnd.nextInt(6) + 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('FLIP 3D', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        const SizedBox(height: 15),
        SizedBox(
          height: 100,
          child: AnimatedBuilder(
            animation: _ctrl,
            builder: (context, child) {
              final double anim = _ctrl.value;
              final double angle = anim * 4.0 * pi;
              final Matrix4 perspective = Matrix4.identity()..setEntry(3, 2, 0.001)..rotateY(angle);
              return Transform(
                transform: perspective,
                alignment: Alignment.center,
                child: _buildDiceWidget(_value, Colors.blue),
              );
            },
          ),
        ),
        const SizedBox(height: 15),
        ElevatedButton(
          onPressed: _roll,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
          child: const Text('Lanzar B'),
        ),
      ],
    );
  }
}

class DiceRollTranslate extends StatefulWidget {
  const DiceRollTranslate({super.key});
  @override
  State<DiceRollTranslate> createState() => _DiceRollTranslateState();
}

class _DiceRollTranslateState extends State<DiceRollTranslate> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  int _value = 1;
  final Random _rnd = Random();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _roll() {
    _ctrl.reset();
    _ctrl.forward();
    _timer = Timer.periodic(const Duration(milliseconds: 90), (timer) {
      if (!mounted) return timer.cancel();
      setState(() => _value = _rnd.nextInt(6) + 1);
    });
    Timer(const Duration(milliseconds: 2200), () {
      _timer?.cancel();
      if (!mounted) return;
      setState(() => _value = _rnd.nextInt(6) + 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('ROLL FÍSICO', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        const SizedBox(height: 15),
        SizedBox(
          height: 100,
          child: AnimatedBuilder(
            animation: _ctrl,
            builder: (context, child) {
              final double t = _ctrl.value;
              final double dx = lerpDouble(-40, 40, Curves.bounceOut.transform(t)) ?? 0.0;
              final double rot = t * 5.0 * pi;
              final double dy = -25 * sin(t * pi);
              return Transform.translate(
                offset: Offset(dx, dy),
                child: Transform.rotate(angle: rot, child: _buildDiceWidget(_value, Colors.green)),
              );
            },
          ),
        ),
        const SizedBox(height: 15),
        ElevatedButton(
          onPressed: _roll,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
          child: const Text('Lanzar C'),
        ),
      ],
    );
  }
}

Widget _buildDiceWidget(int value, Color color) {
  return Container(
    width: 80, height: 80,
    decoration: BoxDecoration(
      color: color, borderRadius: BorderRadius.circular(12),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))],
      border: Border.all(color: Colors.white, width: 2),
    ),
    alignment: Alignment.center,
    child: Text('', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
  );
}
