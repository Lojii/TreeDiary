
import 'package:libgit2dart/libgit2dart.dart';


enum GitAsyncCallbackResType {
  counting,   // 计算中
  compressing,// 压缩中
  transfer,   // 传输中
  pushing,    // 推送中
  updateTips, // 结果更新
  unknown,    // 未知
}


class GitAsyncCallbackRes{
  GitAsyncCallbackResType type;
  int total; /// 总数
  int complete; /// 完成数
  int percentage; /// 0-100
  int bytes;   /// 数据量
  String log; ///
  /// updateTips、pushing
  String refName;
  String oldOidSha;
  String newOidSha;
  String pushMessage;

  GitAsyncCallbackRes({
    this.pushMessage = '' ,
    this.oldOidSha = '' ,
    this.newOidSha = '' ,
    this.refName = '' ,
    this.type = GitAsyncCallbackResType.unknown,
    this.total = 0,
    this.complete = 0,
    this.percentage = 0,
    this.bytes = 0,
    this.log = ''
  });
}

class GitCallbacks extends Callbacks{
  void Function(GitAsyncCallbackRes) callBack;

  GitCallbacks({Credentials? credentials, required this.callBack, StringBuffer? strBuff}) : super(
      credentials: credentials,
      transferProgress: (TransferProgress stats) { /// 此处数据是连续的
        int indexedObjects = stats.indexedObjects;
        int totalObjects = stats.totalObjects;
        int receivedBytes = stats.receivedBytes;
        int percentage = ((indexedObjects / totalObjects) * 100).truncate();
        callBack(GitAsyncCallbackRes(
            type: GitAsyncCallbackResType.transfer,
            total: totalObjects,
            complete: indexedObjects,
            bytes: receivedBytes,
            percentage: percentage,
            log: 'Transfer objects: ${percentage.toString().padLeft(3,' ')}% (${stats.indexedObjects}/${stats.totalObjects}) bytes:${stats.receivedBytes}\r'
        ));
      },
      sidebandProgress: (progress){ /// 这里的数据不是连续的,需要进行截取
        strBuff ??= StringBuffer();
        strBuff!.write(progress);
        String str = strBuff.toString();
        List<String> lines = [];
        String lastPart = '';
        if(!str.endsWith('\r') && !str.endsWith('\n')){
          lastPart= str.split('\n').last.split('\r').last;
          if(lastPart.isNotEmpty){ str = str.replaceRange(str.length - lastPart.length, null, ''); } // 移除尾部有缺失的字符,只处理完整的行
        }
        var np = str.split('\n');
        for(var p in np){
          var rp = p.split('\r');
          for(var line in rp){
            if(line.isNotEmpty){ lines.add(line); }
          }
        }
        strBuff?.clear();
        strBuff!.write(lastPart);

        for(var line in lines){
          var type = GitAsyncCallbackResType.unknown;
          var total = 0;
          var complete = 0;
          var percentage = 0;
          if(line.startsWith('Counting objects: ') || line.startsWith('Compressing objects: ')){
            if(line.startsWith('Counting objects: ')){
              type = GitAsyncCallbackResType.counting;
            }else if(line.startsWith('Compressing objects: ')){
              type = GitAsyncCallbackResType.compressing;
            }
            var parts = line.split(' ');
            if(parts.length >= 2){
              String percentagePart = parts[parts.length - 2].replaceAll('%', '');
              percentage = int.tryParse(percentagePart) ?? 0;
              String completeTotalPart = parts[parts.length - 1].replaceAll('(', '').replaceAll(')', '');
              var ps = completeTotalPart.split('/');
              if(ps.length == 2){
                complete = int.tryParse(ps.first) ?? 0;
                total = int.tryParse(ps.last) ?? 0;
              }
            }
          }
          callBack(GitAsyncCallbackRes(type: type,total:total,complete:complete,percentage:percentage, log: '$line\r'));
        }

      },
      pushUpdateReference: (refName, message){ /// TODO:push信息处理
        callBack(GitAsyncCallbackRes(
            type: GitAsyncCallbackResType.pushing,
            refName: refName,
            pushMessage: message,
            log: 'Pushing $refName - $message\r'
        ));
      },
      updateTips: (refName, oldO, newO){
        callBack(GitAsyncCallbackRes(
            type: GitAsyncCallbackResType.updateTips,
            refName:refName,
            oldOidSha: oldO.sha,
            newOidSha: newO.sha,
            log: 'updateTips $refName: ${oldO.sha} -> ${newO.sha}\r'
        ));
      }
  );
}
