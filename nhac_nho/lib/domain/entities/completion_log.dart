// Entity CompletionLog lưu lịch sử hoàn thành/bỏ qua theo ngày.

enum CompletionStatus {
  done,
  skipped;

  static CompletionStatus fromString(String value) {
    return CompletionStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => CompletionStatus.done,
    );
  }
}

class CompletionLog {
  const CompletionLog({
    this.id,
    required this.reminderId,
    required this.date,
    required this.status,
    required this.completedAt,
  });

  final int? id;
  final int reminderId;
  final String date;
  final CompletionStatus status;
  final String completedAt;

  CompletionLog copyWith({
    int? id,
    int? reminderId,
    String? date,
    CompletionStatus? status,
    String? completedAt,
  }) {
    return CompletionLog(
      id: id ?? this.id,
      reminderId: reminderId ?? this.reminderId,
      date: date ?? this.date,
      status: status ?? this.status,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  Map<String, Object?> toMap() {
    return {
      if (id != null) 'id': id,
      'reminderId': reminderId,
      'date': date,
      'status': status.name,
      'completedAt': completedAt,
    };
  }

  factory CompletionLog.fromMap(Map<String, Object?> map) {
    return CompletionLog(
      id: map['id'] as int?,
      reminderId: map['reminderId'] as int,
      date: map['date'] as String,
      status: CompletionStatus.fromString(map['status'] as String),
      completedAt: map['completedAt'] as String,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CompletionLog &&
        other.id == id &&
        other.reminderId == reminderId &&
        other.date == date &&
        other.status == status &&
        other.completedAt == completedAt;
  }

  @override
  int get hashCode =>
      Object.hash(id, reminderId, date, status, completedAt);
}
