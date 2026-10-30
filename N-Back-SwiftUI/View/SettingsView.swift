//
//  SettingsView.swift
//  N-Back-SwiftUI
//

import SwiftUI

/// Persistent settings: n, events, duration, grid size, letter count (lab 2p).
struct SettingsView: View {
    @EnvironmentObject var viewModel: N_Back_SwiftUIVM
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Form {
            Section("N-back level") {
                Stepper("n = \(viewModel.settingsDraft.n)", value: $viewModel.settingsDraft.n, in: 1...5)
            }

            Section("Round") {
                Stepper(
                    "Events = \(viewModel.settingsDraft.eventsPerRound)",
                    value: $viewModel.settingsDraft.eventsPerRound,
                    in: 5...50,
                    step: 1
                )
                VStack(alignment: .leading) {
                    Text("Event duration: \(String(format: "%.1f", viewModel.settingsDraft.eventDurationSeconds)) s")
                    Slider(value: $viewModel.settingsDraft.eventDurationSeconds, in: 1.0...5.0, step: 0.1)
                }
                Stepper(
                    "Match rate = \(viewModel.settingsDraft.matchPercentage)%",
                    value: $viewModel.settingsDraft.matchPercentage,
                    in: 20...40,
                    step: 5
                )
            }

            Section("Visual") {
                Picker("Grid size", selection: $viewModel.settingsDraft.gridSize) {
                    Text("3 × 3").tag(3)
                    Text("5 × 5").tag(5)
                }
                .pickerStyle(.segmented)
            }

            Section("Auditory") {
                Stepper(
                    "Letters = \(viewModel.settingsDraft.letterCount)",
                    value: $viewModel.settingsDraft.letterCount,
                    in: 2...AuditoryLetters.all.count
                )
                Text("Using: \(AuditoryLetters.all.prefix(viewModel.settingsDraft.letterCount).joined(separator: ", "))")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle("Settings")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    viewModel.saveSettingsFromDraft()
                    dismiss()
                }
            }
        }
        .onAppear {
            viewModel.prepareSettingsDraft()
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            SettingsView()
                .environmentObject(N_Back_SwiftUIVM())
        }
    }
}
