import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:multiselect_dropdown_flutter/multiselect_dropdown_flutter.dart';
import 'package:tasks_app/controller/theme_provider.dart';

/// A reusable bottom sheet component with multiple text fields, dropdowns, and multi-select dropdowns
class CustomBottomSheet extends StatefulWidget {
  final String title;
  final List<FieldConfig> fields;
  final String submitButtonText;
  final Function(Map<String, dynamic>) onSubmit;
  final VoidCallback? onCancel;

  const CustomBottomSheet({
    super.key,
    required this.title,
    required this.fields,
    this.submitButtonText = 'Submit',
    required this.onSubmit,
    this.onCancel,
  });

  @override
  State<CustomBottomSheet> createState() => _CustomBottomSheetState();

  /// Static method to show the bottom sheet
  static Future<void> show({
    required BuildContext context,
    required String title,
    required List<FieldConfig> fields,
    String submitButtonText = 'تابع',
    required Function(Map<String, dynamic>) onSubmit,
    VoidCallback? onCancel,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CustomBottomSheet(
        title: title,
        fields: fields,
        submitButtonText: submitButtonText,
        onSubmit: onSubmit,
        onCancel: onCancel,
      ),
    );
  }
}

class _CustomBottomSheetState extends State<CustomBottomSheet> {
  late Map<String, TextEditingController> _controllers;
  late Map<String, String?> _dropdownValues;
  late Map<String, List<String>> _multiSelectValues;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _controllers = {};
    _dropdownValues = {};
    _multiSelectValues = {};

    for (var field in widget.fields) {
      if (field is TextFieldConfig) {
        _controllers[field.key] = TextEditingController(
          text: field.initialValue,
        );
      } else if (field is DropdownFieldConfig) {
        _dropdownValues[field.key] = field.initialValue;
      } else if (field is MultiSelectDropdownFieldConfig) {
        _multiSelectValues[field.key] = List<String>.from(
          field.initialValues ?? [],
        );
      }
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _handleSubmit() {
    if (_formKey.currentState?.validate() ?? false) {
      final values = <String, dynamic>{};

      _controllers.forEach((key, controller) {
        values[key] = controller.text;
      });

      _dropdownValues.forEach((key, value) {
        if (value != null) {
          values[key] = value;
        }
      });

      _multiSelectValues.forEach((key, value) {
        values[key] = value;
      });

      widget.onSubmit(values);
      Navigator.pop(context);
    }
  }

  void _handleCancel() {
    // Call the onCancel callback if provided
    widget.onCancel?.call();
    // Close the bottom sheet
    Navigator.pop(context);
  }

  Widget _buildField(FieldConfig field, bool isDark, ColorScheme colorScheme) {
    if (field is TextFieldConfig) {
      return TextFormField(
        controller: _controllers[field.key],
        style: TextStyle(
            fontFamily: 'Cairo', color: isDark ? Colors.white : Colors.black87),
        decoration: InputDecoration(
          labelText: field.label,
          labelStyle: TextStyle(
            fontFamily: 'Cairo',
            color: isDark ? Colors.grey[400] : Colors.grey[700],
          ),
          hintText: field.hint,
          hintStyle: TextStyle(
            fontFamily: 'Cairo',
            color: isDark ? Colors.grey[600] : Colors.grey[400],
          ),
          prefixIcon: field.icon != null
              ? Icon(field.icon, color: colorScheme.primary)
              : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: colorScheme.primary, width: 2),
          ),
          filled: true,
          fillColor:
              isDark ? colorScheme.surface.withOpacity(0.5) : Colors.grey[50],
        ),
        keyboardType: field.keyboardType,
        maxLines: field.maxLines,
        obscureText: field.obscureText,
        validator: field.validator,
      );
    } else if (field is DropdownFieldConfig) {
      return DropdownButtonFormField<String>(
        initialValue: _dropdownValues[field.key],
        dropdownColor: isDark ? colorScheme.surface : Colors.white,
        style: TextStyle(
            fontFamily: 'Cairo', color: isDark ? Colors.white : Colors.black87),
        decoration: InputDecoration(
          labelText: field.label,
          labelStyle: TextStyle(
            fontFamily: 'Cairo',
            color: isDark ? Colors.grey[400] : Colors.grey[700],
          ),
          hintText: field.hint,
          hintStyle: TextStyle(
            fontFamily: 'Cairo',
            color: isDark ? Colors.grey[600] : Colors.grey[400],
          ),
          prefixIcon: field.icon != null
              ? Icon(field.icon, color: colorScheme.primary)
              : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: colorScheme.primary, width: 2),
          ),
          filled: true,
          fillColor:
              isDark ? colorScheme.surface.withOpacity(0.5) : Colors.grey[50],
        ),
        items: field.items.map((item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(
              item,
              style: TextStyle(
                fontFamily: 'Cairo',
                color: isDark ? Colors.grey[300] : Colors.black87,
              ),
            ),
          );
        }).toList(),
        onChanged: (value) {
          setState(() {
            _dropdownValues[field.key] = value;
          });
          field.onChanged?.call(value);
        },
        validator: field.validator,
      );
    } else if (field is MultiSelectDropdownFieldConfig) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (field.label.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text(
                field.label,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.grey[300] : Colors.black87,
                ),
              ),
            ),
          KeyedSubtree(
            key: field.widgetKey,
            child: MultiSelectDropdown.simpleList(
              list: field.items,
              initiallySelected: _multiSelectValues[field.key] ?? [],
              onChange: (newList) {
                setState(() {
                  _multiSelectValues[field.key] = List<String>.from(newList);
                });
                field.onChange?.call(newList);
              },
              includeSearch: field.includeSearch,
              includeSelectAll: field.includeSelectAll,
              isLarge: field.isLarge,
              boxDecoration: field.boxDecoration ??
                  BoxDecoration(
                    color: isDark
                        ? colorScheme.surface.withOpacity(0.5)
                        : Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                    ),
                  ),
            ),
          ),
          if (field.validator != null)
            Builder(
              builder: (context) {
                final error = field.validator!(_multiSelectValues[field.key]);
                if (error != null) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0, left: 12.0),
                    child: Text(
                      error,
                      style: TextStyle(
                          fontFamily: 'Cairo',
                          color: colorScheme.error,
                          fontSize: 12),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
        ],
      );
    }
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDark;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? colorScheme.surface : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[700] : Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    widget.title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                  // IconButton(
                  //   icon: Icon(
                  //     Icons.close,
                  //     color: isDark ? Colors.grey[400] : Colors.grey[700],
                  //   ),
                  //   onPressed: _handleCancel,
                  // ),
                ],
              ),
            ),
            Divider(color: isDark ? Colors.grey[800] : Colors.grey[300]),
            // Form fields
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      for (var field in widget.fields) ...[
                        _buildField(field, isDark, colorScheme),
                        const SizedBox(height: 16),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            // Action buttons
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _handleCancel,
                      style: OutlinedButton.styleFrom(
                        textStyle: TextStyle(fontFamily: 'Cairo'),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(
                          color:
                              isDark ? Colors.grey[700]! : colorScheme.primary,
                        ),
                        foregroundColor:
                            isDark ? Colors.grey[300] : colorScheme.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'تراجع',
                        style: TextStyle(fontFamily: 'Cairo'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _handleSubmit,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(widget.submitButtonText),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Base configuration for fields
abstract class FieldConfig {
  final String key;
  final String label;
  final String? hint;
  final IconData? icon;

  const FieldConfig({
    required this.key,
    required this.label,
    this.hint,
    this.icon,
  });
}

/// Configuration for text fields
class TextFieldConfig extends FieldConfig {
  final String? initialValue;
  final TextInputType keyboardType;
  final int maxLines;
  final bool obscureText;
  final String? Function(String?)? validator;

  const TextFieldConfig({
    required super.key,
    required super.label,
    super.hint,
    this.initialValue,
    super.icon,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
    this.obscureText = false,
    this.validator,
  });
}

/// Configuration for dropdown fields
class DropdownFieldConfig extends FieldConfig {
  final List<String> items;
  final String? initialValue;
  final String? Function(String?)? validator;
  final Function(String?)? onChanged;

  const DropdownFieldConfig({
    required super.key,
    required super.label,
    required this.items,
    this.initialValue,
    super.hint,
    super.icon,
    this.validator,
    this.onChanged,
  });
}

/// Configuration for multi-select dropdown fields
class MultiSelectDropdownFieldConfig extends FieldConfig {
  final List<String> items;
  final List<String>? initialValues;
  final Function(List<dynamic>)? onChange;
  final bool includeSearch;
  final bool includeSelectAll;
  final bool isLarge;
  final BoxDecoration? boxDecoration;
  final String? Function(List<String>?)? validator;
  final Key? widgetKey;

  const MultiSelectDropdownFieldConfig({
    required super.key,
    required super.label,
    required this.items,
    this.initialValues,
    this.onChange,
    this.includeSearch = true,
    this.includeSelectAll = true,
    this.isLarge = false,
    this.boxDecoration,
    this.validator,
    super.hint,
    super.icon,
    this.widgetKey,
  });
}
