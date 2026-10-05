import 'package:flutter/material.dart';
import 'package:flutter_application_1/l10n/l10n.dart';

class CommentText extends StatefulWidget {
  const CommentText({super.key, required this.comment});

  final String comment;

  @override
  State<CommentText> createState() => _CommentTextState();
}

class _CommentTextState extends State<CommentText> {
  bool _expanded = false;

  String get _moreText => context.l10n.commentMore;

  final TextStyle _textStyle = TextStyle(
    color: Colors.grey.shade800,
    height: 1.5,
  );

  @override
  Widget build(BuildContext context) {
    if (_expanded) {
      return GestureDetector(
        onTap: () {
          setState(() {
            _expanded = false;
          });
        },
        child: Text.rich(
          TextSpan(
            children: [
              TextSpan(text: widget.comment, style: _textStyle),
              TextSpan(
                text: context.l10n.commentLess,
                style: TextStyle(
                  color: Colors.blue.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final result = _createPreview(widget.comment, constraints.maxWidth);

        // ไม่เกิน 3 บรรทัด
        if (!result.hasMore) {
          return Text(widget.comment, style: _textStyle);
        }

        return GestureDetector(
          onTap: () {
            setState(() {
              _expanded = true;
            });
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                result.line1,
                maxLines: 1,
                softWrap: false,
                style: _textStyle,
              ),
              Text(
                result.line2,
                maxLines: 1,
                softWrap: false,
                style: _textStyle,
              ),

              // บรรทัดที่ 3
              // ข้อความ + ...เพิ่มเติม อยู่ใน Text เดียว
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: result.line3, style: _textStyle),
                    TextSpan(text: _moreText, style: _textStyle),
                  ],
                ),
                softWrap: false,
              ),
            ],
          ),
        );
      },
    );
  }

  _PreviewResult _createPreview(String text, double maxWidth) {
    // หา line 1
    final line1 = _fitLine(text, _textStyle, maxWidth);

    final remaining1 = text.substring(line1.length).trimLeft();

    if (remaining1.isEmpty) {
      return _PreviewResult(line1: line1, line2: '', line3: '', hasMore: false);
    }

    // หา line 2
    final line2 = _fitLine(remaining1, _textStyle, maxWidth);

    final remaining2 = remaining1.substring(line2.length).trimLeft();

    if (remaining2.isEmpty) {
      return _PreviewResult(
        line1: line1,
        line2: line2,
        line3: '',
        hasMore: false,
      );
    }

    // สำคัญที่สุด:
    // หา line 3 โดย "จองพื้นที่ ...เพิ่มเติม" ก่อน
    final line3 = _fitLineForMore(remaining2, _textStyle, maxWidth);

    return _PreviewResult(
      line1: line1,
      line2: line2,
      line3: line3,
      hasMore: true,
    );
  }

  String _fitLine(String text, TextStyle style, double maxWidth) {
    int low = 0;
    int high = text.length;

    while (low < high) {
      final mid = (low + high + 1) ~/ 2;

      final value = text.substring(0, mid);

      final painter = TextPainter(
        text: TextSpan(text: value, style: style),
        textDirection: TextDirection.ltr,
      )..layout();

      if (painter.width <= maxWidth) {
        low = mid;
      } else {
        high = mid - 1;
      }
    }

    return text.substring(0, low).trimRight();
  }

  String _fitLineForMore(String text, TextStyle style, double maxWidth) {
    int low = 0;
    int high = text.length;

    while (low < high) {
      final mid = (low + high + 1) ~/ 2;

      final value = text.substring(0, mid).trimRight();

      // วัด "ข้อความ + ...เพิ่มเติม" ด้วยกัน
      final painter = TextPainter(
        text: TextSpan(
          children: [
            TextSpan(text: value, style: style),
            TextSpan(text: _moreText, style: style),
          ],
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      // ต้องพอดีในความกว้างบรรทัดเดียว
      if (painter.width <= maxWidth) {
        low = mid;
      } else {
        high = mid - 1;
      }
    }

    return text.substring(0, low).trimRight();
  }
}

class _PreviewResult {
  const _PreviewResult({
    required this.line1,
    required this.line2,
    required this.line3,
    required this.hasMore,
  });

  final String line1;
  final String line2;
  final String line3;
  final bool hasMore;
}
