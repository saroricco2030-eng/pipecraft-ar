class BendResult {
  final double insertLength;
  final double targetAngle;
  final double setAngle;
  final double arcLength;
  final double shortenLength;
  final double consumedLength;

  const BendResult({
    required this.insertLength,
    required this.targetAngle,
    required this.setAngle,
    required this.arcLength,
    required this.shortenLength,
    required this.consumedLength,
  });
}
