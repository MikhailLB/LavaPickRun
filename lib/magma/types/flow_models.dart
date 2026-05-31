enum CraterMode {
  web,
  game,
  fresh;

  String toKey() {
    switch (this) {
      case CraterMode.web:   return 'web';
      case CraterMode.game:  return 'game';
      case CraterMode.fresh: return 'fresh';
    }
  }

  static CraterMode fromKey(String? raw) {
    switch (raw) {
      case 'web':
      case 'browser':
        return CraterMode.web;
      case 'game':
      case 'arcade':
        return CraterMode.game;
      default:
        return CraterMode.fresh;
    }
  }
}

class FlowReply {
  final bool granted;
  final String? destination;
  final String? note;
  final int? expiresAt;

  const FlowReply._({
    required this.granted,
    this.destination,
    this.note,
    this.expiresAt,
  });

  factory FlowReply.fromMap(Map<String, dynamic> raw) {
    final granted = (raw['ok'] as bool?)        ??
                    (raw['granted'] as bool?)    ??
                    (raw['accepted'] as bool?)   ??
                    false;

    final destination = raw['url'] as String?        ??
                        raw['link'] as String?       ??
                        raw['target'] as String?     ??
                        raw['destination'] as String?;

    final note = raw['message'] as String? ??
                 raw['note'] as String?    ??
                 raw['reason'] as String?;

    final dynamic ttl = raw['expires'] ?? raw['expires_at'] ?? raw['valid_until'];
    int? expires;
    if (ttl is int) {
      expires = ttl;
    } else if (ttl is num) {
      expires = ttl.toInt();
    } else if (ttl is String) {
      expires = int.tryParse(ttl);
    }

    return FlowReply._(
      granted: granted,
      destination: destination,
      note: note,
      expiresAt: expires,
    );
  }

  factory FlowReply.declined(String reason) =>
      FlowReply._(granted: false, note: reason);
}
