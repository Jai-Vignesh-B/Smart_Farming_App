import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class InsuranceScreen extends StatelessWidget {
  const InsuranceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('insurance'.tr()),
      ),
      body: Center(
        child: Text('insurance'.tr()),
      ),
    );
  }
}
