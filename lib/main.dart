import 'package:flutter/material.dart';
import 'package:cryptography/cryptography.dart';
import 'package:path_provider/path_provider.dart';
import 'package:clipboard/clipboard.dart';

import 'dart:convert';
import 'dart:io';

void main() {
  runApp(Main());
}

class Main extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Safe Write',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MainPage(),
    );
  }
}

class MainPage extends StatefulWidget {
  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  String _ciphertext = "";
  PageController _pageController;
  TextEditingController _plaintextController;
  TextEditingController _passwordController;
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

  Future<File> write(String text) async {
    final file = await _localFile;
    return file.writeAsString(text);
  }

  Future<String> read() async {
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

    _passwordController.addListener(() {
      final pt = _decrypt(_ciphertext, _passwordController.text);
      if (pt != null) {
        _plaintextController.text = pt;
      }
      setState(() {
        _enabled = pt != null;
      });
    });

    _pageController.addListener(() {
      setState(() {
        _page = _pageController.page.round();
      });
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _plaintextController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  SecretKey _keyDerive(String password) {
    final sink = sha256.newSink();
    sink.add(utf8.encode(password));
    sink.close();
    return SecretKey(sink.hash.bytes.sublist(0, 16));
  }

  String _encrypt(String plaintext, String password) {
    if (password.isEmpty) {
      return null;
    }
    final skey = _keyDerive(password);
    final nonce = Nonce.randomBytes(16);
    final data = List<int>.generate(16, (index) => 0);
    data.addAll(utf8.encode(plaintext));
    final ciphertext = aesCbc.encryptSync(data, secretKey: skey, nonce: nonce);
    return base64.encode(nonce.bytes + ciphertext);
  }

  String _decrypt(String ciphertext, String password) {
    if (password.isEmpty) {
      return null;
    }
    if (ciphertext.isEmpty) {
      return "";
    }
    final skey = _keyDerive(password);

    final data = base64.decode(ciphertext);
    if (data.length < 16) {
      return null;
    }

    List<int> plaintext;
    try {
      plaintext = aesCbc.decryptSync(data.sublist(16),
          secretKey: skey, nonce: Nonce(data.sublist(0, 16)));
    } catch (e) {
      return null;
    }

    if (plaintext.length < 16) {
      return null;
    }
    for (var i = 0; i < 16; i++) {
      if (plaintext[i] != 0) return null;
    }
    return utf8.decode(plaintext.sublist(16));
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
            ? () {
                if (_page > 0.5) {
                  setState(() {
                    _ciphertext = _encrypt(
                        _plaintextController.text, _passwordController.text);
                    write(_ciphertext);
                  });
                } else {
                  _plaintextController.text =
                      _decrypt(_ciphertext, _passwordController.text) ??
                          _plaintextController.text;
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
  final TextEditingController plaintextController;
  final bool enabled;

  _PlainTextPage({Key key, this.plaintextController, this.enabled})
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
            OutlineButton(
              onPressed: widget.enabled
                  ? () {
                      widget.plaintextController.text = "";
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
  final TextEditingController passwordController;
  final String ciphertext;

  _CiphertextPage({Key key, this.passwordController, this.ciphertext})
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
                  onPressed: () => FlutterClipboard.copy(widget.ciphertext))
            ],
          ),
          Container(height: 10),
          Expanded(child: ListView(children: [Text(widget.ciphertext)]))
        ],
      ),
    );
  }
}
