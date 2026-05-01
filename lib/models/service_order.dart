class ServiceOrder {
  final String? id;
  final String userId;
  final String urgencyType;
  final DateTime? scheduledDate;
  final String cleaningType;
  final int bedrooms;
  final int bathrooms;
  final double estimatedPrice;
  final String status;
  final String? videoUrl;
  final DateTime? createdAt;

  ServiceOrder({
    this.id,
    required this.userId,
    required this.urgencyType,
    this.scheduledDate,
    required this.cleaningType,
    required this.bedrooms,
    required this.bathrooms,
    required this.estimatedPrice,
    this.status = 'pending',
    this.videoUrl,
    this.createdAt,
  });

  /// Converte o model para Map (para inserir no Supabase)
  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'urgency_type': urgencyType,
      'scheduled_date': scheduledDate?.toIso8601String(),
      'cleaning_type': cleaningType,
      'bedrooms': bedrooms,
      'bathrooms': bathrooms,
      'estimated_price': estimatedPrice,
      'status': status,
      'video_url': videoUrl,
    };
  }

  /// Cria um ServiceOrder a partir do Map retornado pelo Supabase
  factory ServiceOrder.fromMap(Map<String, dynamic> map) {
    return ServiceOrder(
      id: map['id'] as String?,
      userId: map['user_id'] as String,
      urgencyType: map['urgency_type'] as String,
      scheduledDate: map['scheduled_date'] != null
          ? DateTime.parse(map['scheduled_date'] as String)
          : null,
      cleaningType: map['cleaning_type'] as String,
      bedrooms: map['bedrooms'] as int,
      bathrooms: map['bathrooms'] as int,
      estimatedPrice: (map['estimated_price'] as num).toDouble(),
      status: map['status'] as String? ?? 'pending',
      videoUrl: map['video_url'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
    );
  }
}
