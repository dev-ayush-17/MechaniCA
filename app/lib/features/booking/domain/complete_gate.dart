/// Complete is blocked only when a part-replacement line exists and
/// fewer than three photos are queued or stored (FR-MEC-008).
/// Jobs with no part lines can still complete (M07 no-parts path).
bool completeBlockedWithoutPhotos({
  required bool hasPartReplacementLine,
  required int queuedOrStoredCount,
}) {
  if (!hasPartReplacementLine) return false;
  return queuedOrStoredCount < 3;
}
