import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/smb_connection.dart';
import '../services/smb_service.dart';

class SmbDialog extends StatefulWidget {
  final SmbConnection? existing;
  const SmbDialog({super.key, this.existing});

  @override
  State<SmbDialog> createState() => _SmbDialogState();
}

class _SmbDialogState extends State<SmbDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _hostCtrl;
  late final TextEditingController _shareCtrl;
  late final TextEditingController _userCtrl;
  late final TextEditingController _passCtrl;
  late final TextEditingController _domainCtrl;
  late final TextEditingController _pathCtrl;

  @override
  void initState() {
    super.initState();
    final c = widget.existing;
    _nameCtrl = TextEditingController(text: c?.name ?? '');
    _hostCtrl = TextEditingController(text: c?.host ?? '');
    _shareCtrl = TextEditingController(text: c?.shareName ?? '');
    _userCtrl = TextEditingController(text: c?.username ?? '');
    _passCtrl = TextEditingController(text: c?.password ?? '');
    _domainCtrl = TextEditingController(text: c?.domain ?? '');
    _pathCtrl = TextEditingController(text: '');
  }

  @override
  void dispose() {
    for (final c in [_nameCtrl, _hostCtrl, _shareCtrl, _userCtrl, _passCtrl, _domainCtrl, _pathCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final conn = SmbConnection(
      id: widget.existing?.id ?? const Uuid().v4(),
      name: _nameCtrl.text.trim(),
      host: _hostCtrl.text.trim(),
      shareName: _shareCtrl.text.trim(),
      username: _userCtrl.text.trim(),
      password: _passCtrl.text,
      domain: _domainCtrl.text.trim().isEmpty ? null : _domainCtrl.text.trim(),
    );
    Navigator.pop(context, {'connection': conn, 'path': _pathCtrl.text.trim()});
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existing == null ? 'SMB 연결 추가' : 'SMB 연결 편집'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _field(_nameCtrl, '연결 이름', required: true),
                _field(_hostCtrl, '호스트 (IP 또는 hostname)', required: true),
                _field(_shareCtrl, '공유 폴더명', required: true),
                _field(_userCtrl, '사용자명', required: true),
                _field(_passCtrl, '비밀번호', obscure: true),
                _field(_domainCtrl, '도메인 (선택)'),
                _field(_pathCtrl, '하위 경로 (선택, 예: photos/2024)'),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소')),
        FilledButton(onPressed: _submit, child: const Text('연결')),
      ],
    );
  }

  Widget _field(TextEditingController ctrl, String label,
      {bool required = false, bool obscure = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: ctrl,
        obscureText: obscure,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        validator: required
            ? (v) => (v == null || v.trim().isEmpty) ? '$label을 입력하세요' : null
            : null,
      ),
    );
  }
}
