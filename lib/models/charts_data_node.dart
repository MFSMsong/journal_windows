/// 图表数据节点
class ChartsDataNode {
  String name;
  double value;

  ChartsDataNode({
    required this.name,
    required this.value,
  });

  factory ChartsDataNode.fromJson(Map<String, dynamic> json) {
    return ChartsDataNode(
      name: json['name'] ?? '',
      value: (json['value'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'value': value,
    };
  }

  @override
  String toString() {
    return 'ChartsDataNode{name: $name, value: $value}';
  }
}
