
class TimeUtils{

  static DateTime timestampToDate(int timestamp) {
    DateTime dateTime = DateTime.now();

    ///如果是十三位时间戳返回这个
    if (timestamp.toString().length == 13) {
      dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    } else if (timestamp.toString().length == 16) {
      ///如果是十六位时间戳
      dateTime = DateTime.fromMicrosecondsSinceEpoch(timestamp);
    }
    return dateTime;
  }

  ///日期转时间戳
  static int dateToTimestamp(String date, {isMicroseconds = false}) {
    DateTime dateTime = DateTime.parse(date);
    int timestamp = dateTime.millisecondsSinceEpoch;
    if (isMicroseconds) {
      timestamp = dateTime.microsecondsSinceEpoch;
    }
    return timestamp;
  }

  ///时间戳转日期
  ///[timestamp] 时间戳
  ///[onlyNeedDate ] 是否只显示日期 舍去时间
  static String? timestampToDateStr(String timestampStr, {onlyNeedDate = false}) {
    var timestamp = int.tryParse(timestampStr) ?? 0;
    if(timestamp <= 0 || timestampStr.isEmpty){
      // return '----/--/-- --:--:--';
      return null;
    }
    DateTime dataTime = timestampToDate(timestamp);
    String dateTime = dataTime.toString();

    ///去掉时间后面的.000
    dateTime = dateTime.substring(0, dateTime.length - 4);
    if (onlyNeedDate) {
      List<String> dataList = dateTime.split(" ");
      dateTime = dataList[0];
    }
    return dateTime;
  }
}