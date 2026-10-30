//
//  ScoreHistoryView.swift
//  N-Back-SwiftUI
//

import SwiftUI

/// Lists saved scores from Core Data; sortable by name, score, or date.
struct ScoreHistoryView: View {
    @EnvironmentObject var viewModel: N_Back_SwiftUIVM

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    var body: some View {
        VStack(spacing: 0) {
            Picker("Sort", selection: Binding(
                get: { viewModel.scoreSortField },
                set: { viewModel.selectScoreSortField($0) }
            )) {
                ForEach(ScoreSortField.allCases) { field in
                    Text(field.title).tag(field)
                }
            }
            .pickerStyle(.segmented)
            .padding()

            Button {
                viewModel.toggleScoreSortDirection()
            } label: {
                Label(
                    viewModel.scoreSortAscending ? "Ascending" : "Descending",
                    systemImage: viewModel.scoreSortAscending ? "arrow.up" : "arrow.down"
                )
            }
            .padding(.bottom, 8)

            if viewModel.savedScores.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "list.number")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    Text("No scores yet")
                        .font(.headline)
                    Text("Finish a round and save your score under a name.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            } else {
                List(viewModel.savedScores) { entry in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(entry.playerName)
                                .font(.headline)
                            Spacer()
                            Text("\(entry.score) / \(entry.maxScore)")
                                .font(.headline.monospacedDigit())
                        }
                        HStack {
                            Text(entry.stimulusType.capitalized)
                            Spacer()
                            Text(dateFormatter.string(from: entry.date))
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .navigationTitle("Score history")
        .onAppear {
            viewModel.refreshSavedScores()
        }
    }
}

struct ScoreHistoryView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            ScoreHistoryView()
                .environmentObject(N_Back_SwiftUIVM())
        }
    }
}
