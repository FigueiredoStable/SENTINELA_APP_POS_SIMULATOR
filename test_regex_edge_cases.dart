void main() {
  // Test edge cases and variations
  List<String> edgeCases = [
    // Different formats
    "NOTE-002-1755390180-0000000030004000800000d9b4ddb582:1:2:1",
    "NOTE-100-1755390180-abc123def456789:1:2:1",
    "COIN-1-1755390180-xyz789abc:1:2:1",
    "BANKNOTE-5-1755390180-123456789abcdef:1:2:1",

    // Shorter event IDs
    "NOTE-010-1755390180-abc123:1:2:1",
    "COIN-25-1755390180-def456:1:2:1",

    // Longer event IDs
    "NOTE-050-1755390180-0000000030004000800000d9b4ddb582abcdef123456:1:2:1",

    // Different timestamp lengths
    "NOTE-020-17553901801234-0000000030004000800000d9b4ddb585:1:2:1",

    // Mixed case (shouldn't happen but test anyway)
    "NOTE-020-1755390183-ABCD1234efgh5678:1:2:1",
  ];

  print("Testing edge cases with regex: r'-([^-:]+)(?=:)'");
  print("=" * 70);

  for (String testCase in edgeCases) {
    final match = RegExp(r'-([^-:]+)(?=:)').firstMatch(testCase);
    String extracted = match?[1] ?? "NO MATCH";
    String expected = testCase.split('-')[3].split(':')[0];
    bool isCorrect = extracted == expected;

    print("Input:     $testCase");
    print("Extracted: $extracted");
    print("Expected:  $expected");
    print("Result:    ${isCorrect ? '✅ CORRECT' : '❌ WRONG'}");
    print("");
  }
}
