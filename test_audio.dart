import 'package:audioplayers/audioplayers.dart';

void main() {
  final player = AudioPlayer();
  player.audioCache = AudioCache(prefix: 'Assets/');
  print('Done');
}
