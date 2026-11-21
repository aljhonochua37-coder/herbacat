class OrderItem {
  final String herbId;
  final String herbName;
  final int quantity;
  final double price;
  final String imageUrl;

  const OrderItem({
    required this.herbId,
    required this.herbName,
    required this.quantity,
    required this.price,
    this.imageUrl = '',
  });

  double get subtotal => price * quantity;

  Map<String, dynamic> toMap() {
    return {
      'herbId': herbId,
      'herbName': herbName,
      'quantity': quantity,
      'price': price,
      'imageUrl': imageUrl,
    };
  }

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      herbId: map['herbId'] as String? ?? '',
      herbName: map['herbName'] as String? ?? 'Herbal Remedy',
      quantity: (map['quantity'] as num?)?.toInt() ?? 1,
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      imageUrl: map['imageUrl'] as String? ?? '',
    );
  }
}

enum OrderStatus {
  pending,
  shipped,
  delivered,
  cancelled;

  String get displayName {
    switch (this) {
      case OrderStatus.pending:
        return 'Pending Dispatch';
      case OrderStatus.shipped:
        return 'In Transit (Shipped)';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  static OrderStatus fromString(String? val) {
    switch (val?.toLowerCase()) {
      case 'shipped':
        return OrderStatus.shipped;
      case 'delivered':
        return OrderStatus.delivered;
      case 'cancelled':
        return OrderStatus.cancelled;
      case 'pending':
      default:
        return OrderStatus.pending;
    }
  }
}

class HerbOrder {
  final String id;
  final String userId;
  final String userEmail;
  final String userName;
  final String shippingAddress;
  final String municipality;
  final OrderStatus status;
  final List<OrderItem> items;
  final double totalAmount;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const HerbOrder({
    required this.id,
    required this.userId,
    required this.userEmail,
    required this.userName,
    required this.shippingAddress,
    required this.municipality,
    required this.status,
    required this.items,
    required this.totalAmount,
    required this.createdAt,
    this.updatedAt,
  });

  HerbOrder copyWith({
    String? id,
    String? userId,
    String? userEmail,
    String? userName,
    String? shippingAddress,
    String? municipality,
    OrderStatus? status,
    List<OrderItem>? items,
    double? totalAmount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return HerbOrder(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userEmail: userEmail ?? this.userEmail,
      userName: userName ?? this.userName,
      shippingAddress: shippingAddress ?? this.shippingAddress,
      municipality: municipality ?? this.municipality,
      status: status ?? this.status,
      items: items ?? this.items,
      totalAmount: totalAmount ?? this.totalAmount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'userEmail': userEmail,
      'userName': userName,
      'shippingAddress': shippingAddress,
      'municipality': municipality,
      'status': status.name,
      'items': items.map((e) => e.toMap()).toList(),
      'totalAmount': totalAmount,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory HerbOrder.fromMap(Map<String, dynamic> map, {String? docId}) {
    final rawItems = map['items'] as List<dynamic>? ?? [];
    return HerbOrder(
      id: docId ?? map['id'] as String? ?? 'ord_${DateTime.now().millisecondsSinceEpoch}',
      userId: map['userId'] as String? ?? '',
      userEmail: map['userEmail'] as String? ?? '',
      userName: map['userName'] as String? ?? 'Community Forager',
      shippingAddress: map['shippingAddress'] as String? ?? '',
      municipality: map['municipality'] as String? ?? 'Virac',
      status: OrderStatus.fromString(map['status'] as String?),
      items: rawItems
          .whereType<Map<String, dynamic>>()
          .map((item) => OrderItem.fromMap(item))
          .toList(),
      totalAmount: (map['totalAmount'] as num?)?.toDouble() ?? 0.0,
      createdAt: _parseDate(map['createdAt']),
      updatedAt: map['updatedAt'] != null ? _parseDate(map['updatedAt']) : null,
    );
  }

  static DateTime _parseDate(dynamic val) {
    if (val is DateTime) return val;
    if (val is String) {
      final parsed = DateTime.tryParse(val);
      if (parsed != null) return parsed;
    }
    return DateTime.now();
  }
}
