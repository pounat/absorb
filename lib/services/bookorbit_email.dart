/// Sending books by email on BookOrbit: mail servers, the devices and
/// people books go to, groups of them, message templates and what was sent.
/// The calls live on BookOrbitApiService (bookorbit_email_api.dart).
library;

DateTime? _date(Object? v) => v is String ? DateTime.tryParse(v)?.toLocal() : null;
int? _intOrNull(Object? v) => v is num ? v.toInt() : int.tryParse('${v ?? ''}');
String? _text(Object? v) => v is String && v.trim().isNotEmpty ? v : null;

/// Device types a BookOrbit recipient can be.
const boEmailDeviceTypes = ['kindle', 'kobo', 'other'];

/// Formats a recipient can ask for.
const boEmailFormats = ['epub', 'pdf', 'mobi', 'azw3', 'cbz', 'cbr', 'djvu'];

/// What Amazon's Send to Kindle takes by email since 2023.
const boKindleFormats = ['epub', 'pdf'];

List<String> boFormatsFor(String? deviceType) => deviceType == 'kindle' ? boKindleFormats : boEmailFormats;

bool boKindleAccepts(String format) => boKindleFormats.contains(format.toLowerCase());

const _audioFormats = {'m4b', 'mp3', 'm4a', 'opus', 'ogg', 'flac'};
const _bookFormats = {
  'epub', 'kepub', 'mobi', 'azw3', 'azw', 'fb2', 'pdf', 'djvu', 'cbz', 'cbr', 'cb7', 'cbx',
};

class BoMailServer {
  final int id;
  final int? ownerId;
  final String name;
  final String host;
  final int port;
  final String? username;
  final String? fromName;
  final String? fromAddress;
  final bool auth;
  final bool ssl;
  final bool startTls;
  final bool verifyTls;
  final bool isDefault;
  final bool isShared;
  final bool isSystem;
  final bool hasPassword;
  final DateTime? lastTestedAt;
  final bool? lastTestOk;
  final String? lastTestError;

  const BoMailServer({
    required this.id,
    this.ownerId,
    required this.name,
    required this.host,
    required this.port,
    this.username,
    this.fromName,
    this.fromAddress,
    this.auth = true,
    this.ssl = false,
    this.startTls = true,
    this.verifyTls = true,
    this.isDefault = false,
    this.isShared = false,
    this.isSystem = false,
    this.hasPassword = false,
    this.lastTestedAt,
    this.lastTestOk,
    this.lastTestError,
  });

  factory BoMailServer.fromJson(Map<String, dynamic> j) => BoMailServer(
        id: (j['id'] as num).toInt(),
        ownerId: _intOrNull(j['userId']),
        name: '${j['name'] ?? ''}',
        host: '${j['host'] ?? ''}',
        port: _intOrNull(j['port']) ?? 587,
        username: _text(j['username']),
        fromName: _text(j['fromName']),
        fromAddress: _text(j['fromAddress']),
        auth: j['auth'] != false,
        ssl: j['ssl'] == true,
        startTls: j['startTls'] == true,
        verifyTls: j['tlsRejectUnauthorized'] != false,
        isDefault: j['isDefault'] == true,
        isShared: j['isShared'] == true,
        isSystem: j['isSystemProvider'] == true,
        hasPassword: j['hasPassword'] == true,
        lastTestedAt: _date(j['lastTestedAt']),
        lastTestOk: j['lastTestOk'] is bool ? j['lastTestOk'] as bool : null,
        lastTestError: _text(j['lastTestError']),
      );

  bool ownedBy(String userId) => ownerId != null && '$ownerId' == userId;

  /// The address a Kindle has to approve before it takes mail from here.
  String? get sender => fromAddress ?? (username != null && username!.contains('@') ? username : null);

  BoMailSecurity get security => ssl
      ? BoMailSecurity.ssl
      : startTls
          ? BoMailSecurity.startTls
          : BoMailSecurity.none;
}

enum BoMailSecurity { startTls, ssl, none }

/// Ready-made settings for the mail services most people use.
class BoMailPreset {
  final String key;
  final String name;
  final String host;
  final int port;
  final BoMailSecurity security;
  final bool appPassword;

  const BoMailPreset(this.key, this.name, this.host, this.port, this.security, {this.appPassword = false});

  static const all = [
    BoMailPreset('gmail', 'Gmail', 'smtp.gmail.com', 587, BoMailSecurity.startTls, appPassword: true),
    BoMailPreset('outlook', 'Outlook', 'smtp-mail.outlook.com', 587, BoMailSecurity.startTls),
    BoMailPreset('icloud', 'iCloud Mail', 'smtp.mail.me.com', 587, BoMailSecurity.startTls, appPassword: true),
    BoMailPreset('fastmail', 'Fastmail', 'smtp.fastmail.com', 465, BoMailSecurity.ssl),
  ];

  static BoMailPreset? forHost(String host) {
    final h = host.trim().toLowerCase();
    for (final p in all) {
      if (p.host == h) return p;
    }
    return null;
  }
}

class BoEmailLastSend {
  final String? bookTitle;
  final String status;
  final DateTime? createdAt;
  final String? errorMessage;

  const BoEmailLastSend({this.bookTitle, required this.status, this.createdAt, this.errorMessage});

  static BoEmailLastSend? fromJson(Object? j) {
    if (j is! Map) return null;
    return BoEmailLastSend(
      bookTitle: _text(j['bookTitle']),
      status: '${j['status'] ?? 'sent'}',
      createdAt: _date(j['createdAt']),
      errorMessage: _text(j['errorMessage']),
    );
  }
}

/// Where a book can be sent: an e-reader's address, or a person's inbox.
class BoEmailDevice {
  final int id;
  final String name;
  final String email;
  final String? deviceType;
  final String? preferredFormat;
  final int? templateId;
  final String? readAlong;
  final BoEmailLastSend? lastSend;

  const BoEmailDevice({
    required this.id,
    required this.name,
    required this.email,
    this.deviceType,
    this.preferredFormat,
    this.templateId,
    this.readAlong,
    this.lastSend,
  });

  factory BoEmailDevice.fromJson(Map<String, dynamic> j) => BoEmailDevice(
        id: (j['id'] as num).toInt(),
        name: '${j['name'] ?? ''}',
        email: '${j['email'] ?? ''}',
        deviceType: _text(j['deviceType']),
        preferredFormat: _text(j['preferredFormat'])?.toLowerCase(),
        templateId: _intOrNull(j['defaultTemplateId']),
        readAlong: _text(j['readAloudDelivery']),
        lastSend: BoEmailLastSend.fromJson(j['lastSend']),
      );

  bool get isKindle => deviceType == 'kindle';
}

class BoEmailGroup {
  final int id;
  final String name;
  final int? templateId;
  final List<BoEmailDevice> members;

  const BoEmailGroup({required this.id, required this.name, this.templateId, this.members = const []});

  factory BoEmailGroup.fromJson(Map<String, dynamic> j) => BoEmailGroup(
        id: (j['id'] as num).toInt(),
        name: '${j['name'] ?? ''}',
        templateId: _intOrNull(j['defaultTemplateId']),
        members: [
          for (final m in (j['members'] as List? ?? const []).whereType<Map<String, dynamic>>()) BoEmailDevice.fromJson(m),
        ],
      );

  Set<int> get memberIds => {for (final m in members) m.id};
}

class BoEmailTemplate {
  final int id;
  final int? ownerId;
  final String name;
  final String subject;
  final String body;
  final bool isSystem;

  const BoEmailTemplate({
    required this.id,
    this.ownerId,
    required this.name,
    required this.subject,
    required this.body,
    this.isSystem = false,
  });

  factory BoEmailTemplate.fromJson(Map<String, dynamic> j) => BoEmailTemplate(
        id: (j['id'] as num).toInt(),
        ownerId: _intOrNull(j['userId']),
        name: '${j['name'] ?? ''}',
        subject: '${j['subject'] ?? ''}',
        body: '${j['bodyText'] ?? ''}',
        isSystem: j['isSystem'] == true,
      );
}

/// The names a template can use, replaced with the book's details when it goes out.
const boTemplateVariables = {
  'book': ['title', 'subtitle', 'authors', 'seriesName', 'seriesIndex', 'publisher', 'publishedYear', 'pageCount', 'isbn', 'language', 'tags'],
  'file': ['format', 'fileSize'],
  'other': ['senderName', 'appUrl', 'coverUrl'],
};

/// The server, device and template sending uses when none is picked.
class BoEmailDefaults {
  final int? serverId;
  final int? deviceId;
  final int? templateId;

  const BoEmailDefaults({this.serverId, this.deviceId, this.templateId});

  factory BoEmailDefaults.fromJson(Map<String, dynamic>? j) => BoEmailDefaults(
        serverId: _intOrNull(j?['defaultProviderId']),
        deviceId: _intOrNull(j?['defaultRecipientId']),
        templateId: _intOrNull(j?['defaultTemplateId']),
      );
}

/// One email the server sent or tried to send.
class BoEmailSend {
  final int id;
  final int? bookId;
  final String? bookTitle;
  final String? bookAuthors;
  final String toEmail;
  final String? toName;
  final String? subject;
  final String status;
  final int attempts;
  final String? error;
  final DateTime? sentAt;
  final DateTime? createdAt;
  final DateTime? nextRetryAt;
  final String? format;
  final int? size;
  final String? deviceType;
  final int? deviceId;
  final int? userId;

  const BoEmailSend({
    required this.id,
    this.bookId,
    this.bookTitle,
    this.bookAuthors,
    required this.toEmail,
    this.toName,
    this.subject,
    required this.status,
    this.attempts = 0,
    this.error,
    this.sentAt,
    this.createdAt,
    this.nextRetryAt,
    this.format,
    this.size,
    this.deviceType,
    this.deviceId,
    this.userId,
  });

  factory BoEmailSend.fromJson(Map<String, dynamic> j) => BoEmailSend(
        id: (j['id'] as num).toInt(),
        bookId: _intOrNull(j['bookId']),
        bookTitle: _text(j['bookTitle']),
        bookAuthors: _text(j['bookAuthors']),
        toEmail: '${j['toEmail'] ?? ''}',
        toName: _text(j['toName']),
        subject: _text(j['subject']),
        status: '${j['status'] ?? 'pending'}',
        attempts: _intOrNull(j['attemptCount']) ?? 0,
        error: _text(j['errorMessage']),
        sentAt: _date(j['sentAt']),
        createdAt: _date(j['createdAt']),
        nextRetryAt: _date(j['nextRetryAt']),
        format: _text(j['fileFormat'])?.toLowerCase(),
        size: _intOrNull(j['fileSizeBytes']),
        deviceType: _text(j['deviceType']),
        deviceId: _intOrNull(j['recipientId']),
        userId: _intOrNull(j['userId']),
      );

  bool get sent => status == 'sent';
  bool get failed => status == 'failed';
  bool get pending => status == 'pending';
  String get toLabel => toName ?? toEmail;
}

/// A file of the book an email can carry: a readable edition, never a cover,
/// sidecar or audiobook track.
class BoSendableFile {
  final int id;
  final String format;
  final String? name;
  final int? size;
  final bool primary;
  final bool readAlong;

  const BoSendableFile({
    required this.id,
    required this.format,
    this.name,
    this.size,
    this.primary = false,
    this.readAlong = false,
  });
}

/// The files of a BookOrbit item (with its detail loaded) an email can carry,
/// the primary one first.
List<BoSendableFile> boSendableFiles(Map<String, dynamic>? item) {
  final files = (item?['bookOrbit'] as Map?)?['files'];
  if (files is! List) return const [];
  final out = <BoSendableFile>[];
  for (final f in files.whereType<Map>()) {
    final role = f['role'];
    final format = '${f['format'] ?? ''}'.toLowerCase();
    final id = _intOrNull(f['id']);
    if (id == null || (role != 'content' && role != 'primary')) continue;
    if (_audioFormats.contains(format) || !_bookFormats.contains(format)) continue;
    out.add(BoSendableFile(
      id: id,
      format: format,
      name: _text(f['filename']),
      size: _intOrNull(f['size']),
      primary: role == 'primary',
      readAlong: f['readAlong'] == true,
    ));
  }
  out.sort((a, b) => (b.primary ? 1 : 0) - (a.primary ? 1 : 0));
  return out;
}

/// The file [device] would get, following BookOrbit's own choice: the picked
/// format first, then the device's format, then the book's primary. The
/// narrated EPUB goes only to a device set to get originals, never a Kindle.
({BoSendableFile file, String? missingFormat})? boPlanFile(
  List<BoSendableFile> files,
  BoEmailDevice device,
  String? chosenFormat,
) {
  final plain = files.where((f) => !f.readAlong).toList();
  final pool = plain.isNotEmpty ? plain : files;
  if (pool.isEmpty) return null;
  BoSendableFile? byFormat(String format) {
    for (final f in [...pool, ...files]) {
      if (f.format == format) return f;
    }
    return null;
  }

  if (chosenFormat != null) {
    final chosen = byFormat(chosenFormat);
    return chosen != null ? (file: chosen, missingFormat: null) : (file: pool.first, missingFormat: chosenFormat);
  }
  final wanted = device.preferredFormat;
  if (device.readAlong == 'original' && !device.isKindle && (wanted == null || wanted == 'epub')) {
    for (final f in files) {
      if (f.readAlong) return (file: f, missingFormat: null);
    }
  }
  if (wanted != null) {
    final match = byFormat(wanted);
    return match != null ? (file: match, missingFormat: null) : (file: pool.first, missingFormat: wanted);
  }
  return (file: pool.first, missingFormat: null);
}

enum BoSizeLimit { kindle, gmail }

const _mb = 1024 * 1024;

/// The first mail limit a file of [size] bytes is over, or null.
BoSizeLimit? boSizeLimit(int? size, String? deviceType, String? serverHost) {
  if (size == null || size <= 0) return null;
  if (deviceType == 'kindle' && size > 50 * _mb) return BoSizeLimit.kindle;
  final host = serverHost?.toLowerCase() ?? '';
  if ((host == 'smtp.gmail.com' || host.endsWith('.gmail.com') || host.endsWith('googlemail.com')) && size > 25 * _mb) {
    return BoSizeLimit.gmail;
  }
  return null;
}
