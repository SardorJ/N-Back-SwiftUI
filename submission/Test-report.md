# Test report

The unit tests cover the game rules in `N_BackSwiftUIModel`. They do not start the round timer, the speech synthesizer, or SwiftUI. Each test builds a model, feeds it a fixed sequence through `startRoundForTesting`, and checks the return value of a match press or the score.

The lab asks for tests of at least three of these areas: sequence generation, match-rate enforcement, the first-n guarantee, double-press prevention, and the scoring formula. This submission tests the last three. Sequence generation lives in `nback.c` and uses `rand()`, so these tests use a known list instead of the random generator.

The test file is `N-Back-SwiftUITests/N_Back_SwiftUIModelTests.swift`.

## First-n guarantee

`testFirstNEventsCannotRegisterMatch` uses n = 2 and the visual sequence `[3, 7, 3, 1, 2]`.

- A match press on event 1 (index 0) returns `.ignored`.
- A match press on event 2 (index 1) returns `.ignored`.
- A match press on event 3 returns `.hit`, because the value 3 equals the value two steps earlier.

`testIsMatchHelperRespectsFirstN` checks the helper `isMatch` on `[1, 1, 1, 2]` with n = 2. Index 0 and index 1 are not matches. Index 2 is a match. Index 3 is not.

## Double-press prevention

`testDoublePressOnSameEventIsIgnored` uses n = 2 and the sequence `[1, 2, 1, 4]`. The test advances to index 2, where the value matches index 0.

- The first press returns `.hit`.
- The second press on the same event returns `.ignored`.
- `correctCount` stays 1.

## Scoring formula

`testScoringFormulaAndNonNegative` uses n = 1 and the sequence `[5, 5, 8]`.

- Event 2 is a true match. The press returns `.hit`.
- Event 3 is not a match. The press returns `.falseAlarm`.
- The round is then finished.

The formula is hit +2, miss −1, false alarm −2, and the result is never below 0. One hit and one false alarm give `2 - 2 = 0`. The test asserts that `roundScore` is 0 and that it is at least 0.

## Result

Test Suite 'N_Back_SwiftUIModelTests' started at 2026-11-03 22:57:37.382.
Test Case '-[N_Back_SwiftUITests.N_Back_SwiftUIModelTests testDoublePressOnSameEventIsIgnored]' started.
Test Case '-[N_Back_SwiftUITests.N_Back_SwiftUIModelTests testDoublePressOnSameEventIsIgnored]' passed (0.003 seconds).
Test Case '-[N_Back_SwiftUITests.N_Back_SwiftUIModelTests testFirstNEventsCannotRegisterMatch]' started.
Test Case '-[N_Back_SwiftUITests.N_Back_SwiftUIModelTests testFirstNEventsCannotRegisterMatch]' passed (0.001 seconds).
Test Case '-[N_Back_SwiftUITests.N_Back_SwiftUIModelTests testIsMatchHelperRespectsFirstN]' started.
Test Case '-[N_Back_SwiftUITests.N_Back_SwiftUIModelTests testIsMatchHelperRespectsFirstN]' passed (0.000 seconds).
Test Case '-[N_Back_SwiftUITests.N_Back_SwiftUIModelTests testScoringFormulaAndNonNegative]' started.
Test Case '-[N_Back_SwiftUITests.N_Back_SwiftUIModelTests testScoringFormulaAndNonNegative]' passed (0.001 seconds).
Test Suite 'N_Back_SwiftUIModelTests' passed at 2026-11-03 22:57:37.412.
	 Executed 4 tests, with 0 failures (0 unexpected) in 0.004 (0.030) seconds
