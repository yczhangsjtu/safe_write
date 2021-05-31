import 'package:path_provider/path_provider.dart';
import 'package:clipboard/clipboard.dart';
import 'package:flutter/material.dart';

import 'dart:io';
import 'cipher.dart';

class WritingPad extends StatefulWidget {
  @override
  _WritingPadState createState() => _WritingPadState();
}

class _WritingPadState extends State<WritingPad> {
  String? _ciphertext = "";
  PageController? _pageController;
  TextEditingController? _plaintextController;
  TextEditingController? _passwordController;
  bool _enabled = false;
  int _page = 0;

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();

    return directory.path;
  }

  Future<File> get _localFile async {
    final path = await _localPath;
    return File('$path/ciphertext.txt');
  }

  Future<File?> write(String? text) async {
    if (text == null) return null;
    final file = await _localFile;
    return file.writeAsString(text);
  }

  Future<String?> read() async {
    try {
      final file = await _localFile;
      String contents = await file.readAsString();
      return contents;
    } catch (e) {
      return null;
    }
  }

  void _initCiphertext() async {
    _ciphertext = await read() ?? "";
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _plaintextController = TextEditingController();
    _passwordController = TextEditingController();
    _initCiphertext();

    _passwordController?.addListener(() async {
      final pt = await dec(_ciphertext, _passwordController?.text);
      if (pt != null) {
        _plaintextController?.text = pt;
      }
      setState(() {
        _enabled = pt != null;
      });
    });

    _pageController?.addListener(() {
      setState(() {
        _page = _pageController?.page?.round() ?? 0;
      });
    });
  }

  @override
  void dispose() {
    _pageController?.dispose();
    _plaintextController?.dispose();
    _passwordController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Safe Write'),
      ),
      body: DefaultTextStyle(
        style: TextStyle(color: Colors.black, fontSize: 18),
        child: PageView(controller: this._pageController, children: [
          _CiphertextPage(
            passwordController: _passwordController,
            ciphertext: _ciphertext,
          ),
          _PlainTextPage(
            plaintextController: _plaintextController,
            enabled: _enabled,
          ),
        ]),
      ),
      floatingActionButton: FloatingActionButton(
        child: Text(_page > 0.5 ? "E" : "D"),
        onPressed: _enabled
            ? () async {
          if (_page > 0.5) {
            _ciphertext = await enc(
                _plaintextController?.text, _passwordController?.text);
            write(_ciphertext);
            setState(() {});
          } else {
            final plaintext = await dec(_ciphertext, _passwordController?.text);
            if(_plaintextController != null) {
              _plaintextController!.text = plaintext ?? _plaintextController!.text;
            }
          }
        }
            : null,
        backgroundColor: _enabled
            ? Theme.of(context).primaryColor
            : Theme.of(context).disabledColor,
      ),
    );
  }
}

class _PlainTextPage extends StatefulWidget {
  final TextEditingController? plaintextController;
  final bool enabled;

  _PlainTextPage({Key? key, this.plaintextController, this.enabled = false})
      : super(key: key);

  @override
  State createState() {
    return _PlainTextPageState();
  }
}

class _PlainTextPageState extends State<_PlainTextPage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          Expanded(
            child: TextField(
                enabled: widget.enabled,
                controller: widget.plaintextController,
                decoration: null,
                maxLines: null),
          ),
          Row(children: [
            OutlinedButton(
              onPressed: widget.enabled
                  ? () {
                widget.plaintextController?.text = "";
              }
                  : null,
              child: Text("Clear"),
            )
          ])
        ],
      ),
    );
  }
}

class _CiphertextPage extends StatefulWidget {
  final TextEditingController? passwordController;
  final String? ciphertext;

  _CiphertextPage({Key? key, this.passwordController, this.ciphertext})
      : super(key: key);

  @override
  State createState() {
    return _CiphertextPageState();
  }
}

class _CiphertextPageState extends State<_CiphertextPage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: widget.passwordController,
                  decoration: InputDecoration(
                    hintText: "Password",
                  ),
                  obscureText: true,
                ),
              ),
              IconButton(
                  icon: Icon(Icons.file_copy),
                  onPressed: () =>
                      FlutterClipboard.copy(widget.ciphertext ?? ""))
            ],
          ),
          Container(height: 10),
          Expanded(child: ListView(children: [Text(widget.ciphertext ?? "")]))
        ],
      ),
    );
  }
}
