// lib/models/slot.dart
import 'sport.dart';

class Slot {
  Slot({
    required this.id,
    required this.sport,
    required this.title,
    required this.location,
    required this.beginsAt,
    required this.endsAt,
    required this.capacity,
    required this.price,
  });

  final int      id;
  final Sport    sport;
  final String   title;
  final String   location;
  final DateTime beginsAt;
  final DateTime endsAt;
  final int      capacity;
  final double   price;

  /// 允许后端返回 sport=ID 或 sport=Map 两种格式
  factory Slot.fromJson(Map<String, dynamic> j) {
    final dynamic sportRaw = j['sport'];

    /// 解析 Sport
    late final Sport sport;
    if (sportRaw is Map<String, dynamic>) {
      sport = Sport.fromJson(sportRaw);
    } else if (sportRaw is int) {
      // 如果只有 ID，就先创建一个占位 Sport；需要时再去懒加载详情
      sport = Sport(id: sportRaw, name: '', banner: '', description: '');
    } else {
      throw const FormatException('Unsupported sport payload');
    }

    return Slot(
      id:        j['id']               as int,
      sport:     sport,
      title:     j['title']            as String,
      location:  j['location']         as String,
      beginsAt:  DateTime.parse(j['begins_at'] as String),
      endsAt:    DateTime.parse(j['ends_at']   as String),
      capacity:  j['capacity']         as int,
      price:     double.parse(j['price'].toString()),
    );
  }

  /// 方便之后可能的写操作
  Map<String, dynamic> toJson() => {
    'id'        : id,
    'sport'     : sport.id,
    'title'     : title,
    'location'  : location,
    'begins_at' : beginsAt.toIso8601String(),
    'ends_at'   : endsAt.toIso8601String(),
    'capacity'  : capacity,
    'price'     : price,
  };
}
