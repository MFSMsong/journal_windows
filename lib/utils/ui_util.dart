/// UI 工具类
class UiUtil {
  /// 格式化金额
  static String formatMoney(double amount) {
    if (amount >= 10000) {
      return '¥${(amount / 10000).toStringAsFixed(2)}万';
    }
    return '¥${amount.toStringAsFixed(2)}';
  }

  /// 格式化日期
  static String formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    
    if (diff.inDays == 0) {
      if (diff.inHours == 0) {
        if (diff.inMinutes == 0) {
          return '刚刚';
        }
        return '${diff.inMinutes}分钟前';
      }
      return '${diff.inHours}小时前';
    } else if (diff.inDays == 1) {
      return '昨天';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}天前';
    } else {
      return '${date.month}月${date.day}日';
    }
  }

  /// 获取账单类型图标
  static String getExpenseIcon(String type) {
    const iconMap = {
      '餐饮': '🍜',
      '交通': '🚗',
      '购物': '🛒',
      '娱乐': '🎮',
      '医疗': '🏥',
      '教育': '📚',
      '住房': '🏠',
      '通讯': '📱',
      '水电': '💡',
      '工资': '💰',
      '奖金': '🎁',
      '投资': '📈',
      '兼职': '💼',
      '红包': '🧧',
      '其他': '📝',
    };
    return iconMap[type] ?? '📝';
  }
}
