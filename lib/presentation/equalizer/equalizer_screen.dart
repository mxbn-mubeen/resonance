import 'package:flutter/material.dart';

/// TODO(equalizer_screen): actual band gain values need a native EQ
/// AudioEffect hooked to PlaybackController's audio session - see the
/// TODO in application/playback/playback_controller.dart.
class EqualizerScreen extends StatefulWidget {
  const EqualizerScreen({super.key});

  @override
  State<EqualizerScreen> createState() => _EqualizerScreenState();
}

class _EqualizerScreenState extends State<EqualizerScreen> {
  static const _bands = ['60Hz', '230Hz', '910Hz', '3kHz', '14kHz'];
  final List<double> _gains = List.filled(_bands.length, 0);
  double _bassBoost = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Equalizer')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Wrap(
            spacing: 8,
            children: ['Flat', 'Bass Boost', 'Vocal', 'Treble Boost', 'Custom']
                .map((preset) => ChoiceChip(label: Text(preset), selected: preset == 'Flat', onSelected: (_) {}))
                .toList(),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(_bands.length, (i) {
              return Column(
                children: [
                  SizedBox(
                    height: 160,
                    child: RotatedBox(
                      quarterTurns: 3,
                      child: Slider(
                        value: _gains[i],
                        min: -12,
                        max: 12,
                        onChanged: (v) => setState(() => _gains[i] = v),
                      ),
                    ),
                  ),
                  Text(_bands[i]),
                ],
              );
            }),
          ),
          const SizedBox(height: 24),
          Text('Bass Boost', style: Theme.of(context).textTheme.titleMedium),
          Slider(
            value: _bassBoost,
            onChanged: (v) => setState(() => _bassBoost = v),
          ),
        ],
      ),
    );
  }
}
