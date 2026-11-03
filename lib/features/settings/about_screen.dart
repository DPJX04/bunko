import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';

/// The About screen: what the app does, what it is built on, and the
/// licence page, which lists every package's licence, bili_novel_packer's
/// MIT notice and the Archivo font's OFL among them.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final ash = Theme.of(context).colorScheme.onSurfaceVariant;
    final sentence = text.bodyMedium?.copyWith(color: ash);
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.aboutTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        children: [
          Text('Bunko', style: text.titleMedium),
          const SizedBox(height: 8),
          Text(l10n.aboutWhat, style: sentence),
          const SizedBox(height: 16),
          Text(l10n.aboutDownloadOnly, style: sentence),
          const SizedBox(height: 16),
          Text(l10n.aboutBuiltOn, style: sentence),
          const SizedBox(height: 16),
          Text(l10n.aboutPersonal, style: sentence),
          const SizedBox(height: 24),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: OutlinedButton(
              onPressed: () =>
                  showLicensePage(context: context, applicationName: 'Bunko'),
              child: Text(l10n.openSourceLicences),
            ),
          ),
        ],
      ),
    );
  }
}
