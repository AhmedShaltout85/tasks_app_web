import 'package:flutter/material.dart';

class CustomReusableDialog extends StatefulWidget {
  final String title;
  final List<String> radioOptions;
  final String? initialSelectedOption;
  final String Function(String selectedOption)? textFieldLabelBuilder;
  final String textFieldLabel; // Kept for backward compatibility
  final String? initialTextValue;
  final Function(String selectedOption, String textValue) onSave;
  final VoidCallback? onCancel;

  const CustomReusableDialog({
    super.key,
    required this.title,
    required this.radioOptions,
    this.initialSelectedOption,
    this.textFieldLabel = '',
    this.textFieldLabelBuilder,
    this.initialTextValue,
    required this.onSave,
    this.onCancel,
  });

  @override
  State<CustomReusableDialog> createState() => _CustomReusableDialogState();

  // Static method to show the dialog
  static Future<void> show({
    required BuildContext context,
    required String title,
    required List<String> radioOptions,
    String? initialSelectedOption,
    String textFieldLabel = '',
    String Function(String selectedOption)? textFieldLabelBuilder,
    String? initialTextValue,
    required Function(String selectedOption, String textValue) onSave,
    VoidCallback? onCancel,
  }) {
    return showDialog(
      context: context,
      builder: (context) => CustomReusableDialog(
        title: title,
        radioOptions: radioOptions,
        initialSelectedOption: initialSelectedOption,
        textFieldLabel: textFieldLabel,
        textFieldLabelBuilder: textFieldLabelBuilder,
        initialTextValue: initialTextValue,
        onSave: onSave,
        onCancel: onCancel,
      ),
    );
  }
}

class _CustomReusableDialogState extends State<CustomReusableDialog> {
  late String _selectedOption;
  late TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _selectedOption = widget.initialSelectedOption ?? widget.radioOptions.first;
    _textController = TextEditingController(
      text: widget.initialTextValue ?? '',
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  String get _currentLabel {
    if (widget.textFieldLabelBuilder != null) {
      return widget.textFieldLabelBuilder!(_selectedOption);
    }
    return widget.textFieldLabel;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title, style: const TextStyle(color: Colors.blue, fontFamily: 'Cairo')),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Radio buttons
            ...widget.radioOptions.map((option) {
              return RadioListTile<String>(
                title: Text(option, style: const TextStyle(color: Colors.blue, fontFamily: 'Cairo')),
                value: option,
                groupValue: _selectedOption,
                onChanged: (value) {
                  setState(() {
                    _selectedOption = value!;
                  });
                },
                contentPadding: EdgeInsets.zero,
              );
            }),

            const SizedBox(height: 16),

            // Text field with dynamic label
            TextField(
              style: TextStyle(fontFamily: 'Cairo'),
              controller: _textController,
              decoration: InputDecoration(

                labelText: _currentLabel,
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        // Cancel button
        TextButton(
          onPressed: () {
            if (widget.onCancel != null) {
              widget.onCancel!();
            }
            Navigator.of(context).pop();
          },
          child: const Text('الغاء', style: TextStyle(fontFamily: 'Cairo')),
        ),

        // Save button
        ElevatedButton(
          onPressed: () {
            widget.onSave(_selectedOption, _textController.text);
            Navigator.of(context).pop();
          },
          child: const Text('Save', style: TextStyle(fontFamily: 'Cairo')),
        ),
      ],
    );
  }
}
