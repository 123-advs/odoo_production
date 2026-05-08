import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';

class ScanInput extends StatefulWidget {
  const ScanInput({
    super.key,
    required this.onScanned,
    this.hintText = 'Quét hoặc nhập mã lot',
    this.label,
    this.enabled = true,
    this.autofocus = true,
  });

  final Future<void> Function(String) onScanned;
  final String hintText;
  final String? label;
  final bool enabled;
  final bool autofocus;

  @override
  State<ScanInput> createState() => _ScanInputState();
}

class _ScanInputState extends State<ScanInput> {
  final _ctrl = TextEditingController();
  final _focus = FocusNode();
  bool _busy = false;

  static bool get _supportsCamera =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _submit(String value) async {
    final v = value.trim();
    if (v.isEmpty || _busy) return;
    setState(() => _busy = true);
    try {
      await widget.onScanned(v);
      _ctrl.clear();
    } finally {
      if (mounted) {
        setState(() => _busy = false);
        _reclaimFocus();
      }
    }
  }

  void _reclaimFocus() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus.requestFocus();
    });
  }

  Future<void> _openCamera() async {
    final result = await Get.to<String>(() => const _ScannerScreen());
    if (result != null && result.isNotEmpty) {
      await _submit(result);
    } else {
      _reclaimFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
        TextField(
          controller: _ctrl,
          focusNode: _focus,
          autofocus: widget.autofocus,
          enabled: widget.enabled,
          textInputAction: TextInputAction.done,
          onSubmitted: _submit,
          style: const TextStyle(
            fontSize: 16,
            color: AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: widget.hintText,
            prefixIcon: _busy
                ? const Padding(
                    padding: EdgeInsets.all(14),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2.4),
                    ),
                  )
                : const Icon(Icons.qr_code_scanner_rounded,
                    color: AppColors.primary),
            suffixIcon: _supportsCamera
                ? IconButton(
                    tooltip: 'Quét bằng camera',
                    onPressed: widget.enabled && !_busy ? _openCamera : null,
                    icon: const Icon(
                      Icons.photo_camera_outlined,
                      color: AppColors.primary,
                    ),
                  )
                : null,
          ),
        ),
      ],
    );
  }
}

class _ScannerScreen extends StatefulWidget {
  const _ScannerScreen();

  @override
  State<_ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<_ScannerScreen> {
  final _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  bool _popped = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_popped) return;
    final code = capture.barcodes
        .map((b) => b.rawValue ?? '')
        .firstWhere((s) => s.isNotEmpty, orElse: () => '');
    if (code.isEmpty) return;
    _popped = true;
    Get.back<String>(result: code);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Quét mã lot'),
        actions: [
          IconButton(
            tooltip: 'Đèn flash',
            onPressed: () => _controller.toggleTorch(),
            icon: const Icon(Icons.flashlight_on_outlined),
          ),
          IconButton(
            tooltip: 'Đảo camera',
            onPressed: () => _controller.switchCamera(),
            icon: const Icon(Icons.cameraswitch_outlined),
          ),
        ],
      ),
      body: MobileScanner(
        controller: _controller,
        onDetect: _onDetect,
      ),
    );
  }
}
