import 'dart:convert';

import 'cipher.dart';

class Passage {
  String title;
  String content;
  Passage(this.title, this.content);

  String toBase64() {
    return "${base64.encode(utf8.encode(title))}-${base64.encode(utf8.encode(content))}";
  }
}

Passage? passageFromBase64(String? data) {
  if (data == null) return null;
  final parts = data.split("-");
  if (parts.length != 2) return null;
  final title = utf8.decode(base64.decode(parts[0]));
  final content = utf8.decode(base64.decode(parts[1]));
  return Passage(title, content);
}

class Plaintext {
  int fontSize;
  List<Passage> passages;
  Plaintext(this.passages, {this.fontSize = 18});

  Future<String?> encrypt(String? password) async {
    final plaintext =
        passages.map((p) => p.toBase64()).join("|") + ":FontSize=$fontSize";
    return enc(plaintext, password);
  }
}

Future<Plaintext?> fromCiphertext(String? ciphertext, String? password) async {
  if (ciphertext == null || password == null) {
    print("ciphertext or password is null");
    return null;
  }
  final plaintext = await dec(ciphertext, password);
  if (plaintext == null) return null;
  final bodyAndMeta = plaintext.split(":");
  final body = bodyAndMeta[0];
  final passageEncodes = body.split("|");
  List<Passage> passages = [];
  for (String e in passageEncodes) {
    final passage = passageFromBase64(e);
    if (passage == null) {
      print("Invalid passage encoding");
      print(e);
      return null;
    }
    passages.add(passage);
  }
  int? fontSize;
  for (int i = 1; i < bodyAndMeta.length; i++) {
    final metaData = bodyAndMeta[i].split("=");
    if (metaData.length != 2) {
      continue;
    }
    if (metaData[0] == "FontSize") {
      fontSize = int.tryParse(metaData[1]);
    }
  }
  return Plaintext(passages, fontSize: fontSize ?? 18);
}
