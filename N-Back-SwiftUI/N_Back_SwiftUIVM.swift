//
//  N_Back_SwiftUIVM.swift
//  N-Back-SwiftUI
//
//  Created by Jonas Willén on 2023-09-19.
//

import Foundation
import AVFoundation

/// Bridges the pure model to SwiftUI: publishes UI state, runs the round timer, and speaks letters.
/// Navigation stays in the View — this type only exposes `phase` / flags for the View to react to.
@MainActor
final class N_Back_SwiftUIVM: ObservableObject {
    private var theModel: N_BackSwiftUIModel
    private let settingsStore: SettingsStore
    private let scorePersistence: ScorePersistence
    private let synthesizer = AVSpeechSynthesizer()
    private var roundTask: Task<Void, Never>?

    // MARK: - Published UI state

    @Published private(set) var phase: GamePhase = .idle
    @Published var stimulusType: StimulusType = .visual
    @Published private(set) var highScore: Int = 0

    @Published private(set) var currentEventNumber: Int = 0
    @Published private(set) var totalEvents: Int = 20
    @Published private(set) var correctCount: Int = 0
    @Published private(set) var roundScore: Int = 0
    @Published private(set) var maxPossibleScore: Int = 0

    /// 1...gridCellCount while a visual stimulus is active; nil otherwise.
    @Published private(set) var highlightedCell: Int? = nil
    @Published private(set) var showWrongFeedback: Bool = false
    /// Shown when the device has no TTS voices (lab accessibility requirement).
    @Published private(set) var voiceUnavailableMessage: String? = nil

    @Published private(set) var nValue: Int = 2
    @Published private(set) var eventDurationSeconds: Double = 2.5
    @Published private(set) var eventsPerRound: Int = 20
    @Published private(set) var gridSize: Int = 3
    @Published private(set) var letterCount: Int = 8

    /// Editable draft used by SettingsView; committed with `saveSettingsFromDraft()`.
    @Published var settingsDraft: GameSettings = GameSettings()

    @Published var playerNameDraft: String = ""
    @Published private(set) var didSaveCurrentRound: Bool = false

    @Published var scoreSortField: ScoreSortField = .date
    @Published var scoreSortAscending: Bool = false
    @Published private(set) var savedScores: [SavedScore] = []

    init(
        settingsStore: SettingsStore = SettingsStore(),
        scorePersistence: ScorePersistence = .shared
    ) {
        self.settingsStore = settingsStore
        self.scorePersistence = scorePersistence

        let loaded = settingsStore.loadSettings()
        let high = settingsStore.loadHighScore()
        theModel = N_BackSwiftUIModel(settings: loaded, highScore: high)
        theModel.setStimulusType(settingsStore.loadStimulusType())
        settingsDraft = loaded
        stimulusType = theModel.stimulusType
        syncFromModel()
        refreshSavedScores()
    }

    // MARK: - Home / settings actions

    func selectStimulus(_ type: StimulusType) {
        stimulusType = type
        theModel.setStimulusType(type)
        settingsStore.saveStimulusType(type)
        syncFromModel()
    }

    func prepareSettingsDraft() {
        settingsDraft = theModel.settings
    }

    func saveSettingsFromDraft() {
        var draft = settingsDraft
        draft.clamp()
        settingsDraft = draft
        theModel.updateSettings(draft)
        settingsStore.saveSettings(draft)
        syncFromModel()
    }

    func startGame() {
        cancelRoundTask()
        voiceUnavailableMessage = nil
        didSaveCurrentRound = false
        playerNameDraft = ""
        theModel.setStimulusType(stimulusType)
        theModel.startRound()
        syncFromModel()
        beginRoundLoop()
    }

    /// Called when the player leaves the game screen mid-round or after finishing.
    func leaveGame() {
        cancelRoundTask()
        synthesizer.stopSpeaking(at: .immediate)
        if theModel.phase == .running {
            theModel.finishRound()
            persistHighScoreIfNeeded()
        }
        theModel.returnToIdle()
        highlightedCell = nil
        showWrongFeedback = false
        voiceUnavailableMessage = nil
        syncFromModel()
    }

    func saveCurrentScore() {
        guard phase == .finished, !didSaveCurrentRound else { return }
        let name = playerNameDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }

        scorePersistence.saveScore(
            playerName: name,
            score: roundScore,
            maxScore: maxPossibleScore,
            stimulusType: stimulusType
        )
        didSaveCurrentRound = true
        refreshSavedScores()
    }

    func refreshSavedScores() {
        savedScores = scorePersistence.fetchScores(
            sortedBy: scoreSortField,
            ascending: scoreSortAscending
        )
    }

    func selectScoreSortField(_ field: ScoreSortField) {
        if scoreSortField != field {
            scoreSortField = field
            scoreSortAscending = (field == .name)
        }
        refreshSavedScores()
    }

    func toggleScoreSortDirection() {
        scoreSortAscending.toggle()
        refreshSavedScores()
    }

    // MARK: - Match buttons

    func visualMatchPressed() {
        let result = theModel.registerVisualMatchPress()
        handleMatchResult(result)
    }

    func auditoryMatchPressed() {
        let result = theModel.registerAuditoryMatchPress()
        handleMatchResult(result)
    }

    // MARK: - Timer / round loop

    private func beginRoundLoop() {
        let duration = theModel.settings.eventDurationSeconds
        /// Short blank between stimuli so a repeated cell still looks like a new event.
        let blinkGapSeconds = 0.35
        let onSeconds = max(0.4, duration - blinkGapSeconds)

        roundTask = Task { [weak self] in
            guard let self else { return }
            while !Task.isCancelled {
                await self.presentCurrentStimulus()
                try? await Task.sleep(nanoseconds: UInt64(onSeconds * 1_000_000_000))
                if Task.isCancelled { break }

                // Turn the grid off before scoring/advancing (same cell twice → visible blink).
                self.highlightedCell = nil
                try? await Task.sleep(nanoseconds: UInt64(blinkGapSeconds * 1_000_000_000))
                if Task.isCancelled { break }

                self.theModel.completeCurrentEvent()
                let continued = self.theModel.advanceToNextEvent()
                self.syncFromModel()

                if !continued {
                    self.synthesizer.stopSpeaking(at: .immediate)
                    self.persistHighScoreIfNeeded()
                    break
                }
            }
        }
    }

    private func presentCurrentStimulus() async {
        syncFromModel()
        highlightedCell = theModel.currentVisualCell

        if let letter = theModel.currentLetter {
            // Speech only after a user gesture (Start) — required for iOS audio session behavior.
            speech(letter)
        }
    }

    private func cancelRoundTask() {
        roundTask?.cancel()
        roundTask = nil
    }

    private func handleMatchResult(_ result: MatchPressResult) {
        syncFromModel()
        switch result {
        case .falseAlarm:
            triggerWrongFeedback()
        case .hit, .ignored:
            break
        }
    }

    private func triggerWrongFeedback() {
        showWrongFeedback = true
        Task { [weak self] in
            try? await Task.sleep(nanoseconds: 350_000_000)
            self?.showWrongFeedback = false
        }
    }

    private func persistHighScoreIfNeeded() {
        settingsStore.saveHighScore(theModel.highScore)
    }

    private func syncFromModel() {
        phase = theModel.phase
        stimulusType = theModel.stimulusType
        highScore = theModel.highScore
        currentEventNumber = theModel.currentEventNumber
        totalEvents = theModel.totalEvents
        correctCount = theModel.correctCount
        roundScore = theModel.roundScore
        maxPossibleScore = theModel.maxPossibleScore
        nValue = theModel.settings.n
        eventDurationSeconds = theModel.settings.eventDurationSeconds
        eventsPerRound = theModel.settings.eventsPerRound
        gridSize = theModel.settings.gridSize
        letterCount = theModel.settings.letterCount
    }

    private func speech(_ text: String) {
        // Accessibility: fallback message when no voice is available.
        if AVSpeechSynthesisVoice.speechVoices().isEmpty {
            voiceUnavailableMessage = "No voice available. Letter: \(text)"
            return
        }
        voiceUnavailableMessage = nil
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate
        synthesizer.stopSpeaking(at: .immediate)
        synthesizer.speak(utterance)
    }
}
