class EscPosCommands {
  EscPosCommands._();

  static final List<int> init = _toBytes([0x1B, 0x40]);
  static final List<int> partialCut = _toBytes([0x1D, 0x56, 0x00]);
  static final List<int> fullCut = _toBytes([0x1D, 0x56, 0x01]);

  static final List<int> alignLeft = _toBytes([0x1B, 0x61, 0x00]);
  static final List<int> alignCenter = _toBytes([0x1B, 0x61, 0x01]);
  static final List<int> alignRight = _toBytes([0x1B, 0x61, 0x02]);

  static final List<int> boldOn = _toBytes([0x1B, 0x45, 0x01]);
  static final List<int> boldOff = _toBytes([0x1B, 0x45, 0x00]);

  static final List<int> doubleHw = _toBytes([0x1B, 0x21, 0x30]);
  static final List<int> normalSize = _toBytes([0x1B, 0x21, 0x00]);

  /// Set code page to CP437 (IBM PC character set)
  static final List<int> codePage437 = _toBytes([0x1B, 0x74, 0x00]);

  /// Set line spacing to 24/360 inch (~1.7mm) — compacto
  static final List<int> compactLineSpacing = _toBytes([0x1B, 0x33, 0x18]);

  /// Reset line spacing to default (30/360 inch)
  static final List<int> defaultLineSpacing = _toBytes([0x1B, 0x32]);

  static List<int> _textLine(String text) {
    return [...cp437Encode(text), 0x0A];
  }

  static List<int> _centerText(String text, {int width = 38}) {
    final pad = ' ' * (((width - text.length) ~/ 2).clamp(0, width));
    return _textLine(pad + text);
  }

  static List<int> _rule({int width = 38}) {
    return _textLine('=' * width);
  }

  /// Encode a string using CP437-like single-byte mapping.
  /// Thermal printers use single-byte code pages, NOT UTF-8.
  /// This strips/approximates non-ASCII chars to safe CP437 equivalents.
  static List<int> cp437Encode(String text) {
    final out = <int>[];
    for (final c in text.codeUnits) {
      if (c < 0x80) {
        // ASCII — direct
        out.add(c);
      } else {
        // Approximate common non-ASCII to CP437
        out.add(_cp437Approx(c));
      }
    }
    return out;
  }

  static int _cp437Approx(int codeUnit) {
    // CP437 approximations for common Spanish characters
    switch (codeUnit) {
      case 0x00E1: // á
        return 0xA0;
      case 0x00E9: // é
        return 0x82;
      case 0x00ED: // í
        return 0xA1;
      case 0x00F3: // ó
        return 0xA2;
      case 0x00FA: // ú
        return 0xA3;
      case 0x00F1: // ñ
        return 0xA4;
      case 0x00D1: // Ñ
        return 0xA5;
      case 0x00FC: // ü
        return 0x81;
      case 0x00BF: // ¿
        return 0xA8;
      case 0x00A1: // ¡
        return 0xAD;
      default:
        // Fallback: strip diacritics to base ASCII
        if (codeUnit >= 0xC0 && codeUnit <= 0xC5) return 0x41; // A
        if (codeUnit >= 0xE0 && codeUnit <= 0xE5) return 0x61; // a
        if (codeUnit == 0xC9 || codeUnit == 0xCB) return 0x45; // E
        if (codeUnit == 0xE9 || codeUnit == 0xEB) return 0x65; // e
        if (codeUnit >= 0xCC && codeUnit <= 0xCF) return 0x49; // I
        if (codeUnit >= 0xEC && codeUnit <= 0xEF) return 0x69; // i
        if (codeUnit >= 0xD2 && codeUnit <= 0xD6) return 0x4F; // O
        if (codeUnit >= 0xF2 && codeUnit <= 0xF6) return 0x6F; // o
        if (codeUnit >= 0xD9 && codeUnit <= 0xDC) return 0x55; // U
        if (codeUnit >= 0xF9 && codeUnit <= 0xFC) return 0x75; // u
        return 0x20; // space para todo lo demás
    }
  }

  /// Build compact thermal receipt (~6cm tall, 80mm paper).
  /// Ticket number dominates via double H+W + extra spacing.
  /// Uses CP437 single-byte encoding for printer compatibility.
  static List<int> buildTicketReceipt({
    required String headerText,
    required String ticketCode,
    required String areaName,
    required String dateTime,
    required String estimatedWait,
    String instruction = 'PRESENTE SU TICKET',
    String footer = 'Gracias por su preferencia',
    String? barcodeData,
    String? qrData,
  }) {
    final r = <int>[];

    r.addAll(init);

    // Configuración de impresora para ticket compacto
    r.addAll(codePage437);
    r.addAll(compactLineSpacing);
    r.addAll(alignCenter);

    // ── Header ──────────────────────────────────────────
    r.addAll(boldOn);
    r.addAll(_textLine(headerText));
    r.addAll(boldOff);
    r.addAll(_rule());

    // ── Fecha/hora ──────────────────────────────────────
    r.addAll(_centerText(dateTime));
    r.addAll(_rule());

    // ── 1 blank line arriba ─────────────────────────────
    r.addAll(_emptyLine());

    // ── TICKET (double H+W + bold, centrado en 20 cols) ─
    r.addAll(doubleHw);
    r.addAll(boldOn);
    r.addAll(_centerText(ticketCode, width: 20));
    r.addAll(boldOff);
    r.addAll(normalSize);

    // ── 1 blank line abajo ──────────────────────────────
    r.addAll(_emptyLine());

    // ── Restaurar interlineado default ──────────────────
    r.addAll(defaultLineSpacing);

    // ── Área + tiempo (una línea) ───────────────────────
    r.addAll(_rule());
    r.addAll(_textLine('$areaName  |  $estimatedWait'));
    r.addAll(_rule());

    // ── Mensajes ────────────────────────────────────────
    r.addAll(boldOn);
    r.addAll(_centerText('*** $instruction ***'));
    r.addAll(boldOff);
    r.addAll(_centerText(footer));
    r.addAll(_rule());

    // ── Corte ───────────────────────────────────────────
    r.addAll(fullCut);

    return r;
  }

  static List<int> _emptyLine() => [0x0A];

  /// Plain-text receipt for Windows print fallback.
  static String buildPlainTextReceipt({
    required String headerText,
    required String ticketCode,
    required String areaName,
    required String dateTime,
    required String estimatedWait,
    String instruction = '*** PRESENTE SU TICKET ***',
    String footer = 'Gracias por su preferencia',
  }) {
    final buf = StringBuffer();
    final sep = '=' * 36;

    buf.writeln('  $headerText');
    buf.writeln(sep);
    buf.writeln('    $dateTime');
    buf.writeln(sep);
    for (int i = 0; i < 5; i++) {
      buf.writeln();
    }
    buf.writeln('        $ticketCode');
    for (int i = 0; i < 5; i++) {
      buf.writeln();
    }
    buf.writeln(sep);
    buf.writeln('    $areaName  |  $estimatedWait');
    buf.writeln(sep);
    buf.writeln('  $instruction');
    buf.writeln('  $footer');
    buf.writeln(sep);

    return buf.toString();
  }

  static List<int> _toBytes(List<int> data) =>
      data.map((e) => e & 0xFF).toList();
}
