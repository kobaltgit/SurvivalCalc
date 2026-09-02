import 'package:flutter/material.dart';
import 'package:survival_calc/core/theme/outdoor_theme.dart';
import 'package:survival_calc/features/wiki/presentation/widgets/wiki_callout_box.dart';

class WikiMarkdownViewer extends StatelessWidget {
  final String markdown;

  const WikiMarkdownViewer({
    super.key,
    required this.markdown,
  });

  @override
  Widget build(BuildContext context) {
    final lines = markdown.split('\n');
    final widgets = <Widget>[];

    int i = 0;
    while (i < lines.length) {
      final line = lines[i].trimRight();

      if (line.trim().isEmpty) {
        widgets.add(const SizedBox(height: 8));
        i++;
        continue;
      }

      // 1. Horizontal Rule (---)
      if (line.trim() == '---' || line.trim() == '***') {
        widgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Divider(color: Colors.white.withValues(alpha: 0.15), height: 1),
          ),
        );
        i++;
        continue;
      }

      // 2. Blockquote / Callout (> ...)
      if (line.startsWith('>')) {
        final quoteLines = <String>[];
        while (i < lines.length && lines[i].trim().startsWith('>')) {
          quoteLines.add(lines[i].trim().substring(1).trim());
          i++;
        }
        final quoteText = quoteLines.join('\n');
        
        CalloutType type = CalloutType.tip;
        String title = 'Совет эксперта';

        if (quoteText.contains('💡') || quoteText.toLowerCase().contains('совет')) {
          type = CalloutType.tip;
          title = '💡 Совет бывалого';
        } else if (quoteText.contains('⚠️') || quoteText.toLowerCase().contains('важно') || quoteText.toLowerCase().contains('внимание')) {
          type = CalloutType.warning;
          title = '⚠️ Важно для безопасности';
        } else if (quoteText.contains('📐') || quoteText.toLowerCase().contains('формул')) {
          type = CalloutType.formula;
          title = '📐 Расчетная формула';
        } else if (quoteText.contains('🧪') || quoteText.toLowerCase().contains('физиолог')) {
          type = CalloutType.physiology;
          title = '🧪 Физиология и метаболизм';
        }

        widgets.add(
          WikiCalloutBox(
            title: title,
            content: quoteText.replaceAll('**', ''),
            type: type,
          ),
        );
        continue;
      }

      // 3. Headings (#, ##, ###)
      if (line.startsWith('# ')) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 18, bottom: 8),
            child: Text(
              line.substring(2).trim(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                height: 1.25,
                letterSpacing: -0.5,
              ),
            ),
          ),
        );
        i++;
        continue;
      }

      if (line.startsWith('## ')) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 8),
            child: Text(
              line.substring(3).trim(),
              style: const TextStyle(
                color: OutdoorTheme.signalOrange,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                height: 1.3,
              ),
            ),
          ),
        );
        i++;
        continue;
      }

      if (line.startsWith('### ')) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 14, bottom: 6),
            child: Text(
              line.substring(4).trim(),
              style: const TextStyle(
                color: Colors.cyanAccent,
                fontSize: 15,
                fontWeight: FontWeight.bold,
                height: 1.3,
              ),
            ),
          ),
        );
        i++;
        continue;
      }

      // 4. Markdown Tables (| ... |)
      if (line.startsWith('|') && line.endsWith('|')) {
        final tableLines = <String>[];
        while (i < lines.length && lines[i].trim().startsWith('|') && lines[i].trim().endsWith('|')) {
          tableLines.add(lines[i].trim());
          i++;
        }
        widgets.add(_buildTable(tableLines));
        continue;
      }

      // 5. List items (- or 1.)
      if (line.startsWith('- ') || line.startsWith('* ')) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 6, right: 8),
                  child: Icon(Icons.circle, size: 6, color: OutdoorTheme.signalOrange),
                ),
                Expanded(
                  child: _buildRichText(line.substring(2).trim()),
                ),
              ],
            ),
          ),
        );
        i++;
        continue;
      }

      // 6. Numbered list items (1. 2. 3.)
      final numMatch = RegExp(r'^(\d+)\.\s+(.*)$').firstMatch(line);
      if (numMatch != null) {
        final numStr = numMatch.group(1)!;
        final textStr = numMatch.group(2)!;
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(right: 8, top: 2),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.cyanAccent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    numStr,
                    style: const TextStyle(
                      color: Colors.cyanAccent,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  child: _buildRichText(textStr),
                ),
              ],
            ),
          ),
        );
        i++;
        continue;
      }

      // 7. Math formula block ($$...$$)
      if (line.startsWith(r'$$') && line.endsWith(r'$$')) {
        final formula = line.substring(2, line.length - 2).trim();
        widgets.add(
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(vertical: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: OutdoorTheme.surfaceCard,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.3)),
            ),
            child: Text(
              formula.replaceAll(r'\times', '×').replaceAll(r'\approx', '≈').replaceAll(r'\text', '').replaceAll('{', '').replaceAll('}', '').replaceAll(r'\left', '').replaceAll(r'\right', '').replaceAll(r'\frac', '').replaceAll(r'\mathbf', ''),
              style: const TextStyle(
                color: Colors.cyanAccent,
                fontFamily: 'monospace',
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        );
        i++;
        continue;
      }

      // 8. Standard paragraph
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: _buildRichText(line),
        ),
      );
      i++;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  Widget _buildRichText(String text) {
    final spans = <InlineSpan>[];
    final parts = text.split(RegExp(r'(\*\*.*?\*\*|\*.*?\*|\`.*?\`|\$.*?\$)'));

    for (final part in parts) {
      if (part.isEmpty) continue;

      if (part.startsWith('**') && part.endsWith('**')) {
        spans.add(
          TextSpan(
            text: part.substring(2, part.length - 2),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      } else if (part.startsWith('*') && part.endsWith('*')) {
        spans.add(
          TextSpan(
            text: part.substring(1, part.length - 1),
            style: const TextStyle(
              color: Colors.white70,
              fontStyle: FontStyle.italic,
            ),
          ),
        );
      } else if (part.startsWith('`') && part.endsWith('`')) {
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.white24, width: 0.5),
              ),
              child: Text(
                part.substring(1, part.length - 1),
                style: const TextStyle(
                  color: Colors.cyanAccent,
                  fontFamily: 'monospace',
                  fontSize: 12,
                ),
              ),
            ),
          ),
        );
      } else if (part.startsWith(r'$') && part.endsWith(r'$')) {
        spans.add(
          TextSpan(
            text: part.substring(1, part.length - 1).replaceAll(r'\times', '×').replaceAll(r'\text', '').replaceAll('{', '').replaceAll('}', '').replaceAll(r'\rightarrow', '➔'),
            style: const TextStyle(
              color: Colors.cyanAccent,
              fontFamily: 'monospace',
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      } else {
        spans.add(
          TextSpan(
            text: part,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        );
      }
    }

    return SelectableText.rich(
      TextSpan(children: spans),
    );
  }

  Widget _buildTable(List<String> tableLines) {
    if (tableLines.length < 2) return const SizedBox.shrink();

    final headerCols = tableLines[0]
        .split('|')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    final dataRows = <List<String>>[];
    for (int i = 1; i < tableLines.length; i++) {
      if (tableLines[i].contains('---') || tableLines[i].contains(':---')) continue;
      final rowCols = tableLines[i]
          .split('|')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      if (rowCols.isNotEmpty) {
        dataRows.add(rowCols);
      }
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: OutdoorTheme.surfaceCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(OutdoorTheme.darkBackground),
            headingTextStyle: const TextStyle(
              color: OutdoorTheme.signalOrange,
              fontWeight: FontWeight.bold,
              fontSize: 12.5,
            ),
            dataTextStyle: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
            columns: headerCols.map((h) => DataColumn(label: Text(h.replaceAll('**', '')))).toList(),
            rows: dataRows.map((row) {
              return DataRow(
                cells: row.map((cell) => DataCell(Text(cell.replaceAll('**', '')))).toList(),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
