enum SleepTimerTickAction { wait, countDown, trigger }

SleepTimerTickAction sleepTimerTickAction({
  required Duration timeRemaining,
  required bool isPlaybackActive,
  required bool isPauseRequested,
}) {
  if (!isPlaybackActive || isPauseRequested) {
    return SleepTimerTickAction.wait;
  }
  if (timeRemaining <= Duration.zero) {
    return SleepTimerTickAction.trigger;
  }
  return SleepTimerTickAction.countDown;
}
