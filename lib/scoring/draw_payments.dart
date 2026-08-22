Map<String, int> calculateNotenPayments({
  required List<String> allPlayerIds,
  required List<String> tenpaiPlayerIds,
}) {
  final tenpaiCount = tenpaiPlayerIds.length;
  final notenIds = allPlayerIds
      .where((id) => !tenpaiPlayerIds.contains(id))
      .toList();
  final notenCount = notenIds.length;
  if (tenpaiCount == 0 || tenpaiCount == 4) {
    return {for (final id in allPlayerIds) id: 0};
  }
  const totalPot = 3000;
  final perTenpai = totalPot ~/ tenpaiCount;
  final perNoten = totalPot ~/ notenCount;
  return {
    for (final id in tenpaiPlayerIds) id: perTenpai,
    for (final id in notenIds) id: -perNoten,
  };
}
