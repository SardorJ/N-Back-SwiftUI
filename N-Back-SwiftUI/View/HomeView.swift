//
//  HomeView.swift
//  N-Back-SwiftUI
//

import SwiftUI

/// Home screen: high score, stimulus choice, current settings, start button.
struct HomeView: View {
    @EnvironmentObject var viewModel: N_Back_SwiftUIVM
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("N-Back")
                    .font(.largeTitle.bold())

                Text("High score: \(viewModel.highScore)")
                    .font(.title2)

                settingsSummary
                    .frame(maxWidth: contentMaxWidth)

                Text("Stimulus type")
                    .font(.headline)

                stimulusChooser
                    .frame(maxWidth: contentMaxWidth)

                Button {
                    viewModel.startGame()
                } label: {
                    Text("Start game")
                        .font(.title2.bold())
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 48)
                        .padding(.vertical, 8)
                        .foregroundColor(.white)
                        .background(Color.blue)
                        .cornerRadius(14)
                }
                .frame(maxWidth: contentMaxWidth)
            }
            .frame(maxWidth: .infinity)
            .padding()
        }
        .navigationTitle("Home")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                NavigationLink("Scores") {
                    ScoreHistoryView()
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink("Settings") {
                    SettingsView()
                }
            }
        }
    }

    private var contentMaxWidth: CGFloat {
        horizontalSizeClass == .regular ? 560 : .infinity
    }

    private var settingsSummary: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Current settings")
                .font(.headline)
            Text("n = \(viewModel.nValue)")
            Text("Event duration = \(String(format: "%.1f", viewModel.eventDurationSeconds)) s")
            Text("Events per round = \(viewModel.eventsPerRound)")
            Text("Grid = \(viewModel.gridSize)×\(viewModel.gridSize)")
            Text("Letters = \(viewModel.letterCount)")
            Text("Mode = \(viewModel.stimulusType.title)")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.gray.opacity(0.12))
        .cornerRadius(12)
    }

    private var stimulusChooser: some View {
        HStack(spacing: 12) {
            stimulusButton(.visual, label: "Visual", systemImage: "eye")
            stimulusButton(.auditory, label: "Sound", systemImage: "speaker.wave.3.fill")
            stimulusButton(.both, label: "Both", systemImage: "circle.grid.cross")
        }
    }

    private func stimulusButton(_ type: StimulusType, label: String, systemImage: String) -> some View {
        let selected = viewModel.stimulusType == type
        return Button {
            viewModel.selectStimulus(type)
        } label: {
            VStack(spacing: 6) {
                Image(systemName: systemImage)
                    .imageScale(.large)
                Text(label)
                    .font(.caption.bold())
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: 48)
            .padding(.vertical, 10)
            .foregroundColor(.white)
            .background(selected ? Color.blue : Color.gray)
            .cornerRadius(12)
        }
        .accessibilityLabel("\(label) stimulus")
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            HomeView()
                .environmentObject(N_Back_SwiftUIVM())
        }
    }
}
