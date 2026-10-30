//
//  GameSettings.swift
//  N-Back-SwiftUI
//

import Foundation

/// Tunable round parameters. Persisted via UserDefaults (lab 2p).
struct GameSettings: Equatable {
    var n: Int = 2
    var eventsPerRound: Int = 20
    /// How long each stimulus stays visible / playable, in seconds.
    var eventDurationSeconds: Double = 2.5
    /// Target share of events that are true n-back matches (lab: ~20–40 %).
    var matchPercentage: Int = 25
    /// Grid edge length: 3 → 3×3, 5 → 5×5.
    var gridSize: Int = 3
    /// How many distinct spoken letters to use (from the phonetically distinct set).
    var letterCount: Int = 8

    var gridCellCount: Int { gridSize * gridSize }

    /// Keeps values in safe ranges the C generator and UI can handle.
    mutating func clamp() {
        n = min(max(n, 1), 5)
        eventsPerRound = min(max(eventsPerRound, 5), 50)
        eventDurationSeconds = min(max(eventDurationSeconds, 1.0), 5.0)
        matchPercentage = min(max(matchPercentage, 20), 40)
        gridSize = (gridSize == 5) ? 5 : 3
        letterCount = min(max(letterCount, 2), AuditoryLetters.all.count)
        // Need enough events after the first n for meaningful matches.
        if eventsPerRound <= n {
            eventsPerRound = n + 5
        }
    }
}

/// Phonetically distinct letters for TTS (classic dual n-back style set).
enum AuditoryLetters {
    static let all = ["C", "H", "K", "L", "Q", "R", "S", "T"]

    static func letter(forValue value: Int, letterCount: Int) -> String {
        let count = min(max(letterCount, 1), all.count)
        let index = max(0, min(count - 1, value - 1))
        return all[index]
    }
}
