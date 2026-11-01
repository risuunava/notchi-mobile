import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/strings.dart';
import 'pairing_progress_screen.dart';

class ManualConnectScreen extends ConsumerStatefulWidget {
  const ManualConnectScreen({super.key});

  @override
  ConsumerState<ManualConnectScreen> createState() =>
      _ManualConnectScreenState();
}

class _ManualConnectScreenState extends ConsumerState<ManualConnectScreen> {
  final _formKey = GlobalKey<FormState>();
  final _hostController = TextEditingController();
  final _portController = TextEditingController(text: '8765');
  final _tokenController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _hostController.dispose();
    _portController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _submitting = true);
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PairingProgressScreen.manual(
          host: _hostController.text.trim(),
          port: _portController.text.trim(),
          token: _tokenController.text.trim(),
        ),
      ),
    );
    if (mounted) setState(() => _submitting = false);
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(strings.manualTitle)),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                strings.manualHint,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _hostController,
                decoration: InputDecoration(
                  labelText: strings.hostLabel,
                  hintText: strings.hostHint,
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.url,
                textInputAction: TextInputAction.next,
                autocorrect: false,
                enableSuggestions: false,
                validator: (value) {
                  final host = value?.trim() ?? '';
                  if (host.isEmpty ||
                      RegExp(r'\s').hasMatch(host) ||
                      host.contains('/') ||
                      host.contains('://')) {
                    return strings.invalidHost;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _portController,
                decoration: InputDecoration(
                  labelText: strings.portLabel,
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                validator: (value) {
                  final port = int.tryParse(value?.trim() ?? '');
                  if (port == null || port < 1 || port > 65535) {
                    return strings.invalidPort;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _tokenController,
                decoration: InputDecoration(
                  labelText: strings.tokenLabel,
                  border: const OutlineInputBorder(),
                ),
                autocorrect: false,
                enableSuggestions: false,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submit(),
                validator: (value) {
                  if ((value?.trim() ?? '').isEmpty) {
                    return strings.missingToken;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(strings.connect),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
