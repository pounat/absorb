bool shouldRestoreBookLibrary({
  required int pageIndex,
  required bool podcastsShown,
  required String? selectedLibraryId,
  required String podcastLibraryId,
  bool restoreLibraryPage = false,
}) {
  return (pageIndex == 0 || (restoreLibraryPage && pageIndex == 1)) &&
      podcastsShown &&
      selectedLibraryId == podcastLibraryId;
}
