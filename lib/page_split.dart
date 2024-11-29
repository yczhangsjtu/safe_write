import 'package:flutter/cupertino.dart';

List<int> getSplittedText(Size pageSize, TextStyle textStyle, String text) {
  final List<int> _pageTexts = [];
  final textSpan = TextSpan(text: text, style: textStyle);
  final textPainter = TextPainter(
    text: textSpan,
    textDirection: TextDirection.ltr,
  );
  textPainter.layout(
    minWidth: 0,
    maxWidth: pageSize.width,
  );

  // https://medium.com/swlh/flutter-line-metrics-fd98ab180a64
  List<LineMetrics> lines = textPainter.computeLineMetrics();
  double currentPageBottom = pageSize.height;
  int currentPageStartIndex = 0;
  int currentPageEndIndex = 0;

  for (int i = 0; i < lines.length; i++) {
    final line = lines[i];

    final left = line.left;
    final top = line.baseline - line.ascent;
    final bottom = line.baseline + line.descent;

    // Current line overflow page
    if (currentPageBottom < bottom) {
      // https://stackoverflow.com/questions/56943994/how-to-get-the-raw-text-from-a-flutter-textbox/56943995#56943995
      currentPageEndIndex =
          textPainter.getPositionForOffset(Offset(left, top)).offset;
      _pageTexts.add(currentPageStartIndex);

      currentPageStartIndex = currentPageEndIndex;
      currentPageBottom = top + pageSize.height;
    }
  }

  _pageTexts.add(currentPageStartIndex);
  return _pageTexts;
}
