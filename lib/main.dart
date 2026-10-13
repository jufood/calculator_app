
import 'package:flutter/material.dart';

void main() {
  runApp(const CalculatorApp());
}

class CalculatorApp extends StatefulWidget {
  const CalculatorApp({super.key});

  @override
  State<CalculatorApp> createState() => _CalculatorAppState();
}

class _CalculatorAppState extends State<CalculatorApp> {
  bool isDark = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Calculator State Lab',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorSchemeSeed: Colors.blue,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: Colors.blue,
      ),
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      themeAnimationDuration: const Duration(milliseconds: 300),
      home: CalculatorPage(
        isDark: isDark,
        onThemeChanged: () {
          setState(() {
            isDark = !isDark;
          });
        },
      ),
    );
  }
}

class CalculatorPage extends StatefulWidget {
  final bool isDark;
  final VoidCallback onThemeChanged;

  const CalculatorPage({
    super.key,
    required this.isDark,
    required this.onThemeChanged,
  });

  @override
  State<CalculatorPage> createState() => _CalculatorPageState();
}

class _CalculatorPageState extends State<CalculatorPage> {
  String currentInput = '0';
  double? accumulator;
  String? pendingOperator;
  bool awaitingOperand = false;
  bool resultPhase = false;
  String? message;

  String formatNumber(double number) {
    if (!number.isFinite) return 'Error';
    if (number == 0) return '0';
    if (number == number.truncateToDouble()) {
      return number.toStringAsFixed(0);
    }
    return double.parse(number.toStringAsPrecision(12)).toString();
  }

  double? calculate(double a, double b, String operator) {
    switch (operator) {
      case '+':
        return a + b;
      case '-':
        return a - b;
      case '×':
        return a * b;
      case '÷':
        if (b == 0) return null;
        return a / b;
      default:
        return null;
    }
  }

  void clearAll() {
    setState(() {
      currentInput = '0';
      accumulator = null;
      pendingOperator = null;
      awaitingOperand = false;
      resultPhase = false;
      message = null;
    });
  }

  void showError(String error) {
    setState(() {
      currentInput = 'Error';
      accumulator = null;
      pendingOperator = null;
      awaitingOperand = false;
      resultPhase = true;
      message = error;
    });
  }

  void enterDigit(String digit) {
    setState(() {
      if (resultPhase || currentInput == 'Error') {
        currentInput = digit;
        accumulator = null;
        pendingOperator = null;
        awaitingOperand = false;
        resultPhase = false;
      } else if (awaitingOperand) {
        currentInput = digit;
        awaitingOperand = false;
      } else if (currentInput == '0') {
        currentInput = digit;
      } else if (currentInput.length < 14) {
        currentInput += digit;
      }
      message = null;
    });
  }

  void chooseOperator(String operator) {
    if (currentInput == 'Error') return;

    if (awaitingOperand) {
      setState(() {
        pendingOperator = operator;
        message = 'Operator changed to $operator';
      });
      return;
    }

    final value = double.parse(currentInput);

    if (accumulator != null && pendingOperator != null) {
      final result = calculate(accumulator!, value, pendingOperator!);
      if (result == null || !result.isFinite) {
        showError('Cannot divide by zero or calculate this result');
        return;
      }

      setState(() {
        accumulator = result;
        currentInput = formatNumber(result);
        pendingOperator = operator;
        awaitingOperand = true;
        resultPhase = false;
        message = null;
      });
    } else {
      setState(() {
        accumulator = value;
        pendingOperator = operator;
        awaitingOperand = true;
        resultPhase = false;
        message = null;
      });
    }
  }

  void pressEquals() {
    if (currentInput == 'Error') return;

    if (awaitingOperand) {
      setState(() {
        message = 'Enter another number before equals';
      });
      return;
    }

    if (accumulator == null || pendingOperator == null) {
      setState(() {
        resultPhase = true;
        message = null;
      });
      return;
    }

    final result = calculate(
      accumulator!,
      double.parse(currentInput),
      pendingOperator!,
    );

    if (result == null || !result.isFinite) {
      showError('Cannot divide by zero or calculate this result');
      return;
    }

    setState(() {
      currentInput = formatNumber(result);
      accumulator = null;
      pendingOperator = null;
      awaitingOperand = false;
      resultPhase = true;
      message = null;
    });
  }

  void handleButton(String key) {
    if (RegExp(r'^[0-9]$').hasMatch(key)) {
      enterDigit(key);
    } else if (key == 'AC') {
      clearAll();
    } else if (key == '=') {
      pressEquals();
    } else {
      chooseOperator(key);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final rows = [
      ['7', '8', '9', '÷'],
      ['4', '5', '6', '×'],
      ['1', '2', '3', '-'],
      ['AC', '0', '=', '+'],
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calculator State Lab'),
        actions: [
          IconButton(
            tooltip: 'Switch light or dark theme',
            icon: Icon(
              widget.isDark ? Icons.light_mode : Icons.dark_mode,
            ),
            onPressed: widget.onThemeChanged,
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Expanded(
                    flex: 2,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: colors.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            pendingOperator == null
                                ? 'Ready'
                                : awaitingOperand
                                    ? 'Waiting for number: $pendingOperator'
                                    : 'Operation: $pendingOperator',
                            style: TextStyle(
                              color: colors.onSurfaceVariant,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 12),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerRight,
                            child: Text(
                              currentInput,
                              key: const Key('calculatorDisplay'),
                              style: const TextStyle(
                                fontSize: 56,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (message != null)
                            Text(
                              message!,
                              style: TextStyle(
                                color: colors.error,
                                fontSize: 13,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    flex: 5,
                    child: Column(
                      children: rows.map((row) {
                        return Expanded(
                          child: Row(
                            children: row.map((key) {
                              return Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.all(5),
                                  child: CalculatorButton(
                                    label: key,
                                    onPressed: () => handleButton(key),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class CalculatorButton extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;

  const CalculatorButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  @override
  State<CalculatorButton> createState() => _CalculatorButtonState();
}

class _CalculatorButtonState extends State<CalculatorButton> {
  bool pressed = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isOperator = ['+', '-', '×', '÷', '='].contains(widget.label);

    return AnimatedScale(
      scale: pressed ? 0.92 : 1.0,
      duration: const Duration(milliseconds: 110),
      child: Material(
        color: isOperator
            ? colors.primaryContainer
            : colors.secondaryContainer,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: Key('button_${widget.label}'),
          onTapDown: (_) => setState(() => pressed = true),
          onTapUp: (_) => setState(() => pressed = false),
          onTapCancel: () => setState(() => pressed = false),
          onTap: widget.onPressed,
          child: Center(
            child: Text(
              widget.label,
              style: TextStyle(
                fontSize: 27,
                fontWeight: FontWeight.w600,
                color: isOperator
                    ? colors.onPrimaryContainer
                    : colors.onSecondaryContainer,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
