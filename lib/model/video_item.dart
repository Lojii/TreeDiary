class VideoItem {

  String? thumbPath; // 缩略图路径
  String path; // 视频路径
  String size;  // 大小
  VideoItem({required this.path,this.thumbPath, this.size = '0'});

  String _size(){
    print(size);
    double s = double.parse(size);
    if(s < 1024){
      return '${s.toStringAsFixed(2)}KB';
    }
    if(s < 1024*1024){
      return '${(s / 1024).toStringAsFixed(2)}MB';
    }
    if(s < 1024*1024*1024){
      return '${(s / 1024 / 1024).toStringAsFixed(2)}GB';
    }
    // if(s < 1024*1024*1024*1024){
    //   return '${(s / 1024 / 1024 / 1024).toStringAsFixed(2)}GB';
    // }
    return '';
  }

  String get sizeStr => _size();

}
