//
//  N_Back_SwiftUIModelTests.swift
//  N-Back-SwiftUITests
//
//  Unit tests for core game logic (lab 1p requirement: at least three areas).
//

import XCTest
@testable import N_Back_SwiftUI

final class N_Back_SwiftUIModelTests: XCTestCase {

    /// 1) First-n guarantee: match presses during the first n events are ignored.
    func testFirstNEventsCannotRegisterMatch() {
        var model = N_BackSwiftUIModel(settings: GameSettings(n: 2, eventsPerRound: 5))
        // Indices: 0,1 are within first n; index 2 equals index 0 → true match.
        model.startRoundForTesting(visual: [3, 7, 3, 1, 2])

        XCTAssertEqual(model.registerVisualMatchPress(), .ignored, "Event 1 (index 0) must ignore match press")
        _ = model.advanceToNextEvent()
        XCTAssertEqual(model.registerVisualMatchPress(), .ignored, "Event 2 (index 1) must ignore match press")
        _ = model.advanceToNextEvent()
        XCTAssertEqual(model.registerVisualMatchPress(), .hit, "Event 3 matches event 1 for n=2")
    }

    /// 2) Double-press prevention: second press on the same event is ignored.
    func testDoublePressOnSameEventIsIgnored() {
        var model = N_BackSwiftUIModel(settings: GameSettings(n: 2, eventsPerRound: 4))
        model.startRoundForTesting(visual: [1, 2, 1, 4])
        _ = model.advanceToNextEvent()
        _ = model.advanceToNextEvent()

        XCTAssertEqual(model.registerVisualMatchPress(), .hit)
        XCTAssertEqual(model.registerVisualMatchPress(), .ignored, "Second press on same event must be ignored")
        XCTAssertEqual(model.correctCount, 1)
    }

    /// 3) Scoring formula: hit +2, miss -1, false alarm -2; score never negative.
    func testScoringFormulaAndNonNegative() {
        var model = N_BackSwiftUIModel(settings: GameSettings(n: 1, eventsPerRound: 3))
        // n=1: index1 matches index0; index2 does not match index1.
        model.startRoundForTesting(visual: [5, 5, 8])

        _ = model.advanceToNextEvent() // index 1, true match
        XCTAssertEqual(model.registerVisualMatchPress(), .hit)

        _ = model.advanceToNextEvent() // index 2, not a match
        XCTAssertEqual(model.registerVisualMatchPress(), .falseAlarm)
        model.completeCurrentEvent()
        model.finishRound()

        // 1 hit (+2) + 1 false alarm (-2) = 0
        XCTAssertEqual(model.roundScore, 0)
        XCTAssertGreaterThanOrEqual(model.roundScore, 0)
    }

    /// Static helper: first n indices are never matches.
    func testIsMatchHelperRespectsFirstN() {
        let sequence = [1, 1, 1, 2]
        XCTAssertFalse(N_BackSwiftUIModel.isMatch(in: sequence, at: 0, n: 2))
        XCTAssertFalse(N_BackSwiftUIModel.isMatch(in: sequence, at: 1, n: 2))
        XCTAssertTrue(N_BackSwiftUIModel.isMatch(in: sequence, at: 2, n: 2))
        XCTAssertFalse(N_BackSwiftUIModel.isMatch(in: sequence, at: 3, n: 2))
    }
}
