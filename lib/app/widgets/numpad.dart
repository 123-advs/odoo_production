import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';

class Numpad extends StatefulWidget {
  const Numpad({
    super.key,
    required this.value,
    required this.onChanged,
    this.allowDecimal = true,
    this.maxLength = 9,
    this.label,
    this.autofocus = true,
  });

  final String value;
  final ValueChanged<String> onChanged;
  final bool allowDecimal;
  final int maxLength;
  final String? label;
  final bool autofocus;

  @override
  State<Numpad> createState() => _NumpadState();
}

class _NumpadState extends State<Numpad> {
  late final FocusNode _focus;
  bool _hasFocus = false;

  @override
  void initState() {
    super.initState();
    _focus = FocusNode(debugLabel: 'Numpad');
    _focus.addListener(() {
      if (mounted && _focus.hasFocus != _hasFocus) {
        setState(() => _hasFocus = _focus.hasFocus);
      }
    });
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;

    final digitMap = <LogicalKeyboardKey, String>{
      LogicalKeyboardKey.digit0: '0',
      LogicalKeyboardKey.digit1: '1',
      LogicalKeyboardKey.digit2: '2',
      LogicalKeyboardKey.digit3: '3',
      LogicalKeyboardKey.digit4: '4',
      LogicalKeyboardKey.digit5: '5',
      LogicalKeyboardKey.digit6: '6',
      LogicalKeyboardKey.digit7: '7',
      LogicalKeyboardKey.digit8: '8',
      LogicalKeyboardKey.digit9: '9',
      LogicalKeyboardKey.numpad0: '0',
      LogicalKeyboardKey.numpad1: '1',
      LogicalKeyboardKey.numpad2: '2',
      LogicalKeyboardKey.numpad3: '3',
      LogicalKeyboardKey.numpad4: '4',
      LogicalKeyboardKey.numpad5: '5',
      LogicalKeyboardKey.numpad6: '6',
      LogicalKeyboardKey.numpad7: '7',
      LogicalKeyboardKey.numpad8: '8',
      LogicalKeyboardKey.numpad9: '9',
    };
    final digit = digitMap[key];
    if (digit != null) {
      _onKeyPress(digit);
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.period ||
        key == LogicalKeyboardKey.numpadDecimal ||
        key == LogicalKeyboardKey.comma) {
      if (widget.allowDecimal) _onKeyPress('.');
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.backspace) {
      _onKeyPress('⌫');
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.delete) {
      _onClearAll();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focus,
      autofocus: widget.autofocus,
      onKeyEvent: _handleKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.label != null) ...[
            Text(
              widget.label!,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          _Display(
            value: widget.value,
            highlighted: _hasFocus,
            onTap: () => _focus.requestFocus(),
          ),
          const SizedBox(height: AppSpacing.md),
          _row(['7', '8', '9']),
          const SizedBox(height: AppSpacing.sm),
          _row(['4', '5', '6']),
          const SizedBox(height: AppSpacing.sm),
          _row(['1', '2', '3']),
          const SizedBox(height: AppSpacing.sm),
          _row([
            widget.allowDecimal ? '.' : null,
            '0',
            '⌫',
          ]),
        ],
      ),
    );
  }

  Widget _row(List<String?> keys) {
    return Row(
      children: [
        for (int i = 0; i < keys.length; i++) ...[
          if (i > 0) const SizedBox(width: AppSpacing.sm),
          Expanded(child: _key(keys[i])),
        ],
      ],
    );
  }

  Widget _key(String? key) {
    if (key == null) {
      return const SizedBox(height: AppSpacing.numpadButton);
    }
    final isBackspace = key == '⌫';
    return SizedBox(
      height: AppSpacing.numpadButton,
      child: Material(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusButton),
          side: const BorderSide(color: AppColors.divider),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppSpacing.radiusButton),
          onTap: () => _onKeyPress(key),
          onLongPress: isBackspace ? () => _onClearAll() : null,
          child: Center(
            child: isBackspace
                ? const Icon(
                    Icons.backspace_outlined,
                    size: 26,
                    color: AppColors.textPrimary,
                  )
                : Text(
                    key,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  void _onKeyPress(String key) {
    final cur = widget.value;
    String next;
    if (key == '⌫') {
      if (cur.isEmpty) return;
      next = cur.substring(0, cur.length - 1);
    } else if (key == '.') {
      if (cur.contains('.')) return;
      next = cur.isEmpty ? '0.' : '$cur.';
    } else {
      // digit
      if (cur.length >= widget.maxLength) return;
      if (cur == '0') {
        next = key;
      } else {
        next = '$cur$key';
      }
    }
    widget.onChanged(next);
  }

  void _onClearAll() => widget.onChanged('');
}

class _Display extends StatelessWidget {
  const _Display({
    required this.value,
    this.highlighted = false,
    this.onTap,
  });

  final String value;
  final bool highlighted;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final borderColor = highlighted ? AppColors.primary : AppColors.divider;
    final container = AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppSpacing.radiusButton),
        border: Border.all(
          color: borderColor,
          width: highlighted ? 1.5 : 1,
        ),
      ),
      child: Text(
        value.isEmpty ? '0' : value,
        textAlign: TextAlign.right,
        style: TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.w700,
          color: value.isEmpty ? AppColors.textMuted : AppColors.textPrimary,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
    if (onTap == null) return container;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusButton),
      child: container,
    );
  }
}
