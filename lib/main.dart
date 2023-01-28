import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:hash/hash.dart';
import 'package:convert/convert.dart';
import 'package:flutter_document_picker/flutter_document_picker.dart';
import 'package:safe_write/write_pad.dart';
import 'settings.dart';
import 'passage.dart';
import 'page_split.dart';

import 'dart:io';
import 'dart:convert';
import 'dart:math';

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
      home: _SafeReader(),
    );
  }
}

class _SafeReader extends StatefulWidget {
  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();

    return directory.path;
  }

  Future<File> get _localFile async {
    final path = await _localPath;
    return File('$path/settings.json');
  }

  Future<File> _passageFile(String path) async {
    final localpath = await _localPath;
    path = path.replaceAll("/", "_").replaceAll("\\", "_");
    return File('$localpath/$path');
  }

  Future<File?> write(Settings? settings) async {
    if (settings == null) return null;
    final file = await _localFile;
    return file.writeAsString(json.encode(settings.toJson()));
  }

  Future<Settings> read() async {
    try {
      final file = await _localFile;
      String contents = await file.readAsString();
      return Settings.fromJson(json.decode(contents));
    } catch (e) {
      return Settings([], {}, {}, {});
    }
  }

  Future<File?> writePassage(String path, String content) async {
    final file = await _passageFile(path);
    return file.writeAsString(content);
  }

  Future<String?> readPassage(String path) async {
    try {
      final file = await _passageFile(path);
      return await file.readAsString();
    } catch (e) {
      return null;
    }
  }

  @override
  State<StatefulWidget> createState() {
    return _SafeReaderState();
  }
}

class _SafeReaderState extends State<_SafeReader> {
  Settings settings = Settings([], {}, {}, {});

  @override
  void initState() {
    super.initState();
    () async {
      settings = await widget.read();
      setState(() {});
    }();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Files"),
        actions: [
          PopupMenuButton(
              // add icon, by default "3 dot" icon
              // icon: Icon(Icons.book)
              itemBuilder: (context) {
            return [
              PopupMenuItem<int>(
                value: 0,
                child: Text("Secret Write"),
              ),
            ];
          }, onSelected: (value) {
            if (value == 0) {
              Navigator.push(context, MaterialPageRoute(builder: (context) {
                return WritingPad();
              }));
            }
          }),
        ],
      ),
      backgroundColor: Colors.black,
      body: DefaultTextStyle(
        style: TextStyle(color: Colors.white),
        child: ListView.builder(
            itemCount: settings.files.length + 1,
            itemBuilder: (context, index) {
              if (index < settings.files.length) {
                final path = settings.files[index];
                return GestureDetector(
                  onTap: () async {
                    final s = await widget.readPassage(path);
                    if (s == null) {
                      return;
                    }
                    Navigator.push(context,
                        MaterialPageRoute(builder: (context) {
                      return _LockedReader(
                        path: settings.files[index],
                        ciphertext: s,
                        name: basenameWithoutExtension(settings.files[index]),
                        locations: settings.locations,
                        pageBreaks: settings.pageBreaks,
                        chapters: settings.passages,
                        onWrite: () {
                          widget.write(settings);
                        },
                      );
                    }));
                  },
                  child: ListTile(
                    title: Text(basenameWithoutExtension(path),
                        style: TextStyle(color: Colors.white)),
                    subtitle: Text(path, style: TextStyle(color: Colors.white)),
                    trailing: IconButton(
                        iconSize: 14,
                        onPressed: () {
                          settings.files.removeAt(index);
                          widget.write(settings);
                          setState(() {});
                        },
                        icon: Icon(Icons.delete, color: Colors.white)),
                  ),
                );
              } else
                return Container(
                    height: 30,
                    child: Center(
                        child: IconButton(
                            color: Colors.blue,
                            icon: Icon(Icons.add),
                            onPressed: () async {
                              // This path is only a temporary path, not the
                              // real path to the file. Should copy the content
                              // of this file and store it in the space of this
                              // app.
                              final path =
                                  await FlutterDocumentPicker.openDocument();
                              if (path == null) return;
                              final file = File(path);
                              final s = await file.readAsString();
                              widget.writePassage(path, s);
                              setState(() {
                                settings.files.add(path);
                                widget.write(settings);
                              });
                            })));
            }),
      ),
    );
  }
}

class _LockedReader extends StatefulWidget {
  final String path;
  final String ciphertext;
  final String name;
  final Map<String, int> locations;
  final Map<String, List<int>> pageBreaks;
  final Map<String, int> chapters;
  final VoidCallback onWrite;

  _LockedReader(
      {Key? key,
      required this.path,
      required this.ciphertext,
      required this.name,
      required this.locations,
      required this.pageBreaks,
      required this.chapters,
      required this.onWrite})
      : super(key: key);

  @override
  _LockedReaderState createState() => _LockedReaderState();
}

class _LockedReaderState extends State<_LockedReader> {
  TextEditingController? _passwordController;
  String? errorText;

  @override
  void initState() {
    super.initState();
    _passwordController = TextEditingController();
    _passwordController?.addListener(() {
      setState(() {
        errorText = null;
      });
    });
  }

  @override
  void dispose() {
    _passwordController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black,
      child: Center(
          child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.lock, color: Colors.blue, size: 32),
          Text(widget.name, style: TextStyle(color: Colors.white)),
          Container(
              width: 300,
              child: TextField(
                controller: _passwordController,
                obscureText: true,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: "Password",
                  errorText: errorText,
                ),
              )),
          OutlinedButton(
            child: Text("Open"),
            onPressed: () async {
              final plaintext = await fromCiphertext(
                  widget.ciphertext, _passwordController?.text);
              if (plaintext == null) {
                setState(() {
                  errorText = "Wrong password";
                });
                return;
              }
              _passwordController?.text = "";
              Navigator.push(context, MaterialPageRoute(builder: (context) {
                return _Reader(
                  path: widget.path,
                  plaintext: plaintext,
                  locations: widget.locations,
                  pageBreaks: widget.pageBreaks,
                  passages: widget.chapters,
                  onWrite: widget.onWrite,
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height,
                );
              }));
            },
          )
        ],
      )),
    );
  }
}

class _Reader extends StatefulWidget {
  final String path;
  final Plaintext plaintext;
  final Map<String, int> locations;
  final Map<String, List<int>> pageBreaks;
  final Map<String, int> passages;
  final VoidCallback onWrite;
  final TextStyle _style = TextStyle(fontSize: 18, color: Colors.white);
  final double width;
  final double height;
  final double textWidth;
  final double textHeight;

  _Reader(
      {Key? key,
      double padding = 50,
      required this.path,
      required this.plaintext,
      required this.locations,
      required this.pageBreaks,
      required this.passages,
      required this.onWrite,
      required this.width,
      required this.height})
      : textWidth = width - padding,
        textHeight = height - padding,
        super(key: key);

  @override
  _ReaderState createState() => _ReaderState();
}

class _ReaderState extends State<_Reader> {
  int _passage = 0;
  int _start = 0;
  int _end = 0;
  List<int> _pageIndices = [];
  final List<List<int>> _pageStartPositions = [];
  final List<String> _runes = [];

  void _updateStartEnd() {
    final pageIndex = _pageIndices[_passage];
    _start = _pageStartPositions[_passage][pageIndex];
    _end = pageIndex + 1 >= _pageStartPositions[_passage].length
        ? widget.plaintext.passages[_passage].content.runes.length
        : _pageStartPositions[_passage][pageIndex + 1];
  }

  void _saveProgress() {
    widget.locations["${widget.path}/$_passage"] =
        _pageStartPositions[_passage][_pageIndices[_passage]];
    widget.passages[widget.path] = _passage;
    widget.onWrite();
  }

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < widget.plaintext.passages.length; i++) {
      // _runes.add(widget.plaintext.passages[i].content.runes.toList());
      _runes.add(widget.plaintext.passages[i].content);
      var md5 =
          MD5().update(widget.plaintext.passages[i].content.codeUnits).digest();
      String key = hex.encode(md5);
      List<int>? pageBreaks;
      if (widget.pageBreaks.containsKey(key)) {
        pageBreaks = widget.pageBreaks[key];
      } else {
        pageBreaks = _breakPages(_runes[i]);
        widget.pageBreaks[key] = pageBreaks;
        widget.onWrite();
      }
      _pageStartPositions.add(pageBreaks!);
    }
    _pageIndices = [];
    _passage = widget.passages[widget.path] ?? 0;
    for (int i = 0; i < widget.plaintext.passages.length; i++) {
      int position = widget.locations["${widget.path}/$i"] ?? 0;
      int _pageIndex = locatePage(i, position) ?? 0;
      _pageIndices.add(_pageIndex);
    }
    _updateStartEnd();
  }

  List<int> _breakPages(String text) {
    return getSplittedText(
        Size(widget.textWidth, widget.textHeight - 20), widget._style, text);
  }

  int? locatePage(int passage, int position) {
    if (passage < 0 || passage >= widget.plaintext.passages.length) return null;
    final pageStartPositions = _pageStartPositions[passage];
    for (int i = 0; i < pageStartPositions.length - 1; i++) {
      if (position < pageStartPositions[i + 1]) return i;
    }
    return pageStartPositions.length - 1;
  }

  @override
  Widget build(BuildContext context) {
    return Material(
        child: Stack(
      children: [
        Container(color: Colors.black),
        Center(
          child: Container(
              width: widget.textWidth,
              height: widget.textHeight,
              child: Text(
                  widget.plaintext.passages[_passage].content.runes
                      .toList()
                      .sublist(_start, _end)
                      .map((rune) => String.fromCharCode(rune))
                      .join(),
                  style: widget._style)),
        ),
        Row(
          children: [
            GestureDetector(
              onTap: () {
                if (_pageIndices[_passage] > 0) {
                  _pageIndices[_passage] -= 1;
                } else if (_passage > 0) {
                  _passage -= 1;
                  _pageIndices[_passage] =
                      _pageStartPositions[_passage].length - 1;
                }
                setState(() {
                  _updateStartEnd();
                  _saveProgress();
                });
              },
              child: Container(
                  width: widget.width / 4,
                  color: Colors.white.withAlpha(0),
                  height: widget.height),
            ),
            GestureDetector(
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) {
                  return _ProgressController(
                      plaintext: widget.plaintext,
                      passage: _passage,
                      pageIndices: _pageIndices,
                      maxPages:
                          _pageStartPositions.map((e) => e.length).toList(),
                      maxPositions: widget.plaintext.passages
                          .map((e) => e.content.runes.length)
                          .toList(),
                      setPassage: (passage) {
                        setState(() {
                          _passage = passage;
                          _updateStartEnd();
                          _saveProgress();
                        });
                      },
                      locatePage: locatePage,
                      pageLocation: (passage, page) =>
                          _pageStartPositions[passage][page]);
                }));
              },
              child: Container(
                  width: widget.width / 2,
                  color: Colors.white.withAlpha(0),
                  height: widget.height),
            ),
            GestureDetector(
              onTap: () {
                if (_pageIndices[_passage] <
                    _pageStartPositions[_passage].length - 1) {
                  _pageIndices[_passage] += 1;
                } else if (_passage < _pageIndices.length - 1) {
                  _passage += 1;
                  _pageIndices[_passage] = 0;
                }
                setState(() {
                  _updateStartEnd();
                  _saveProgress();
                });
              },
              child: Container(
                  width: widget.width / 4,
                  color: Colors.white.withAlpha(0),
                  height: widget.height),
            ),
          ],
        ),
      ],
    ));
  }
}

class _ProgressController extends StatefulWidget {
  final Plaintext plaintext;
  final int passage;
  final List<int> pageIndices;
  final List<int> maxPages;
  final List<int> maxPositions;
  final void Function(int) setPassage;
  final int? Function(int, int) locatePage;
  final int? Function(int, int) pageLocation;

  _ProgressController(
      {Key? key,
      required this.plaintext,
      required this.passage,
      required this.pageIndices,
      required this.maxPages,
      required this.maxPositions,
      required this.setPassage,
      required this.locatePage,
      required this.pageLocation})
      : super(key: key);

  @override
  _ProgressControllerState createState() => _ProgressControllerState();
}

class _ProgressControllerState extends State<_ProgressController> {
  int passage = 0;
  int pageIndex = 0;
  bool validNumber = true;
  TextEditingController? _pageController;

  @override
  void initState() {
    super.initState();
    passage = widget.passage;
    onChangePassage();
    _pageController = TextEditingController();
  }

  @override
  void dispose() {
    _pageController?.dispose();
    super.dispose();
  }

  void onChangePassage() {
    pageIndex = widget.pageIndices[passage];
  }

  @override
  Widget build(BuildContext context) {
    final dropdownMenuItems = <DropdownMenuItem<int>>[];
    for (int i = 0; i < widget.plaintext.passages.length; i++) {
      dropdownMenuItems.add(DropdownMenuItem(
          child: Container(
            color: Colors.black,
            child: Text(widget.plaintext.passages[i].title,
                style: TextStyle(color: Colors.white)),
          ),
          value: i));
    }
    return Scaffold(
      appBar: AppBar(title: Text("Progress")),
      backgroundColor: Colors.black,
      body: Container(
        padding: const EdgeInsets.all(8.0),
        child: DefaultTextStyle(
          style: TextStyle(color: Colors.white),
          child: Container(
            padding: EdgeInsets.only(left: 20, right: 20, top: 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Expanded(
                      child: Text("Passage:",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    DropdownButton(
                      value: passage,
                      dropdownColor: Colors.black,
                      items: dropdownMenuItems,
                      onChanged: (value) {
                        setState(() {
                          passage = value as int;
                          onChangePassage();
                        });
                        SchedulerBinding.instance
                            .addPostFrameCallback((timeStamp) {
                          _pageController?.text = (pageIndex + 1).toString();
                        });
                      },
                    ),
                  ],
                ),
                Row(mainAxisSize: MainAxisSize.min, children: [
                  Expanded(
                    child: Text("Page:",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  Counter(
                      value: pageIndex,
                      minValue: 0,
                      maxValue: widget.maxPages[passage] - 1,
                      controller: _pageController,
                      onChange: (value, valid) {
                        setState(() {
                          if (valid) {
                            pageIndex = value;
                          }
                          validNumber = valid;
                        });
                      }),
                  TextButton(
                      onPressed: () {
                        Navigator.push(context,
                            MaterialPageRoute(builder: (context) {
                          return _PositionSelector(
                              initialValue:
                                  widget.pageLocation(passage, pageIndex) ?? 0,
                              maxValue: widget.maxPositions[passage],
                              onReturn: (value) {
                                setState(() {
                                  pageIndex =
                                      widget.locatePage(passage, value) ??
                                          pageIndex;
                                  _pageController?.text =
                                      (pageIndex + 1).toString();
                                });
                              });
                        }));
                      },
                      child: Text("From Position")),
                ]),
                Container(height: 30),
                Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Expanded(child: Container()),
                      OutlinedButton(
                          onPressed: validNumber
                              ? () {
                                  widget.pageIndices[passage] = pageIndex;
                                  widget.setPassage(passage);
                                  Navigator.of(context).pop();
                                }
                              : null,
                          child: Text("OK")),
                      OutlinedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: Text("Cancel")),
                    ])
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PositionSelector extends StatefulWidget {
  final int initialValue;
  final int maxValue;
  final void Function(int) onReturn;

  _PositionSelector(
      {Key? key,
      required this.initialValue,
      required this.maxValue,
      required this.onReturn})
      : super(key: key);

  @override
  _PositionSelectorState createState() => _PositionSelectorState();
}

class _PositionSelectorState extends State<_PositionSelector> {
  bool _valid = true;
  int _value = 0;
  TextEditingController? _positionController;

  @override
  void initState() {
    super.initState();
    _value = widget.initialValue;
    _positionController = TextEditingController();
  }

  @override
  void dispose() {
    _positionController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Counter(
                value: widget.initialValue,
                minValue: 0,
                maxValue: widget.maxValue,
                controller: _positionController,
                onChange: (value, valid) {
                  setState(() {
                    _value = value;
                    _valid = valid;
                  });
                }),
            Container(height: 30),
            Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Expanded(child: Container()),
                  OutlinedButton(
                      onPressed: _valid
                          ? () {
                              widget.onReturn(_value);
                              Navigator.of(context).pop();
                            }
                          : null,
                      child: Text("OK")),
                  OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: Text("Cancel")),
                ])
          ],
        ),
      ),
    );
  }
}

class Counter extends StatefulWidget {
  final int value;
  final int minValue;
  final int maxValue;
  final void Function(int, bool) onChange;
  final TextEditingController? controller;

  Counter(
      {Key? key,
      this.value = 0,
      required this.minValue,
      required this.maxValue,
      required this.onChange,
      required this.controller})
      : super(key: key);

  @override
  _CounterState createState() => _CounterState();
}

class _CounterState extends State<Counter> {
  int _value = 0;
  bool _isValid = true;
  TextEditingController? _valueController;

  void _controllerListener() {
    int? readValue = int.tryParse(_valueController?.text ?? "");
    if (readValue == null) {
      _isValid = false;
      widget.onChange(_value, _isValid);
      return;
    }
    int newValue = readValue - 1;
    if (newValue < widget.minValue) {
      _isValid = false;
    } else if (newValue > widget.maxValue) {
      _isValid = false;
    } else {
      _value = newValue;
      _isValid = true;
    }
    widget.onChange(_value, _isValid);
  }

  @override
  void initState() {
    super.initState();
    _value = widget.value;
    _valueController = widget.controller;
    _isValid = _value >= widget.minValue && _value <= widget.maxValue;
    _valueController?.text = (_value + 1).toString();
    _valueController?.addListener(_controllerListener);
  }

  @override
  void dispose() {
    _valueController?.removeListener(_controllerListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      IconButton(
          icon: Icon(Icons.horizontal_rule),
          iconSize: 20,
          color: Colors.white,
          onPressed: () {
            setState(() {
              _value = max(widget.minValue, _value - 1);
              _valueController?.text = (_value + 1).toString();
            });
          }),
      Container(
          width: 100,
          child: TextField(
            controller: _valueController,
            keyboardType: TextInputType.number,
            style: TextStyle(color: Colors.white),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r"\d+"))
            ],
            decoration: InputDecoration(
              border: OutlineInputBorder(),
            ),
          )),
      Text("/${widget.maxValue + 1}"),
      IconButton(
          icon: Icon(Icons.add),
          iconSize: 20,
          color: Colors.white,
          onPressed: () {
            setState(() {
              _value = min(widget.maxValue, _value + 1);
              _valueController?.text = (_value + 1).toString();
            });
          }),
    ]);
  }
}
