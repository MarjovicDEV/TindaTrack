enum HistoryKind { sale, expense, utang }

class HistoryItem {
  const HistoryItem({
    required this.kind,
    required this.title,
    required this.subtitle,
    required this.createdAt,
    this.amount,
  });

  final HistoryKind kind;
  final String title;
  final String subtitle;
  final DateTime createdAt;
  final double? amount;
}
