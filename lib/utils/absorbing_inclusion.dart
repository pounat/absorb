bool shouldIncludeBookInAbsorbing({
  required bool isFinished,
  required bool addedAfterFinish,
  bool isActive = false,
}) {
  return !isFinished || addedAfterFinish || isActive;
}
