enum PaymentStatus {
  pending,
  processing,
  completed,
  failed,
  cancelled,
  refunded,
  loading,
}

extension PaymentStatusExtension on PaymentStatus {
  String get displayName {
    switch (this) {
      case PaymentStatus.pending:
        return 'Pending';
      case PaymentStatus.processing:
        return 'Processing';
      case PaymentStatus.completed:
        return 'Completed';
      case PaymentStatus.failed:
        return 'Failed';
      case PaymentStatus.cancelled:
        return 'Cancelled';
      case PaymentStatus.refunded:
        return 'Refunded';
      case PaymentStatus.loading:
        return 'Loading';
    }
  }

  bool get isSuccess => this == PaymentStatus.completed;
  bool get isFailure =>
      this == PaymentStatus.failed || this == PaymentStatus.cancelled;
  bool get isPending =>
      this == PaymentStatus.pending ||
      this == PaymentStatus.processing ||
      this == PaymentStatus.loading;
}
