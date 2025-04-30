import 'package:flutter/material.dart';

// Placeholder for Confirmation Card
class ConfirmationCard extends StatelessWidget {
  final Map<String, String> collectedData;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const ConfirmationCard({
    Key? key,
    required this.collectedData,
    required this.onConfirm,
    required this.onCancel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10.0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Toplanan Bilgiler (Onay Bekliyor):', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (collectedData.isEmpty)
              const Text('Henüz bilgi toplanmadı.', style: TextStyle(fontStyle: FontStyle.italic))
            else
              // Use DataTable for better formatting
              SingleChildScrollView(
                scrollDirection: Axis.horizontal, // Allow horizontal scroll if needed
                child: DataTable(
                  columnSpacing: 16.0,
                  headingRowHeight: 30,
                  dataRowMinHeight: 35,
                  dataRowMaxHeight: 50,
                  columns: const [
                    DataColumn(label: Text('Alan', style: TextStyle(fontWeight: FontWeight.bold))), 
                    DataColumn(label: Text('Değer', style: TextStyle(fontWeight: FontWeight.bold))),
                  ],
                  rows: collectedData.entries.map((entry) => DataRow(
                    cells: [
                      DataCell(Text(entry.key)), // Display key (or maybe a mapped label if available)
                      DataCell(Text(entry.value, maxLines: 2, overflow: TextOverflow.ellipsis)),
                    ]
                  )).toList(),
                ),
              ),
            const SizedBox(height: 16),
            Text("Lütfen bilgileri kontrol edin. 'Belgeyi Oluştur' ile devam edebilir veya 'İptal Et' ile akışı sonlandırabilirsiniz.", style: theme.textTheme.bodySmall),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.cancel_outlined, size: 18),
                  label: const Text('İptal Et'),
                  onPressed: onCancel,
                  style: TextButton.styleFrom(
                     foregroundColor: theme.colorScheme.error,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  icon: const Icon(Icons.check_circle_outline, size: 18),
                  label: const Text('Onayla ve Oluştur'),
                  onPressed: onConfirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
} 