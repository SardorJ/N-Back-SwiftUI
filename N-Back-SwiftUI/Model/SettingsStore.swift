//
//  SettingsStore.swift
//  N-Back-SwiftUI
//

import Foundation

/// Reads/writes game settings and high score with UserDefaults (lab hint for iOS).
struct SettingsStore {
    private let defaults: UserDefaults

    private enum Key {
        static let n = "settings.n"
        static let eventsPerRound = "settings.eventsPerRound"
        static let eventDuration = "settings.eventDurationSeconds"
        static let matchPercentage = "settings.matchPercentage"
        static let gridSize = "settings.gridSize"
        static let letterCount = "settings.letterCount"
        static let highScore = "settings.highScore"
        static let stimulusType = "settings.stimulusType"
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func loadSettings() -> GameSettings {
        var settings = GameSettings()
        if defaults.object(forKey: Key.n) != nil {
            settings.n = defaults.integer(forKey: Key.n)
        }
        if defaults.object(forKey: Key.eventsPerRound) != nil {
            settings.eventsPerRound = defaults.integer(forKey: Key.eventsPerRound)
        }
        if defaults.object(forKey: Key.eventDuration) != nil {
            settings.eventDurationSeconds = defaults.double(forKey: Key.eventDuration)
        }
        if defaults.object(forKey: Key.matchPercentage) != nil {
            settings.matchPercentage = defaults.integer(forKey: Key.matchPercentage)
        }
        if defaults.object(forKey: Key.gridSize) != nil {
            settings.gridSize = defaults.integer(forKey: Key.gridSize)
        }
        if defaults.object(forKey: Key.letterCount) != nil {
            settings.letterCount = defaults.integer(forKey: Key.letterCount)
        }
        settings.clamp()
        return settings
    }

    func saveSettings(_ settings: GameSettings) {
        var clamped = settings
        clamped.clamp()
        defaults.set(clamped.n, forKey: Key.n)
        defaults.set(clamped.eventsPerRound, forKey: Key.eventsPerRound)
        defaults.set(clamped.eventDurationSeconds, forKey: Key.eventDuration)
        defaults.set(clamped.matchPercentage, forKey: Key.matchPercentage)
        defaults.set(clamped.gridSize, forKey: Key.gridSize)
        defaults.set(clamped.letterCount, forKey: Key.letterCount)
    }

    func loadHighScore() -> Int {
        defaults.integer(forKey: Key.highScore)
    }

    func saveHighScore(_ score: Int) {
        defaults.set(max(0, score), forKey: Key.highScore)
    }

    func loadStimulusType() -> StimulusType {
        guard let raw = defaults.string(forKey: Key.stimulusType),
              let type = StimulusType(rawValue: raw) else {
            return .visual
        }
        return type
    }

    func saveStimulusType(_ type: StimulusType) {
        defaults.set(type.rawValue, forKey: Key.stimulusType)
    }
}
