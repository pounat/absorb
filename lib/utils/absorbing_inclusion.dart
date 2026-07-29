bool shouldIncludeBookInAbsorbing({
  required bool isFinished,
  required bool manuallyAdded,
}) {
  return !isFinished || manuallyAdded;
}
