import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/viewer_provider.dart';
import '../services/smb_service.dart';
import '../models/smb_connection.dart';
import '../widgets/smb_dialog.dart';
import 'viewer_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final SmbService _smbService = SmbService();
  List<SmbConnection> _connections = [];

  @override
  void initState() {
    super.initState();
    _loadConnections();
  }

  Future<void> _loadConnections() async {
    final conns = await _smbService.loadConnections();
    setState(() => _connections = conns);
  }

  Future<void> _openViewer(ViewerProvider provider) async {
    if (!provider.hasImages) return;
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ViewerScreen()),
    );
  }

  Future<void> _openFolder(ViewerProvider provider) async {
    await provider.openLocalFolder();
    await _openViewer(provider);
  }

  Future<void> _openArchive(ViewerProvider provider) async {
    await provider.openArchive();
    await _openViewer(provider);
  }

  Future<void> _openSmb(ViewerProvider provider, SmbConnection conn) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => SmbDialog(existing: conn),
    );
    if (result == null) return;
    final path = result['path'] as String? ?? '';
    await provider.openSmb(conn, path);
    await _openViewer(provider);
  }

  Future<void> _addConnection() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => const SmbDialog(),
    );
    if (result == null) return;
    final conn = result['connection'] as SmbConnection;
    await _smbService.saveConnection(conn);
    await _loadConnections();
  }

  Future<void> _deleteConnection(String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('연결 삭제'),
        content: const Text('이 연결을 삭제하시겠습니까?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('취소')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('삭제')),
        ],
      ),
    );
    if (ok != true) return;
    await _smbService.deleteConnection(id);
    await _loadConnections();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ViewerProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('이미지 뷰어'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 로컬 열기
          _SectionHeader(title: '로컬 파일'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _ActionCard(
                  icon: Icons.folder_open,
                  label: '폴더 열기',
                  onTap: () => _openFolder(provider),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ActionCard(
                  icon: Icons.folder_zip,
                  label: '압축 파일 열기\n(zip, cbz)',
                  onTap: () => _openArchive(provider),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // SMB (Android에서만 또는 Windows에서도)
          if (!Platform.isWindows || true) ...[
            Row(
              children: [
                const _SectionHeader(title: 'SMB 원격 저장소'),
                const Spacer(),
                TextButton.icon(
                  onPressed: _addConnection,
                  icon: const Icon(Icons.add),
                  label: const Text('추가'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_connections.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(
                    child: Text('SMB 연결이 없습니다\n+ 추가 버튼으로 추가하세요',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey)),
                  ),
                ),
              )
            else
              ..._connections.map(
                (conn) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const Icon(Icons.storage),
                    title: Text(conn.name),
                    subtitle: Text('\\\\${conn.host}\\${conn.shareName}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _deleteConnection(conn.id),
                        ),
                        FilledButton(
                          onPressed: () => _openSmb(provider, conn),
                          child: const Text('열기'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],

          // 에러 표시
          if (provider.error != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Card(
                color: Theme.of(context).colorScheme.errorContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(provider.error!,
                      style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold));
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionCard({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(icon, size: 40),
              const SizedBox(height: 12),
              Text(label, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
