class PurchaseResult {
  const PurchaseResult({
    required this.status,
    required this.recipeId,
    this.orderId,
    this.transactionId,
  });

  final PurchaseResultStatus status;
  final String recipeId;
  final String? orderId;
  final String? transactionId;

  factory PurchaseResult.fromJson(Map<String, dynamic> json) {
    return PurchaseResult(
      status: switch (json['status']) {
        'purchased' => PurchaseResultStatus.purchased,
        'already_owned' => PurchaseResultStatus.alreadyOwned,
        _ => throw const FormatException('Unknown purchase status.'),
      },
      recipeId: json['recipeId'] as String,
      orderId: json['orderId'] as String?,
      transactionId: json['transactionId'] as String?,
    );
  }
}

enum PurchaseResultStatus { purchased, alreadyOwned }
