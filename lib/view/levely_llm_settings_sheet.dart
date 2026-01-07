import 'package:app/service/levely_llm_config.dart';
import 'package:app/service/levely_runtime_config.dart';
import 'package:app/utils/colors.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

Future<void> showLevelyLlmSettingsSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const _LevelyLlmSettingsSheet(),
  );
}

class _LevelyLlmSettingsSheet extends StatefulWidget {
  const _LevelyLlmSettingsSheet();

  @override
  State<_LevelyLlmSettingsSheet> createState() => _LevelyLlmSettingsSheetState();
}

class _LevelyLlmSettingsSheetState extends State<_LevelyLlmSettingsSheet> {
  final TextEditingController _apiKeyController = TextEditingController();
  final TextEditingController _modelController = TextEditingController();
  final TextEditingController _baseUrlController = TextEditingController();
  bool _saving = false;
  bool _showKey = false;

  @override
  void initState() {
    super.initState();
    final overrides = LevelyRuntimeConfig.overrides;
    final effective = LevelyLlmConfigResolver.resolve(
      allowOverrides: kDebugMode,
      overrides: overrides,
    );
    _apiKeyController.text = overrides.apiKey ?? effective.apiKey;
    _modelController.text = overrides.model ?? effective.model;
    _baseUrlController.text = overrides.baseUrl ?? effective.baseUrl;
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _modelController.dispose();
    _baseUrlController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final overrides = LevelyLlmOverrides(
      apiKey: _apiKeyController.text,
      model: _modelController.text,
      baseUrl: _baseUrlController.text,
    );
    await LevelyRuntimeConfig.save(overrides);
    if (!mounted) return;
    setState(() => _saving = false);
    Navigator.pop(context);
  }

  Future<void> _clearOverrides() async {
    setState(() => _saving = true);
    await LevelyRuntimeConfig.clear();
    if (!mounted) return;
    final effective = LevelyLlmConfigResolver.resolve(
      allowOverrides: kDebugMode,
      overrides: LevelyRuntimeConfig.overrides,
    );
    setState(() {
      _apiKeyController.text = effective.apiKey;
      _modelController.text = effective.model;
      _baseUrlController.text = effective.baseUrl;
      _saving = false;
    });
  }

  void _applyDefaults() {
    final defaults = LevelyLlmConfigResolver.defaults();
    _modelController.text = defaults.model;
    _baseUrlController.text = defaults.baseUrl;
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: bottom),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 24,
                offset: const Offset(0, -10),
              ),
            ],
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'LLM Settings (Debug)',
                        style: TextStyle(
                          fontFamily: 'DIN_Next_Rounded',
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryColor,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                      color: Colors.black54,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Release build akan memakai gemini-3-flash dan API key dari dart-define.',
                  style: TextStyle(fontFamily: 'DIN_Next_Rounded', color: Colors.grey.shade700),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _modelController,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: 'Model',
                    labelStyle: const TextStyle(fontFamily: 'DIN_Next_Rounded'),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _baseUrlController,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: 'Base URL',
                    labelStyle: const TextStyle(fontFamily: 'DIN_Next_Rounded'),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _apiKeyController,
                  textInputAction: TextInputAction.done,
                  obscureText: !_showKey,
                  enableSuggestions: false,
                  autocorrect: false,
                  decoration: InputDecoration(
                    labelText: 'API key',
                    labelStyle: const TextStyle(fontFamily: 'DIN_Next_Rounded'),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    suffixIcon: IconButton(
                      onPressed: () => setState(() => _showKey = !_showKey),
                      icon: Icon(_showKey ? Icons.visibility_off : Icons.visibility),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    TextButton(
                      onPressed: _saving ? null : _applyDefaults,
                      child: const Text('Use defaults'),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: _saving ? null : _clearOverrides,
                      child: const Text('Clear overrides'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  style: FilledButton.styleFrom(backgroundColor: AppColors.primaryColor),
                  child: Text(
                    _saving ? 'Menyimpan...' : 'Simpan',
                    style: const TextStyle(fontFamily: 'DIN_Next_Rounded', fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
