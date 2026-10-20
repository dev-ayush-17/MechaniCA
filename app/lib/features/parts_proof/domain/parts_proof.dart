import '../../../core/error/result.dart';

enum ProofKind { before, after, oldPart }

extension ProofKindLabel on ProofKind {
  String get label => switch (this) {
        ProofKind.before => 'Before',
        ProofKind.after => 'After',
        ProofKind.oldPart => 'Old part',
      };

  String get apiValue => switch (this) {
        ProofKind.before => 'before',
        ProofKind.after => 'after',
        ProofKind.oldPart => 'old_part',
      };
}

class PartsProof {
  const PartsProof({
    required this.id,
    required this.bookingId,
    required this.lineId,
    required this.kind,
    required this.path,
    this.uploadUrl,
    this.hidden = false,
    this.metadata = const {},
  });

  final String id;
  final String bookingId;
  final String lineId;
  final ProofKind kind;
  final String path;
  final String? uploadUrl;
  final bool hidden;
  final Map<String, String> metadata;
}

class QueuedProof {
  const QueuedProof({
    required this.kind,
    required this.localPath,
    this.storagePath,
    this.uploaded = false,
  });

  final ProofKind kind;
  final String localPath;
  final String? storagePath;
  final bool uploaded;

  QueuedProof copyWith({String? storagePath, bool? uploaded}) => QueuedProof(
        kind: kind,
        localPath: localPath,
        storagePath: storagePath ?? this.storagePath,
        uploaded: uploaded ?? this.uploaded,
      );
}

class ProofUploadQueue {
  ProofUploadQueue({Map<ProofKind, QueuedProof>? seed}) : _items = seed ?? {};

  final Map<ProofKind, QueuedProof> _items;

  void enqueue(QueuedProof item) => _items[item.kind] = item;

  QueuedProof? operator [](ProofKind kind) => _items[kind];

  int get queuedCount => _items.length;

  bool get hasAllThree => _items.length >= 3;

  List<QueuedProof> get items => List.unmodifiable(_items.values);
}

abstract interface class PartsProofRepository {
  Future<Result<PartsProof>> create({
    required String token,
    required String bookingId,
    required String lineId,
    required ProofKind kind,
  });

  Future<Result<List<PartsProof>>> list({
    required String token,
    required String bookingId,
  });
}
