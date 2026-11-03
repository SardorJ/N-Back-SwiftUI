//
//  N_Back_SwiftUIModel.swift
//  N-Back-SwiftUI
//
//  Created by Jonas Willén on 2023-09-19.
//

import Foundation

// MARK: - Game configuration types

/// Which stimulus channels are active in a round.
enum StimulusType: String, CaseIterable, Identifiable {
    case visual
    case auditory
    case both

    var id: String { rawValue }

    var title: String {
        switch self {
        case .visual: return "Visual"
        case .auditory: return "Sound"
        case .both: return "Both"
        }
    }

    var usesVisual: Bool { self == .visual || self == .both }
    var usesAuditory: Bool { self == .auditory || self == .both }
}

/// Lifecycle of a round. Views switch UI from this; ViewModel drives transitions.
enum GamePhase: String {
    case idle
    case running
    case finished
}

/// Result of pressing a match button once.
enum MatchPressResult: Equatable {
    case ignored
    case hit
    case falseAlarm
}

// MARK: - Model

/// Pure game logic: sequences, match rules, and scoring.
/// No UI, no timers, no speech — that stays in the ViewModel so this layer is unit-testable.
struct N_BackSwiftUIModel {
    private(set) var settings: GameSettings
    private(set) var stimulusType: StimulusType
    private(set) var phase: GamePhase

    /// Visual sequence values in 1...gridCellCount. Empty when visual is off.
    private(set) var visualSequence: [Int]
    /// Auditory sequence values in 1...letterCount. Empty when auditory is off.
    private(set) var auditorySequence: [Int]

    /// Zero-based index of the current event while running / after last tick.
    private(set) var currentIndex: Int

    private var visualRespondedThisEvent: Bool
    private var auditoryRespondedThisEvent: Bool

    private(set) var visualHits: Int
    private(set) var visualMisses: Int
    private(set) var visualFalseAlarms: Int
    private(set) var auditoryHits: Int
    private(set) var auditoryMisses: Int
    private(set) var auditoryFalseAlarms: Int

    private(set) var highScore: Int

    init(settings: GameSettings = GameSettings(), highScore: Int = 0) {
        var clamped = settings
        clamped.clamp()
        self.settings = clamped
        self.stimulusType = .visual
        self.phase = .idle
        self.visualSequence = []
        self.auditorySequence = []
        self.currentIndex = 0
        self.visualRespondedThisEvent = false
        self.auditoryRespondedThisEvent = false
        self.visualHits = 0
        self.visualMisses = 0
        self.visualFalseAlarms = 0
        self.auditoryHits = 0
        self.auditoryMisses = 0
        self.auditoryFalseAlarms = 0
        self.highScore = highScore
    }

    // MARK: Display helpers

    /// 1-based event number for the HUD (0 when idle with no sequence).
    var currentEventNumber: Int {
        guard phase != .idle, !activeSequenceLengthIsZero else { return 0 }
        return currentIndex + 1
    }

    var totalEvents: Int { settings.eventsPerRound }

    /// Correct responses so far (hits on active channels).
    var correctCount: Int {
        var total = 0
        if stimulusType.usesVisual { total += visualHits }
        if stimulusType.usesAuditory { total += auditoryHits }
        return total
    }

    /// Grid cell 1...N for the current visual stimulus, or nil if none.
    var currentVisualCell: Int? {
        guard stimulusType.usesVisual,
              phase == .running,
              visualSequence.indices.contains(currentIndex) else { return nil }
        return visualSequence[currentIndex]
    }

    /// Spoken letter for the current auditory stimulus, or nil if none.
    var currentLetter: String? {
        guard stimulusType.usesAuditory,
              phase == .running,
              auditorySequence.indices.contains(currentIndex) else { return nil }
        return AuditoryLetters.letter(
            forValue: auditorySequence[currentIndex],
            letterCount: settings.letterCount
        )
    }

    /// Score for the finished round. Weights: hit +2, miss -1, false alarm -2; never negative.
    var roundScore: Int {
        let hits = correctCount
        let misses = (stimulusType.usesVisual ? visualMisses : 0)
            + (stimulusType.usesAuditory ? auditoryMisses : 0)
        let falseAlarms = (stimulusType.usesVisual ? visualFalseAlarms : 0)
            + (stimulusType.usesAuditory ? auditoryFalseAlarms : 0)
        return max(0, hits * 2 - misses - falseAlarms * 2)
    }

    /// Number of true n-back matches in the active sequence(s).
    var trueMatchCount: Int {
        var count = 0
        if stimulusType.usesVisual {
            count += Self.countMatches(in: visualSequence, n: settings.n)
        }
        if stimulusType.usesAuditory {
            count += Self.countMatches(in: auditorySequence, n: settings.n)
        }
        return count
    }

    /// Perfect play: every true match is a hit, no misses or false alarms → matches × 2.
    var maxPossibleScore: Int {
        trueMatchCount * 2
    }

    private var activeSequenceLengthIsZero: Bool {
        let length = stimulusType.usesVisual ? visualSequence.count : auditorySequence.count
        return length == 0
    }

    // MARK: Setup

    mutating func setStimulusType(_ type: StimulusType) {
        guard phase == .idle else { return }
        stimulusType = type
    }

    mutating func updateSettings(_ newSettings: GameSettings) {
        guard phase == .idle else { return }
        var clamped = newSettings
        clamped.clamp()
        settings = clamped
    }

    mutating func setHighScore(_ score: Int) {
        highScore = max(0, score)
    }

    // MARK: Round lifecycle

    /// Builds sequences via the C generator and enters `.running` at event 0.
    mutating func startRound() {
        var visual: [Int] = []
        var auditory: [Int] = []

        if stimulusType.usesVisual {
            visual = Self.generateSequence(
                size: settings.eventsPerRound,
                combinations: settings.gridCellCount,
                matchPercentage: settings.matchPercentage,
                nback: settings.n
            )
        }
        if stimulusType.usesAuditory {
            auditory = Self.generateSequence(
                size: settings.eventsPerRound,
                combinations: settings.letterCount,
                matchPercentage: settings.matchPercentage,
                nback: settings.n
            )
        }

        beginRound(visual: visual, auditory: auditory)
    }

    /// Starts a round with known sequences (used by unit tests).
    mutating func startRoundForTesting(visual: [Int], auditory: [Int] = []) {
        if !visual.isEmpty {
            stimulusType = auditory.isEmpty ? .visual : .both
        } else {
            stimulusType = .auditory
        }
        var adjusted = settings
        adjusted.eventsPerRound = max(visual.count, auditory.count)
        settings = adjusted
        beginRound(visual: visual, auditory: auditory)
    }

    private mutating func beginRound(visual: [Int], auditory: [Int]) {
        resetRoundCounters()
        visualSequence = visual
        auditorySequence = auditory
        currentIndex = 0
        visualRespondedThisEvent = false
        auditoryRespondedThisEvent = false
        phase = .running
    }

    /// Ends the round, updates high score, and moves to `.finished`.
    mutating func finishRound() {
        guard phase == .running else { return }
        let score = roundScore
        if score > highScore {
            highScore = score
        }
        phase = .finished
    }

    /// Leaves the game screen back to home without requiring a finished score update again.
    mutating func returnToIdle() {
        phase = .idle
        currentIndex = 0
        visualRespondedThisEvent = false
        auditoryRespondedThisEvent = false
    }

    // MARK: Match rules

    /// True when the value at `index` equals the value at `index - n`.
    /// The first `n` events can never be matches (lab requirement).
    func isVisualMatch(at index: Int) -> Bool {
        Self.isMatch(in: visualSequence, at: index, n: settings.n)
    }

    func isAuditoryMatch(at index: Int) -> Bool {
        Self.isMatch(in: auditorySequence, at: index, n: settings.n)
    }

    /// Whether a match press is allowed right now for a channel.
    func canRegisterMatch(visual: Bool) -> Bool {
        guard phase == .running else { return false }
        guard currentIndex >= settings.n else { return false }
        if visual {
            guard stimulusType.usesVisual else { return false }
            return !visualRespondedThisEvent
        } else {
            guard stimulusType.usesAuditory else { return false }
            return !auditoryRespondedThisEvent
        }
    }

    /// Registers one match press for the visual (position) channel.
    mutating func registerVisualMatchPress() -> MatchPressResult {
        registerMatchPress(isVisual: true)
    }

    /// Registers one match press for the auditory channel.
    mutating func registerAuditoryMatchPress() -> MatchPressResult {
        registerMatchPress(isVisual: false)
    }

    /// Dual-mode helper: register both channels in one press ("I think both match").
    mutating func registerBothMatchPress() -> (visual: MatchPressResult, auditory: MatchPressResult) {
        let visual = registerVisualMatchPress()
        let auditory = registerAuditoryMatchPress()
        return (visual, auditory)
    }

    /// True when both channels can still accept a press this event (for the Both button).
    func canRegisterBothMatches() -> Bool {
        stimulusType == .both
            && canRegisterMatch(visual: true)
            && canRegisterMatch(visual: false)
    }

    // MARK: Event tick (called by ViewModel timer)

    /// At the end of an event window: count misses for unanswered true matches.
    mutating func completeCurrentEvent() {
        guard phase == .running else { return }

        if stimulusType.usesVisual,
           isVisualMatch(at: currentIndex),
           !visualRespondedThisEvent {
            visualMisses += 1
        }
        if stimulusType.usesAuditory,
           isAuditoryMatch(at: currentIndex),
           !auditoryRespondedThisEvent {
            auditoryMisses += 1
        }
    }

    /// Advances to the next event, or finishes the round. Returns `false` when the round ended.
    @discardableResult
    mutating func advanceToNextEvent() -> Bool {
        guard phase == .running else { return false }

        let lastIndex = settings.eventsPerRound - 1
        if currentIndex >= lastIndex {
            finishRound()
            return false
        }

        currentIndex += 1
        visualRespondedThisEvent = false
        auditoryRespondedThisEvent = false
        return true
    }

    // MARK: Private helpers

    private mutating func registerMatchPress(isVisual: Bool) -> MatchPressResult {
        guard canRegisterMatch(visual: isVisual) else { return .ignored }

        if isVisual {
            visualRespondedThisEvent = true
            if isVisualMatch(at: currentIndex) {
                visualHits += 1
                return .hit
            } else {
                visualFalseAlarms += 1
                return .falseAlarm
            }
        } else {
            auditoryRespondedThisEvent = true
            if isAuditoryMatch(at: currentIndex) {
                auditoryHits += 1
                return .hit
            } else {
                auditoryFalseAlarms += 1
                return .falseAlarm
            }
        }
    }

    private mutating func resetRoundCounters() {
        visualHits = 0
        visualMisses = 0
        visualFalseAlarms = 0
        auditoryHits = 0
        auditoryMisses = 0
        auditoryFalseAlarms = 0
    }

    /// Copies a C-generated sequence into a Swift array and frees the C object.
    static func generateSequence(
        size: Int,
        combinations: Int,
        matchPercentage: Int,
        nback: Int
    ) -> [Int] {
        let handle = create(
            Int32(size),
            Int32(combinations),
            Int32(matchPercentage),
            Int32(nback)
        )
        defer { destroy(handle) }

        var values: [Int] = []
        values.reserveCapacity(size)
        for i in 0..<size {
            values.append(Int(getIndexOf(handle, Int32(i))))
        }
        return values
    }

    static func isMatch(in sequence: [Int], at index: Int, n: Int) -> Bool {
        guard index >= n, sequence.indices.contains(index), sequence.indices.contains(index - n) else {
            return false
        }
        return sequence[index] == sequence[index - n]
    }

    static func countMatches(in sequence: [Int], n: Int) -> Int {
        guard !sequence.isEmpty else { return 0 }
        return sequence.indices.filter { isMatch(in: sequence, at: $0, n: n) }.count
    }
}
