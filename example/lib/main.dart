import 'dart:async';

import 'package:flutter_music_player_plugin/flutter_music_player_plugin.dart';
import 'package:flutter/material.dart';

typedef void OnError(Exception exception);
const kUrl = "Any Url Here !";

void main() {
  runApp(new MaterialApp(home: new Scaffold(body: new AudioApp())));
}

enum PlayerState { stopped, playing, paused }

class AudioApp extends StatefulWidget {
  @override
  _AudioAppState createState() => new _AudioAppState();
}

class _AudioAppState extends State<AudioApp> {
   Duration duration= new Duration();
   Duration position=new Duration();

  late MusicFinder audioPlayer;

  String localFilePath="";

  PlayerState playerState = PlayerState.stopped;

  get isPlaying => playerState == PlayerState.playing;
  get isPaused => playerState == PlayerState.paused;

  get durationText => duration.toString().split('.').first;
  get positionText =>position.toString().split('.').first;

  bool isMuted = false;

  @override
  void initState() {
    super.initState();
    initAudioPlayer();
  }

  Future initAudioPlayer() async {
    audioPlayer = new MusicFinder();
    var songs;
    try {
      songs = await MusicFinder.allSongs();
    } catch (e) {
      print(e.toString());
    }

    print(songs);
    audioPlayer.setDurationHandler((d) => setState(() {
          duration = d;
        }));

    audioPlayer.setPositionHandler((p) => setState(() {
          position = p;
        }));

    audioPlayer.setCompletionHandler(() {
      onComplete();
      setState(() {
        position = duration;
      });
    });

    audioPlayer.setErrorHandler((msg) {
      setState(() {
        playerState = PlayerState.stopped;
        duration = new Duration(seconds: 0);
        position = new Duration(seconds: 0);
      });
    });

    setState(() {
      print(songs.toString());
    });
  }

  Future play() async {
    final result = await audioPlayer.play(kUrl);
    if (result == 1)
      setState(() {
        print('_AudioAppState.play... PlayerState.playing');
        playerState = PlayerState.playing;
      });
  }

  Future _playLocal() async {
    final result = await audioPlayer.play(localFilePath, isLocal: true);
    if (result == 1) setState(() => playerState = PlayerState.playing);
  }

  Future pause() async {
    final result = await audioPlayer.pause();
    if (result == 1) setState(() => playerState = PlayerState.paused);
  }

  Future stop() async {
    final result = await audioPlayer.stop();
    if (result == 1)
      setState(() {
        playerState = PlayerState.stopped;
        position = new Duration();
      });
  }

  Future mute(bool muted) async {
    final result = await audioPlayer.mute(muted);
    if (result == 1)
      setState(() {
        isMuted = muted;
      });
  }

  void onComplete() {
    setState(() => playerState = PlayerState.stopped);
  }

  @override
  void dispose() {
    super.dispose();
    audioPlayer.stop();
  }

//  Future<Uint8List> _loadFileBytes(String url, {OnError onError}) async {
//    Uint8List bytes;
//    try {
//      bytes = await readBytes(url);
//    } on ClientException {
//      rethrow;
//    }
//    return bytes;
//  }

  @override
  Widget build(BuildContext context) {
    return new Center(
        child: new Material(
            elevation: 2.0,
            color: Colors.grey[200],
            child: new Center(
              child: new Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    new Material(child: _buildPlayer()), new Text(localFilePath),
                    new Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: new Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            new ElevatedButton(
                              onPressed: () => {},
                              child: new Text('Download'),
                            ),
                            new ElevatedButton(
                              onPressed: () => _playLocal(),
                              child: new Text('play local'),
                            ),
                          ]),
                    )
                  ]),
            )));
  }

  Widget _buildPlayer() => new Container(
      padding: new EdgeInsets.all(16.0),
      child: new Column(mainAxisSize: MainAxisSize.min, children: [
        new Row(mainAxisSize: MainAxisSize.min, children: [
          new IconButton(
              onPressed: isPlaying ? null : () => play(),
              iconSize: 64.0,
              icon: new Icon(Icons.play_arrow),
              color: Colors.cyan),
          new IconButton(
              onPressed: isPlaying ? () => pause() : null,
              iconSize: 64.0,
              icon: new Icon(Icons.pause),
              color: Colors.cyan),
          new IconButton(
              onPressed: isPlaying || isPaused ? () => stop() : null,
              iconSize: 64.0,
              icon: new Icon(Icons.stop),
              color: Colors.cyan),
        ]),
        duration == null
            ? new Container()
            : new Slider(
                value: position?.inMilliseconds?.toDouble() ?? 0,
                onChanged: (double value) =>
                    audioPlayer.seek((value / 1000).roundToDouble()),
                min: 0.0,
                max: duration.inMilliseconds.toDouble()),
        new Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            new IconButton(
                onPressed: () => mute(true),
                icon: new Icon(Icons.headset_off),
                color: Colors.cyan),
            new IconButton(
                onPressed: () => mute(false),
                icon: new Icon(Icons.headset),
                color: Colors.cyan),
          ],
        ),
        new Row(mainAxisSize: MainAxisSize.min, children: [
          new Padding(
              padding: new EdgeInsets.all(12.0),
              child: new Stack(children: [
                new CircularProgressIndicator(
                    value: 1.0,
                    valueColor: new AlwaysStoppedAnimation(Colors.grey[300])),
                new CircularProgressIndicator(
                  value: position != null && position.inMilliseconds > 0
                      ? (position?.inMilliseconds?.toDouble() ?? 0.0) /
                          (duration?.inMilliseconds?.toDouble() ?? 0.0)
                      : 0.0,
                  valueColor: new AlwaysStoppedAnimation(Colors.cyan),
                  backgroundColor: Colors.yellow,
                ),
              ])),
          new Text(
              position != null
                  ? "${positionText ?? ''} / ${durationText ?? ''}"
                  : duration != null ? durationText : '',
              style: new TextStyle(fontSize: 24.0))
        ])
      ]));
}
