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
        var quoteText = quoteLines.join('\n');

        CalloutType type = CalloutType.tip;
        String title = 'Совет эксперта';

        if (quoteText.contains('💡') || quoteText.toLowerCase().contains('совет')) {
          type = CalloutType.tip;
          title = '💡 Совет бывалого';
        } else if (quoteText.contains('⚠️') ||
            quoteText.toLowerCase().contains('важно') ||
            quoteText.toLowerCase().contains('внимание')) {
          type = CalloutType.warning;
          title = '⚠️ Важно для безопасности';
        } else if (quoteText.contains('📐') || quoteText.toLowerCase().contains('формул')) {
          type = CalloutType.formula;
          title = '📐 Расчетная формула';
        } else if (quoteText.contains('🧪') || quoteText.toLowerCase().contains('физиолог')) {
          type = CalloutType.physiology;
          title = '🧪 Физиология и метаболизм';
        }

        // Clean redundant leading bold prefix (e.g. "> 💡 **Совет бывалого:** Текст")
        quoteText = quoteText
            .replaceFirst(RegExp(r'^(💡|⚠️|📐|🧪)?\s*\*\*[^*]+\*\*:\s*'), '')
            .replaceAll('**', '');

        widgets.add(
          WikiCalloutBox(
            title: title,
            content: quoteText,
            type: type,
          ),
        );
        continue;
      }

      // 3. Headings (#, ##, ###)
      if (line.startsWith('# ')) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 20, bottom: 8),
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
            padding: const EdgeInsets.only(top: 18, bottom: 8),
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

      if (line.startsWith('#### ')) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 4),
            child: Text(
              line.substring(5).trim(),
              style: const TextStyle(
                color: Color(0xFFFFB74D),
                fontSize: 14,
                fontWeight: FontWeight.bold,
                height: 1.3,
              ),
            ),
          ),
        );
        i++;
        continue;
      }

      if (line.startsWith('##### ') || line.startsWith('###### ')) {
        final prefixLen = line.startsWith('##### ') ? 6 : 7;
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 4),
            child: Text(
              line.substring(prefixLen).trim(),
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
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

      // 5. List items (- or * )
      if (line.startsWith('- ') || line.startsWith('* ')) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 7, right: 10),
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
      final numMatch = RegExp(r'^(\d+)[\.\)]\s+(.*)$').firstMatch(line);
      if (numMatch != null) {
        final numStr = numMatch.group(1)!;
        final textStr = numMatch.group(2)!;
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 22,
                  height: 22,
                  margin: const EdgeInsets.only(right: 10, top: 1),
                  decoration: BoxDecoration(
                    color: Colors.cyanAccent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.6)),
                  ),
                  child: Center(
                    child: Text(
                      numStr,
                      style: const TextStyle(
                        color: Colors.cyanAccent,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
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
        final cleanFormula = formula
            .replaceAll(r'\times', ' × ')
            .replaceAll(r'\approx', ' ≈ ')
            .replaceAll(r'\rightarrow', ' ➔ ')
            .replaceAll(r'\sum', '∑')
            .replaceAll(r'\frac', '')
            .replaceAll(r'\left', '')
            .replaceAll(r'\right', '')
            .replaceAll(r'\mathbf', '')
            .replaceAll(r'\text', '')
            .replaceAll('{', '')
            .replaceAll('}', '')
            .replaceAll(r'\', '')
            .replaceAll(RegExp(r'\s+'), ' ')
            .trim();

        widgets.add(
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(vertical: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: OutdoorTheme.surfaceCard,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.4)),
            ),
            child: Text(
              cleanFormula,
              style: const TextStyle(
                color: Colors.cyanAccent,
                fontFamily: 'monospace',
                fontSize: 13.5,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.3,
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
          padding: const EdgeInsets.only(bottom: 8),
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

  Widget _buildRichText(String text, {double fontSize = 14, Color? color, double height = 1.5}) {
    final spans = <InlineSpan>[];

    // Pattern matches:
    // 1. Bold: **text**
    // 2. Italic: *text* (excluding lone stars)
    // 3. Inline code: `text`
    // 4. Inline math: $text$
    final pattern = RegExp(r'(\*\*([^*]+)\*\*|\*([^*]+)\*|`([^`]+)`|\$([^$]+)\$)');

    int lastMatchEnd = 0;
    for (final match in pattern.allMatches(text)) {
      // Add plain text before match
      if (match.start > lastMatchEnd) {
        spans.add(
          TextSpan(
            text: text.substring(lastMatchEnd, match.start),
            style: TextStyle(
              color: color ?? Colors.white70,
              fontSize: fontSize,
              height: height,
            ),
          ),
        );
      }

      final fullMatch = match.group(0)!;
      if (fullMatch.startsWith('**') && fullMatch.endsWith('**')) {
        final content = fullMatch.substring(2, fullMatch.length - 2);
        spans.add(
          TextSpan(
            text: content,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: fontSize,
              height: height,
            ),
          ),
        );
      } else if (fullMatch.startsWith('*') && fullMatch.endsWith('*')) {
        final content = fullMatch.substring(1, fullMatch.length - 1);
        spans.add(
          TextSpan(
            text: content,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontStyle: FontStyle.italic,
              fontSize: fontSize,
              height: height,
            ),
          ),
        );
      } else if (fullMatch.startsWith('`') && fullMatch.endsWith('`')) {
        final content = fullMatch.substring(1, fullMatch.length - 1);
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.white24, width: 0.5),
              ),
              child: Text(
                content,
                style: const TextStyle(
                  color: Colors.cyanAccent,
                  fontFamily: 'monospace',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        );
      } else if (fullMatch.startsWith(r'$') && fullMatch.endsWith(r'$')) {
        final content = fullMatch
            .substring(1, fullMatch.length - 1)
            .replaceAll(r'\times', ' × ')
            .replaceAll(r'\approx', ' ≈ ')
            .replaceAll(r'\rightarrow', ' ➔ ')
            .replaceAll(r'\mathbf', '')
            .replaceAll(r'\text', '')
            .replaceAll('{', '')
            .replaceAll('}', '')
            .replaceAll(r'\', '')
            .trim();
        spans.add(
          TextSpan(
            text: content,
            style: TextStyle(
              color: Colors.cyanAccent,
              fontFamily: 'monospace',
              fontWeight: FontWeight.bold,
              fontSize: fontSize,
              height: height,
            ),
          ),
        );
      }

      lastMatchEnd = match.end;
    }

    // Add remaining plain text
    if (lastMatchEnd < text.length) {
      spans.add(
        TextSpan(
          text: text.substring(lastMatchEnd),
          style: TextStyle(
            color: color ?? Colors.white70,
            fontSize: fontSize,
            height: height,
          ),
        ),
      );
    }

    return SelectableText.rich(
      TextSpan(children: spans),
    );
  }

  Widget _buildTable(List<String> tableLines) {
    if (tableLines.length < 2) return const SizedBox.shrink();

    final headerCols = tableLines[0]
        .split('|')
        .map((s) => s.trim().replaceAll('**', ''))
        .where((s) => s.isNotEmpty)
        .toList();

    final dataRows = <List<String>>[];
    for (int i = 1; i < tableLines.length; i++) {
      if (tableLines[i].contains('---') || tableLines[i].contains(':---')) continue;
      final rowCols = tableLines[i]
          .split('|')
          .map((s) => s.trim().replaceAll('**', ''))
          .where((s) => s.isNotEmpty)
          .toList();
      if (rowCols.isNotEmpty) {
        dataRows.add(rowCols);
      }
    }

    if (dataRows.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 650;

        // On mobile / narrow screens with 3+ columns, render as structured responsive cards
        if (isCompact && headerCols.length >= 3) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: dataRows.map((row) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: OutdoorTheme.surfaceCard,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row: Primary Title + Category Tag
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              row.length > 1 ? row[1] : row[0],
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14.5,
                                fontWeight: FontWeight.bold,
                                height: 1.25,
                              ),
                            ),
                          ),
                          if (row.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: OutdoorTheme.signalOrange.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: OutdoorTheme.signalOrange.withValues(alpha: 0.4)),
                              ),
                              child: Text(
                                row[0],
                                style: const TextStyle(
                                  color: OutdoorTheme.signalOrange,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Detail fields (Columns 2+)
                      for (int c = 2; c < row.length && c < headerCols.length; c++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 5),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${headerCols[c]}: ',
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  row[c],
                                  style: TextStyle(
                                    color: c == 2 ? Colors.cyanAccent : Colors.white70,
                                    fontSize: 12.5,
                                    height: 1.3,
                                    fontWeight: c == 2 ? FontWeight.w600 : FontWeight.normal,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                );
              }).toList(),
            ),
          );
        }

        // Standard Wide Table (100% width, no horizontal scrolling needed)
        final columnWidths = <int, TableColumnWidth>{};
        if (headerCols.length == 2) {
          columnWidths[0] = const FlexColumnWidth(2);
          columnWidths[1] = const FlexColumnWidth(1.5);
        } else if (headerCols.length == 4) {
          columnWidths[0] = const FlexColumnWidth(1.2);
          columnWidths[1] = const FlexColumnWidth(1.2);
          columnWidths[2] = const FlexColumnWidth(1.1);
          columnWidths[3] = const FlexColumnWidth(2.2);
        } else {
          for (int c = 0; c < headerCols.length; c++) {
            columnWidths[c] = const FlexColumnWidth(1);
          }
        }

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: OutdoorTheme.surfaceCard,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white12),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Table(
              columnWidths: columnWidths,
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              children: [
                // Header Row
                TableRow(
                  decoration: const BoxDecoration(
                    color: OutdoorTheme.darkBackground,
                    border: Border(bottom: BorderSide(color: Colors.white12)),
                  ),
                  children: headerCols.map((h) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      child: Text(
                        h,
                        style: const TextStyle(
                          color: OutdoorTheme.signalOrange,
                          fontWeight: FontWeight.bold,
                          fontSize: 12.5,
                        ),
                      ),
                    );
                  }).toList(),
                ),

                // Data Rows
                for (int r = 0; r < dataRows.length; r++)
                  TableRow(
                    decoration: BoxDecoration(
                      color: r % 2 == 1 ? Colors.white.withValues(alpha: 0.02) : Colors.transparent,
                      border: Border(
                        bottom: BorderSide(
                          color: r == dataRows.length - 1 ? Colors.transparent : Colors.white.withValues(alpha: 0.05),
                        ),
                      ),
                    ),
                    children: [
                      for (int c = 0; c < headerCols.length; c++)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                          child: Text(
                            c < dataRows[r].length ? dataRows[r][c] : '',
                            style: TextStyle(
                              color: c == 0 ? Colors.white : Colors.white70,
                              fontWeight: c == 0 || c == 1 ? FontWeight.w600 : FontWeight.normal,
                              fontSize: 12.5,
                              height: 1.35,
                            ),
                          ),
                        ),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
