/// Whether a queue may reuse cached audio and promote only book metadata.
/// Browser playback instead needs the normal completion -> playItem path so
/// every book starts with a freshly reconciled, owned session writer.
bool allowsNativeCrossBookHandover({required bool isWeb}) => !isWeb;
