
import 'dart:io';

import 'package:cryptography/cryptography.dart';
import 'package:treediary/config/global_data.dart';
import 'package:openssh_ed25519/openssh_ed25519.dart';
import 'package:path_provider/path_provider.dart';

import '../utils/string_utils.dart';

class SSHKey {

  String id = '';

  String publicKey = ''; // 公钥
  String privateKey = '';  //  私钥
  String passPhrase = '';  //  密码
  String publicKeyHash = ''; // 公钥Hash

  String publicKeyPath = ''; // 公钥路径
  String privateKeyPath = '';  //  私钥路径
  String passPhrasePath = '';  //  密码路径

  bool _isTmp = false;

  static Future<SSHKey> create({ required String publicKey, required String privateKey, String passPhrase = ''}) async{
    var key = SSHKey();
    key.publicKey = publicKey;
    key.privateKey = privateKey;
    key.passPhrase = passPhrase;
    key.id = StringUtils.randomString(16);
    //
    Directory appDir = await getApplicationDocumentsDirectory();
    Directory keyDir = Directory(appDir.path + '/tmpKey');
    if(!await keyDir.exists()){ await keyDir.create(recursive: true); }
    key.privateKeyPath = keyDir.path + '/${key.id}.pri';
    key.publicKeyPath = keyDir.path + '/${key.id}.pub';
    key.passPhrasePath = keyDir.path + '/${key.id}.pas';
    File(key.privateKeyPath).writeAsString(key.privateKey);
    File(key.publicKeyPath).writeAsString(key.publicKey);
    if(key.passPhrase.isNotEmpty){
      File(key.passPhrasePath).writeAsString(key.publicKey);
    }
    key._isTmp = true;
    return key;
  }

  static generate() async{
    final keyPair = await Ed25519().newKeyPair();
    var privateBytes = await keyPair.extractPrivateKeyBytes();
    var public = await keyPair.extractPublicKey();
    var publicBytes = public.bytes;
    var publicStr = encodeEd25519Public(publicBytes);
    var privateStr = encodeEd25519Private(privateBytes: privateBytes, publicBytes: publicBytes,);

//    publicStr = 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC17qM/sO2hdGqF5wAK43gHWE49MT1NWiqeUy9enDSR/GfskBU/eruyPYvvuJaLIo9F5uqMg5ekh5rWClFV20gguwTm/k1bibz8etZTQBXr2sxpUDLbZQ35KgxGoDAGIv4AAJlYGFdvjjzDEkzWvGWQMghAlybGa2UUmaxYmmnFRTRgabMhPSPsxIaFmWKxD6cGGd441wtF/jwfUtw6LgF94YqTfoaEt5rz65Xs6qEl0Y01vRHS8LOSe3gYOVuzTa7j2w5OccGYL2G1k1257d64VyX82GvY6QaeYMjwEteoxXasNmI5zKRWoJ+5javmHg52iVBM3OJqmPkKiTMb+udxTD0jsypYNpUu7X+GP0hMrjIyaQj/j9u2J4LrIXmVmwQ0YA09PftIqpBCxlwgaR/gHrEHayS3Y7Nx8GpEW4QxQKB9IahBtqtzeSkwGRh4Fqbdum7mTb6yu0YeVnj2QasOkrrnMDWDW9BbzrtekkU8JMXX39Vi3La/qDBTG3Yr5+u0FNgWuBGRDd7KqlfneyddweSz4txVdg1NdekaiAgAtE7ZUeCp0ACC4zY+PDVKR1s2G6xhN89Gc7XUKNvjuHckT8k3v6nIYKqLwssBcHANQ5ptACUZOIRPZvjmQ0orpXfpco4NAStOUcQjgnW9RSBeeIAn/nfUcITzX8ZnIX11Lw== liujie@liujiedeMacBook-Pro-2.local';
//    privateStr = '''
// -----BEGIN RSA PRIVATE KEY-----
// MIIJKQIBAAKCAgEAte6jP7DtoXRqhecACuN4B1hOPTE9TVoqnlMvXpw0kfxn7JAV
// P3q7sj2L77iWiyKPRebqjIOXpIea1gpRVdtIILsE5v5NW4m8/HrWU0AV69rMaVAy
// 22UN+SoMRqAwBiL+AACZWBhXb448wxJM1rxlkDIIQJcmxmtlFJmsWJppxUU0YGmz
// IT0j7MSGhZlisQ+nBhneONcLRf48H1LcOi4BfeGKk36GhLea8+uV7OqhJdGNNb0R
// 0vCzknt4GDlbs02u49sOTnHBmC9htZNdue3euFcl/Nhr2OkGnmDI8BLXqMV2rDZi
// OcykVqCfuY2r5h4OdolQTNziapj5CokzG/rncUw9I7MqWDaVLu1/hj9ITK4yMmkI
// /4/btieC6yF5lZsENGANPT37SKqQQsZcIGkf4B6xB2skt2OzcfBqRFuEMUCgfSGo
// Qbarc3kpMBkYeBam3bpu5k2+srtGHlZ49kGrDpK65zA1g1vQW867XpJFPCTF19/V
// Yty2v6gwUxt2K+frtBTYFrgRkQ3eyqpX53snXcHks+LcVXYNTXXpGogIALRO2VHg
// qdAAguM2Pjw1SkdbNhusYTfPRnO11Cjb47h3JE/JN7+pyGCqi8LLAXBwDUOabQAl
// GTiET2b45kNKK6V36XKODQErTlHEI4J1vUUgXniAJ/531HCE81/GZyF9dS8CAwEA
// AQKCAgEAmGDu1IqxDZi/G7X14CjTQHui1Dfom2AY8BDGTRzSHy/kL0wir89xZAGO
// slLNrG1eyPJ2owgYu9JkSj/MDfgi+l8J5Rs72Z6M7n9IAeRcN/ZDXTWx0vZZ9MZW
// D9VdQ9aNHZ1i0llY6nOcytoKB5U2D8cICGlRLcGHoPBxXKjATF0BWHtPcFiQPWAB
// N+bXtWthvoduC/d5Vr9wxd+V2xjrYO7GLXE84+4QV5qLMSr3nABeoJLiWeYG0Xqe
// hNONzakUAX5ZBjTbLEcLNJTgXLkx4P4FMDhoY/4Q8BgqVIHDpXT2R5kpPjX7sx7H
// iRdy0cN846Vw31/mN9g2Rq/RYe8NZvsT+m6OqaC70HipfkZvdEt8gDMWutAsFd/j
// m/b4zXYiziGG4ERbyTpw6IvuIB3BJgmFWqUqRXrPJpAxpGexf29yIXsee3UgQq7e
// 9M2NNnh/1zDTzd38pmDCP/RiJ1LJ+KbTnIXPGNFO0pmmZanZKgm3X9swFbdxOqmL
// luDbdE0P0Gv+/JN6agDsik6+ijqgRGjq3HNm//w/AfyzTrk09WVPjhyrXkp0MfYL
// ikS0zNWkRcNGCOWclmylraShiKHqkAhVzWkn2O0T1p0Y8y3Kqp6Xpmc4vj9sCjMC
// 7F7FRi9KGUxVdSQ1dstg8fFWEphrvgOh0uftqnMdoDC2nOEc/8kCggEBANy0Oz1F
// vmC7JBiDALBEqeXLXZxxOXKUkvWwaTzoMlmKC7KX2CcloCaH6aQA8jNOqdko6FuL
// vztFQ2cq8PeJUz8rJkakjAmRz8iUcUDKIOSYGliamCP3zocl2XlEou8jQ1ahvNZz
// WPm5GKXUgzWVVwEu4T2IZdbFQSGpDAy3UaaKyGNeChnjm/QxO4DOOQ95GPEpvdCM
// abyJLV/7xLIXk4fpCPs52XxpPH/K6ZoGt9sffWFwebscGjap2Ur3OolJWwDqZcAI
// EtuaAkTXmALL0aap/BkPwvmoWCD+27Ay6Pb7rT2kIJEu4NTj8PsviL/NjJKB5ocm
// Ef4jfjrcEg5ye50CggEBANMHD6cKHseKiaqIOJtCBk29hyKR9DUAx4OUtn9m8MiL
// PblEaq9FMKVgyHISOFE02HFAvvYN6l8T5f+lYD8+ZfSUOSViKHQuECLfnpVJjQDE
// 8QmavdpBxW4W33AOqE0xlhxJDmYJCvrg1Oo5oz3WQVjrDuRzwkaTCb2aGA77WIea
// +lkH4IiZp/IYBxvg185qXSehIaYT2qPbhg0plucIjwpk7i5XGuuEJsfeyS9jGjPH
// Et3bYbZwo5fRUBPQqn4iyOOJ6s9jZCHitRzaUI/qm4XL1vJrmv+TMHN+plGMMiLx
// hHOQRibRVZKXcgiuKBp+QtW//dxosu+hi8MR66MBWDsCggEAS5fTvn3X4ivXBipA
// nx81jgakzoOdaJho6Yv9z6W8MRzuOsJ1f5sMioX8yXalfltQI5g2Vby8yCFGH9z+
// YdqAT9+IoaOUb2ao44usasOQlpteUsDIoXEsJPAa18VhhUTvuIl3M4CYlhgG0C3E
// ryKyhS44aaoBL5mqYEwVW3milsdsMVSxYwKplO8T8V8w/hK9L0TbxcWCJdhaWUjT
// qygWGPQBZoL+8fTdiuvGLUJl0MCtYiVzHFpYxCZSzbF2NDWS3PJr3WUmiF7srgWm
// BDcpXMtWFINohbhaTxrbxjL5xjaXtMg1e2SyD1jvXil+zisqHbgubFXmzcP8ZU6h
// RJ+DpQKCAQBmS6D5zz0Wa4DKitgt4vadTseoKWphGyycC0XgQm1sOZtFKPYyWm73
// bBAew9hK/TwCwmkPa7V2O3Yd0/PxFHVl90gwaAHGN+IYlaARLCNPASj7B+kKWSG0
// eR/8+Q36xZPHyF5TdgS9kqmDlUcdnbP1v5Rrh/XgMjzhjUYmVQ8YRTcgW2IrtZil
// EaK4j+jtJcBcio5+LFerYKn9zXBaNFrqpfyTuCPTkS8fak7KStcTzGfH5iXaw4V5
// /bw8rsVG+eO58UxDFiIfDv/OqcGt0gNr+2EKCMGNLLOq+PT0yOow6DTVtFVdUdKS
// ihl8PbgxB42sgjI0WwiKgxv2BsTcMrWrAoIBAQDBoMWdtbxGbPgbqnHc6YiDkvvi
// 93QZY1k1DyQFrYrx8Muwk1JX5d7ELouFkKI4dBOj79heLRaVL7aLQH/9hkbrIEtc
// Fst8UezWaGA49FuBSVkKPTTrF5MElPjRjq2JvNn4Vp99aaNRxp8d9YsalbKHG/XK
// uYUa8ruWBQw0PxGsMbJXhVnk+SAkIT3+eTdfqMFXcPIni7mCJaT/JNR74pFfGQOb
// YMYLBx2HCNoFbOJ9HYmYuK0IriU5Gn2+RYQYIEPoVGXGfXG2uljo6QWg7LaNmWgt
// 9fUl6sq+OCS37ByvaIVysC4FWQVaczNv+VR8EnwwSUtGfJBCItpS9h6nMJ1l
// -----END RSA PRIVATE KEY-----
// ''';
    return await create(publicKey: publicStr, privateKey: privateStr);
  }

  static SSHKey? onlyKeyPathSync(String id, {bool isTmp = false}){
    if(id.isEmpty){ return null; }
    var key = SSHKey();
    key.id = id;
    String keyDirPath = Global.documentsDirectoryPath + (isTmp ?  '/tmpKey' : '/key');
    key.privateKeyPath = keyDirPath + '/${key.id}.pri';
    key.publicKeyPath = keyDirPath + '/${key.id}.pub';
    key.passPhrasePath = keyDirPath + '/${key.id}.pas';
    return key;
  }

  static Future<SSHKey?> readById(String id, {bool isTmp = false}) async{
    var key = SSHKey.onlyKeyPathSync(id, isTmp: isTmp);
    if(key == null){
      return null;
    }
    var privateKey = File(key.privateKeyPath);
    var publicKey = File(key.publicKeyPath);
    var passPhrase = File(key.passPhrasePath);
    if(await privateKey.exists()){ key.privateKey = await privateKey.readAsString(); }
    if(await publicKey.exists()){ key.publicKey = await publicKey.readAsString(); }
    if(await passPhrase.exists()){ key.passPhrase = await passPhrase.readAsString(); }
    if(key.privateKey.isEmpty || key.publicKey.isEmpty || key.privateKeyPath.isEmpty || key.publicKeyPath.isEmpty){
      return null;
    }
    return key;
  }

  delete() async{
    if(id.isEmpty){ return; }
    return await SSHKey.deleteById(id, isTmp: _isTmp);
  }

  // 首次生成的key，存放在tmpKey文件夹里，需要调用upgrade后，才会移到正式key文件夹
  upgrade() async{
    if(!_isTmp){ return; }
    Directory appDir = await getApplicationDocumentsDirectory();
    Directory keyDir = Directory(appDir.path + '/key');
    if(!await keyDir.exists()){ await keyDir.create(recursive: true); }
    var priPath = keyDir.path + '/$id.pri';
    var pubPath = keyDir.path + '/$id.pub';
    var pasPath = keyDir.path + '/$id.pas';
    var privateKey = File(privateKeyPath);
    var publicKey = File(publicKeyPath);
    var passPhrase = File(passPhrasePath);
    if(await privateKey.exists()){ await privateKey.rename(priPath); }
    if(await publicKey.exists()){ await publicKey.rename(pubPath); }
    if(await passPhrase.exists()){ await passPhrase.rename(pasPath); }
    privateKeyPath = priPath;
    publicKeyPath = pubPath;
    passPhrasePath = pasPath;
    _isTmp = false;
  }

  static deleteById(String id, {bool isTmp = false}) async{
    Directory appDir = await getApplicationDocumentsDirectory();
    Directory keyDir = Directory(appDir.path + (isTmp ? '/tmpKey' : '/key'));
    if(!await keyDir.exists()){ await keyDir.create(recursive: true); }
    var privateKey = File(keyDir.path + '/${id}.pri');
    var publicKey = File(keyDir.path + '/${id}.pub');
    var passPhrase = File(keyDir.path + '/${id}.pas');
    if(await privateKey.exists()){ await privateKey.delete(); }
    if(await publicKey.exists()){ await publicKey.delete(); }
    if(await passPhrase.exists()){ await passPhrase.delete(); }
  }

  @override
  String toString(){ return 'publicKey:$publicKey\nprivateKey:$privateKey\npassPhrase$passPhrase\npublicKeyHash:$publicKeyHash\npublicKeyPath:$publicKeyPath\nprivateKeyPath:$privateKeyPath\npassPhrasePath::$passPhrasePath'; }

}
