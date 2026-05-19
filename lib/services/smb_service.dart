import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/smb_connection.dart';
import '../models/image_file.dart';

class SmbService {
  static const _prefsKey = 'smb_connections';

  Future<List<SmbConnection>> loadConnections() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_prefsKey) ?? [];
    return jsonList.map((e) => SmbConnection.fromJson(jsonDecode(e))).toList();
  }

  Future<void> saveConnection(SmbConnection conn) async {
    final prefs = await SharedPreferences.getInstance();
    final connections = await loadConnections();
    final idx = connections.indexWhere((c) => c.id == conn.id);
    if (idx >= 0) {
      connections[idx] = conn;
    } else {
      connections.add(conn);
    }
    await prefs.setStringList(
      _prefsKey,
      connections.map((c) => jsonEncode(c.toJson())).toList(),
    );
  }

  Future<void> deleteConnection(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final connections = await loadConnections();
    connections.removeWhere((c) => c.id == id);
    await prefs.setStringList(
      _prefsKey,
      connections.map((c) => jsonEncode(c.toJson())).toList(),
    );
  }

  // SMB 파일 목록 가져오기
  // smb2 패키지 사용: https://pub.dev/packages/smb2
  Future<List<ImageFile>> listFiles(SmbConnection conn, String remotePath) async {
    try {
      // smb2 패키지 API 예시:
      // final client = Smb2Client(
      //   host: conn.host,
      //   shareName: conn.shareName,
      //   username: conn.username,
      //   password: conn.password,
      // );
      // final files = await client.listDirectory(remotePath);
      // return files
      //   .where((f) => ImageFile.isSupported(f.name) || ImageFile.isArchive(f.name))
      //   .map((f) => ImageFile(
      //     name: f.name,
      //     path: '$remotePath/${f.name}',
      //     sourceType: ImageSourceType.smb,
      //     smbConnectionId: conn.id,
      //   ))
      //   .toList()
      //   ..sort((a, b) => a.name.compareTo(b.name));

      throw UnimplementedError(
        'SMB 연결 구현 필요\n'
        'smb2 패키지 설치 후 위 주석 코드를 활성화하세요\n'
        'https://pub.dev/packages/smb2',
      );
    } catch (e) {
      throw Exception('SMB 연결 실패: $e');
    }
  }

  Future<Uint8List> readFileBytes(SmbConnection conn, ImageFile file) async {
    try {
      // final client = Smb2Client(...);
      // return await client.readFile(file.path);
      throw UnimplementedError('SMB 파일 읽기 구현 필요');
    } catch (e) {
      throw Exception('파일 읽기 실패: $e');
    }
  }
}
