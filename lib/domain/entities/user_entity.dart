class UserEntity {
  final String id;
  final String name;
  final String phone;
  final String role; // 'super_admin', 'vendor', 'customer'
  final String? shopName;
  final String? address;
  final String? businessActivity;
  final String status; // 'pending', 'active', 'inactive', 'rejected'
  final DateTime? createdAt;

  UserEntity({
    required this.id,
    required this.name,
    required this.phone,
    required this.role,
    this.shopName,
    this.address,
    this.businessActivity,
    this.status = 'active',
    this.createdAt,
  });

  bool get isApproved => status == 'active';
  bool get isPending => status == 'pending';
  bool get isInactive => status == 'inactive';
  bool get isRejected => status == 'rejected';

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'phone': phone,
    'role': role,
    'shop_name': shopName,
    'address': address,
    'business_activity': businessActivity,
    'status': status,
    'created_at': (createdAt ?? DateTime.now()).toIso8601String(),
  };

  factory UserEntity.fromMap(Map<String, dynamic> map) => UserEntity(
    id: map['id']?.toString() ?? '',
    name: map['name'] ?? '',
    phone: map['phone'] ?? '',
    role: map['role'] ?? 'customer',
    shopName: map['shop_name'] ?? map['shopName'],
    address: map['address'],
    businessActivity: map['business_activity'] ?? map['businessActivity'],
    status: map['status'] ?? (map['isApproved'] == false ? 'pending' : 'active'),
    createdAt: map['created_at'] != null ? DateTime.tryParse(map['created_at'].toString()) : null,
  );
}