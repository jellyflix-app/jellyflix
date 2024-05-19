import 'package:flutter/material.dart';

class SwitchSettingsTile extends StatelessWidget {
  final Widget? leading;
  final bool value;
  final Function(bool)? onChanged;
  final Widget title;
  const SwitchSettingsTile({
    super.key,
    this.leading,
    required this.value,
    required this.title,
    this.onChanged,
  });
  @override
  Widget build(BuildContext context) {
    return ListTile(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      leading: leading,
      title: title,
      trailing: Switch(
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}
