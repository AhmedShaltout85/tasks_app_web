// reusable_user_bottom_sheet.dart
import 'dart:developer';

import 'package:flutter/material.dart';

// Field configuration classes
abstract class FieldConfig {
  final String key;
  final String label;
  final String? hint;
  final IconData? icon;

  FieldConfig({
    required this.key,
    required this.label,
    this.hint,
    this.icon,
  });
}

class TextFieldConfig extends FieldConfig {
  final String? initialValue;
  final TextInputType? keyboardType;
  final int? maxLines;
  final bool obscureText;
  final String? Function(String?)? validator;

  TextFieldConfig({
    required super.key,
    required super.label,
    super.hint,
    super.icon,
    this.initialValue,
    this.keyboardType,
    this.maxLines = 1,
    this.obscureText = false,
    this.validator,
  });
}

class DropdownFieldConfig extends FieldConfig {
  final List<String> items;
  final String? initialValue;
  final Function(String?)? onChanged;
  final String? Function(String?)? validator;

  DropdownFieldConfig({
    required super.key,
    required super.label,
    required this.items,
    super.hint,
    super.icon,
    this.initialValue,
    this.onChanged,
    this.validator,
  });
}

class MultiSelectDropdownFieldConfig extends FieldConfig {
  final List<String> items;
  final List<String>? initialValues;
  final bool includeSearch;
  final bool includeSelectAll;
  final bool isLarge;
  final BoxDecoration? boxDecoration;

  MultiSelectDropdownFieldConfig({
    required super.key,
    required super.label,
    required this.items,
    super.hint,
    super.icon,
    this.initialValues,
    this.includeSearch = false,
    this.includeSelectAll = false,
    this.isLarge = false,
    this.boxDecoration,
  });
}

class ToggleFieldConfig extends FieldConfig {
  final bool initialValue;
  final Function(bool)? onChanged;

  ToggleFieldConfig({
    required super.key,
    required super.label,
    this.initialValue = false,
    super.icon,
    this.onChanged,
  });
}

// Main reusable bottom sheet function
void showUserAddTaskBottomSheet({
  required BuildContext context,
  required List<String> appNames,
  required List<String> placeNames,
  required List<String> coOperatorUsers,
  String? initialTaskTitle,
  String? initialAppName,
  String? initialPlaceName,
  String? initialSubPlace,
  bool? initialIsRemote,
  List<String>? initialCoOperatorUsers,
  Function(Map<String, dynamic>)? onSubmitTask,
}) {
  // Filter out null or empty values from co-operator users
  final validInitialCoOperatorUsers = initialCoOperatorUsers
          ?.where((user) => user.isNotEmpty && coOperatorUsers.contains(user))
          .toList() ??
      [];

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (bottomSheetContext) => StatefulBuilder(
      builder: (builderContext, setState) {
        return _buildBottomSheetContent(
          context: context,
          appNames: appNames,
          placeNames: placeNames,
          coOperatorUsers: coOperatorUsers,
          initialTaskTitle: initialTaskTitle,
          initialAppName: initialAppName,
          initialPlaceName: initialPlaceName,
          initialSubPlace: initialSubPlace,
          initialIsRemote: initialIsRemote,
          initialCoOperatorUsers: validInitialCoOperatorUsers,
          onSubmitTask: onSubmitTask,
        );
      },
    ),
  );
}

Widget _buildBottomSheetContent({
  required BuildContext context,
  required List<String> appNames,
  required List<String> placeNames,
  required List<String> coOperatorUsers,
  String? initialTaskTitle,
  String? initialAppName,
  String? initialPlaceName,
  String? initialSubPlace,
  bool? initialIsRemote,
  List<String>? initialCoOperatorUsers,
  Function(Map<String, dynamic>)? onSubmitTask,
}) {
  // Add "اختر" as placeholder at the beginning of lists
  final appNamesWithPlaceholder = ['اختر', ...appNames];
  final placeNamesWithPlaceholder = ['اختر', ...placeNames];

  // Validate initial values exist in the lists
  final validInitialAppName = (initialAppName != null &&
          appNamesWithPlaceholder.contains(initialAppName))
      ? initialAppName
      : 'اختر';

  final validInitialPlaceName = (initialPlaceName != null &&
          placeNamesWithPlaceholder.contains(initialPlaceName))
      ? initialPlaceName
      : 'اختر';

  final fields = [
    TextFieldConfig(
      key: 'task_title',
      label: 'اسم المهمة',
      hint: 'ادخل اسم المهمة',
      icon: Icons.title,
      initialValue: initialTaskTitle,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'فضلا ادخل اسم المهمة';
        }
        return null;
      },
    ),
    DropdownFieldConfig(
      key: 'app_name',
      label: 'اسم التطبيق',
      icon: Icons.apps,
      items: appNamesWithPlaceholder,
      initialValue: validInitialAppName,
      validator: (value) {
        if (value == null || value.isEmpty || value == 'اختر') {
          return 'فضلا اختر اسم التطبيق';
        }
        return null;
      },
    ),
    DropdownFieldConfig(
      key: 'place_name',
      label: 'اسم المكان',
      icon: Icons.location_on,
      items: placeNamesWithPlaceholder,
      initialValue: validInitialPlaceName,
      validator: (value) {
        if (value == null || value.isEmpty || value == 'اختر') {
          return 'فضلا اختر اسم المكان';
        }
        return null;
      },
    ),
    TextFieldConfig(
      key: 'sub_place',
      label: 'المكان الفرعي',
      hint: 'ادخل المكان الفرعي',
      icon: Icons.location_on_outlined,
      initialValue: initialSubPlace ?? 'لايوجد',
    ),
    ToggleFieldConfig(
      key: 'is_remote',
      label: 'عن بعد',
      initialValue: initialIsRemote ?? false,
      icon: Icons.wifi,
    ),
    MultiSelectDropdownFieldConfig(
      key: 'co_operator_users',
      label: 'المتعاونون',
      items: coOperatorUsers,
      icon: Icons.people,
      hint: 'اختر المتعاونين',
      initialValues: initialCoOperatorUsers ?? [],
      // includeSearch: true,
      includeSelectAll: true,
      isLarge: true,
      boxDecoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey),
      ),
    ),
  ];

  return _UserAddTaskBottomSheetContent(
    title: 'إضافة مهمة جديدة',
    fields: fields,
    submitButtonText: 'حفظ المهمة',
    onSubmit: (values) async {
      if (onSubmitTask != null) {
        onSubmitTask(values);
      }
    },
  );
}

// Internal widget to show the bottom sheet content
class _UserAddTaskBottomSheetContent extends StatefulWidget {
  final String title;
  final List<FieldConfig> fields;
  final String submitButtonText;
  final Function(Map<String, dynamic>) onSubmit;
  final VoidCallback? onCancel;

  const _UserAddTaskBottomSheetContent({
    required this.title,
    required this.fields,
    this.submitButtonText = 'Submit',
    required this.onSubmit,
    this.onCancel,
  });

  @override
  State<_UserAddTaskBottomSheetContent> createState() =>
      _UserAddTaskBottomSheetContentState();
}

class _UserAddTaskBottomSheetContentState
    extends State<_UserAddTaskBottomSheetContent> {
  late Map<String, TextEditingController> _controllers;
  late Map<String, String?> _dropdownValues;
  late Map<String, List<String>> _multiSelectValues;
  late Map<String, bool> _toggleValues;
  final _formKey = GlobalKey<FormState>();

  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _controllers = {};
    _dropdownValues = {};
    _multiSelectValues = {};
    _toggleValues = {};

    for (var field in widget.fields) {
      if (field is TextFieldConfig) {
        _controllers[field.key] =
            TextEditingController(text: field.initialValue);
      } else if (field is DropdownFieldConfig) {
        // Ensure initial value exists in items
        String? validInitialValue;
        if (field.initialValue != null &&
            field.items.contains(field.initialValue)) {
          validInitialValue = field.initialValue;
        } else if (field.items.isNotEmpty) {
          validInitialValue = field.items.first;
        }
        _dropdownValues[field.key] = validInitialValue;
      } else if (field is MultiSelectDropdownFieldConfig) {
        // Filter initial values to only those that exist in items
        final validInitialValues = field.initialValues
                ?.where((v) => field.items.contains(v))
                .toList() ??
            [];
        _multiSelectValues[field.key] = validInitialValues;
      } else if (field is ToggleFieldConfig) {
        _toggleValues[field.key] = field.initialValue;
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                widget.title,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.blue,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ...widget.fields
                  .map((field) => _buildField(field, isDark, colorScheme)),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _handleSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        widget.submitButtonText,
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextButton(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor:
                            isDark ? Colors.grey[800] : Colors.grey[200],
                      ),
                      onPressed: () {
                        widget.onCancel?.call();
                        Navigator.pop(context);
                      },
                      child: Text(
                        'الغاء',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(FieldConfig field, bool isDark, ColorScheme colorScheme) {
    if (field is TextFieldConfig) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: TextFormField(
          strutStyle: StrutStyle(fontFamily: 'Cairo'),
          controller: _controllers[field.key],
          style: TextStyle(
              fontFamily: 'Cairo',
              color: isDark ? Colors.white : Colors.black87),
          decoration: InputDecoration(
            labelText: field.label,
            labelStyle: TextStyle(
                fontFamily: 'Cairo',
                color: isDark ? Colors.grey[400] : Colors.grey[700]),
            hintText: field.hint,
            hintStyle: TextStyle(
                fontFamily: 'Cairo',
                color: isDark ? Colors.grey[600] : Colors.grey[400]),
            prefixIcon: field.icon != null
                ? Icon(field.icon, color: colorScheme.primary)
                : null,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                  color: isDark ? Colors.grey[700]! : Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colorScheme.primary, width: 2),
            ),
            filled: true,
            fillColor: isDark
                ? colorScheme.surface.withValues(alpha: 0.5)
                : Colors.grey[50],
          ),
          keyboardType: field.keyboardType,
          maxLines: field.maxLines,
          obscureText: field.obscureText,
          validator: field.validator,
        ),
      );
    } else if (field is DropdownFieldConfig) {
      // Ensure the current value is valid
      final currentValue = _dropdownValues[field.key];
      final validValue =
          (currentValue != null && field.items.contains(currentValue))
              ? currentValue
              : (field.items.isNotEmpty ? field.items.first : null);

      if (currentValue != validValue) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _dropdownValues[field.key] = validValue;
            });
          }
        });
      }

      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: DropdownButtonFormField<String>(
          initialValue: validValue,
          dropdownColor: isDark ? colorScheme.surface : Colors.white,
          style: TextStyle(
              fontFamily: 'Cairo',
              color: isDark ? Colors.white : Colors.black87),
          decoration: InputDecoration(
            labelText: field.label,
            labelStyle: TextStyle(
                fontFamily: 'Cairo',
                color: isDark ? Colors.grey[400] : Colors.grey[700]),
            hintText: field.hint,
            hintStyle: TextStyle(
                fontFamily: 'Cairo',
                color: isDark ? Colors.grey[600] : Colors.grey[400]),
            prefixIcon: field.icon != null
                ? Icon(field.icon, color: colorScheme.primary)
                : null,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                  color: isDark ? Colors.grey[700]! : Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colorScheme.primary, width: 2),
            ),
            filled: true,
            fillColor: isDark
                ? colorScheme.surface.withValues(alpha: 0.5)
                : Colors.grey[50],
          ),
          items: field.items
              .map((item) => DropdownMenuItem<String>(
                    value: item,
                    child: Text(
                      item,
                      style: TextStyle(
                          fontFamily: 'Cairo',
                          color: isDark ? Colors.grey[300] : Colors.black87),
                    ),
                  ))
              .toList(),
          onChanged: (value) {
            setState(() {
              _dropdownValues[field.key] = value;
            });
            field.onChanged?.call(value);
          },
          validator: field.validator,
        ),
      );
    } else if (field is MultiSelectDropdownFieldConfig) {
      // Filter items based on search query
      final filteredItems = _searchQuery.isEmpty
          ? field.items
          : field.items
              .where((item) =>
                  item.toLowerCase().contains(_searchQuery.toLowerCase()))
              .toList();

      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (field.label.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    if (field.icon != null)
                      Icon(field.icon, size: 20, color: colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      field.label,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.grey[300] : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            Container(
              decoration: field.boxDecoration ??
                  BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(12),
                  ),
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  if (field.includeSearch)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: TextField(
                        strutStyle: StrutStyle(fontFamily: 'Cairo'),
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        decoration: InputDecoration(
                          hintText: 'بحث...',
                          hintStyle: TextStyle(
                            color: isDark ? Colors.grey[500] : Colors.grey[400],
                          ),
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          filled: true,
                          fillColor:
                              isDark ? Colors.grey[800] : Colors.grey[100],
                        ),
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                      ),
                    ),
                  if (field.includeSelectAll && filteredItems.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: CheckboxListTile(
                        title: Text(
                          'اختر الكل',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        value: _multiSelectValues[field.key]?.length ==
                                filteredItems.length &&
                            filteredItems.isNotEmpty,
                        onChanged: (bool? selected) {
                          setState(() {
                            if (selected == true) {
                              _multiSelectValues[field.key] =
                                  List.from(filteredItems);
                            } else {
                              _multiSelectValues[field.key] = [];
                            }
                          });
                        },
                        dense: true,
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                    ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: filteredItems.map((item) {
                      final isSelected =
                          _multiSelectValues[field.key]?.contains(item) ??
                              false;
                      return FilterChip(
                        label: Text(
                          item,
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _multiSelectValues[field.key] ??= [];
                            if (selected) {
                              _multiSelectValues[field.key]!.add(item);
                            } else {
                              _multiSelectValues[field.key]!.remove(item);
                            }
                          });
                        },
                        selectedColor:
                            colorScheme.primary.withValues(alpha: 0.3),
                        checkmarkColor: colorScheme.primary,
                      );
                    }).toList(),
                  ),
                  if (filteredItems.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'لا توجد نتائج',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          color: isDark ? Colors.grey[500] : Colors.grey[400],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      );
    } else if (field is ToggleFieldConfig) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                if (field.icon != null)
                  Icon(field.icon, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  field.label,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.grey[300] : Colors.black87,
                  ),
                ),
              ],
            ),
            Switch(
              value: _toggleValues[field.key] ?? false,
              onChanged: (value) {
                setState(() {
                  _toggleValues[field.key] = value;
                });
                field.onChanged?.call(value);
              },
              activeThumbColor: colorScheme.primary,
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }

  void _handleSubmit() {
    if (_formKey.currentState?.validate() ?? false) {
      final values = <String, dynamic>{};
      _controllers.forEach((key, controller) => values[key] = controller.text);
      _dropdownValues.forEach((key, value) {
        if (value != null && value.isNotEmpty && value != 'اختر')
          values[key] = value;
      });
      _multiSelectValues.forEach((key, value) => values[key] = value);
      _toggleValues.forEach((key, value) => values[key] = value);

      widget.onSubmit(values);
      Navigator.pop(context);
    }
  }
}
