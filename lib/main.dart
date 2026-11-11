import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Pomodoro Timer',
      debugShowCheckedModeBanner: false,
      home: PomodoroPage(),
    );
  }
}

class PomodoroPage extends StatefulWidget {
  const PomodoroPage({super.key});

  @override
  State<PomodoroPage> createState() => _PomodoroPageState();
}

class _PomodoroPageState extends State<PomodoroPage> {
  // settings (in minutes)
  int focusMin = 25;
  int shortMin = 5;
  int longMin = 15;
  int totalRounds = 8;
  int longEvery = 4;

  // phase: 0 = focus, 1 = short break, 2 = long break
  int phase = 0;
  int round = 1;
  int remaining = 25 * 60;
  bool running = false;
  bool finished = false;
  Timer? timer;

  // how many seconds the current phase has
  int getSeconds() {
    if (phase == 0) return focusMin * 60;
    if (phase == 1) return shortMin * 60;
    return longMin * 60;
  }

  // go to the next session
  void nextSession() {
    if (phase == 0) {
      if (round >= totalRounds) {
        // all rounds done
        finished = true;
        running = false;
        timer?.cancel();
        remaining = 0;
        return;
      }
      if (round % longEvery == 0) {
        phase = 2;
      } else {
        phase = 1;
      }
    } else {
      round++;
      phase = 0;
    }
    remaining = getSeconds();
  }

  // play beep sound 3 times
  void playSound() async {
    for (int i = 0; i < 3; i++) {
      SystemSound.play(SystemSoundType.alert);
      await Future.delayed(const Duration(milliseconds: 350));
    }
  }

  void start() {
    if (running || finished) return;
    setState(() {
      running = true;
    });
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() {
        remaining--;
        if (remaining <= 0) {
          nextSession();
          playSound();
        }
      });
    });
  }

  void pause() {
    timer?.cancel();
    setState(() {
      running = false;
    });
  }

  void reset() {
    timer?.cancel();
    setState(() {
      running = false;
      finished = false;
      phase = 0;
      round = 1;
      remaining = getSeconds();
    });
  }

  void skip() {
    setState(() {
      nextSession();
    });
  }

  void openSettings() async {
    final result = await Navigator.push<List<int>>(
      context,
      MaterialPageRoute(
        builder: (context) => SettingsPage(
          focus: focusMin,
          shortBreak: shortMin,
          longBreak: longMin,
          rounds: totalRounds,
          every: longEvery,
        ),
      ),
    );
    if (result == null) return;
    focusMin = result[0];
    shortMin = result[1];
    longMin = result[2];
    totalRounds = result[3];
    longEvery = result[4];
    reset();
  }

  String formatTime(int seconds) {
    String m = (seconds ~/ 60).toString().padLeft(2, '0');
    String s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  String getTitle() {
    if (finished) return 'All rounds completed!';
    if (phase == 0) return 'Focus Time';
    if (phase == 1) return 'Short Break';
    return 'Long Break';
  }

  Color getColor() {
    if (finished) return Colors.grey.shade300;
    if (phase == 0) return Colors.blue.shade100;
    if (phase == 1) return Colors.green.shade100;
    return Colors.purple.shade100;
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // estimated time when this session ends
    final end = DateTime.now().add(Duration(seconds: remaining));
    final endText = TimeOfDay.fromDateTime(end).format(context);

    return Scaffold(
      backgroundColor: getColor(),
      appBar: AppBar(
        title: const Text('Pomodoro Timer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: openSettings,
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(getTitle(), style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 10),
            Text('Round $round of $totalRounds'),
            const SizedBox(height: 20),
            Text(
              formatTime(remaining),
              style: const TextStyle(fontSize: 70, fontWeight: FontWeight.bold),
            ),
            if (!finished)
              Text(
                'Estimated finish: $endText',
                style: const TextStyle(fontSize: 12),
              ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: finished ? null : (running ? pause : start),
                  child: Text(running ? 'Pause' : 'Start'),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: finished ? null : skip,
                  child: const Text('Next'),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: reset,
                  child: const Text('Reset'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class SettingsPage extends StatefulWidget {
  final int focus;
  final int shortBreak;
  final int longBreak;
  final int rounds;
  final int every;

  const SettingsPage({
    super.key,
    required this.focus,
    required this.shortBreak,
    required this.longBreak,
    required this.rounds,
    required this.every,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late int focus;
  late int shortBreak;
  late int longBreak;
  late int rounds;
  late int every;

  @override
  void initState() {
    super.initState();
    focus = widget.focus;
    shortBreak = widget.shortBreak;
    longBreak = widget.longBreak;
    rounds = widget.rounds;
    every = widget.every;
  }

  // one row: label, minus button, number, plus button
  Widget row(String label, int value, int min, int max, Function(int) change) {
    return ListTile(
      title: Text(label),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.remove),
            onPressed: value > min ? () => change(value - 1) : null,
          ),
          Text('$value', style: const TextStyle(fontSize: 18)),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: value < max ? () => change(value + 1) : null,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Presets'),
          const SizedBox(height: 8),
          Row(
            children: [
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    focus = 25;
                    shortBreak = 5;
                    longBreak = 15;
                  });
                },
                child: const Text('Standard 25/5/15'),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    focus = 50;
                    shortBreak = 10;
                    longBreak = 30;
                  });
                },
                child: const Text('Long 50/10/30'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text('Or set your own time below (custom):'),
          row('Focus (min)', focus, 1, 120, (v) => setState(() => focus = v)),
          row('Short break (min)', shortBreak, 1, 60,
              (v) => setState(() => shortBreak = v)),
          row('Long break (min)', longBreak, 1, 120,
              (v) => setState(() => longBreak = v)),
          row('Total rounds', rounds, 1, 20, (v) => setState(() => rounds = v)),
          row('Long break every N rounds', every, 1, 20,
              (v) => setState(() => every = v)),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context, [focus, shortBreak, longBreak, rounds, every]);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}