//
//  GameView.swift
//  N-Back-SwiftUI
//

import SwiftUI

/// Game screen: grid and/or audio, live HUD, match controls, wrong-press feedback.
struct GameView: View {
    @EnvironmentObject var viewModel: N_Back_SwiftUIVM
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private var isLandscape: Bool {
        verticalSizeClass == .compact
    }

    var body: some View {
        GeometryReader { geo in
            Group {
                if isLandscape {
                    HStack(alignment: .top, spacing: 20) {
                        stimulusArea(maxSide: min(geo.size.height - 32, geo.size.width * 0.55))
                        sidePanel
                            .frame(maxWidth: .infinity)
                    }
                } else {
                    VStack(spacing: 16) {
                        header
                        hud
                        stimulusArea(maxSide: min(geo.size.width - 32, geo.size.height * 0.45))
                        if viewModel.phase == .finished {
                            finishedPanel
                        } else {
                            matchButtons
                        }
                        Spacer(minLength: 0)
                    }
                }
            }
            .padding()
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .safeAreaInset(edge: .bottom) {
            if let message = viewModel.voiceUnavailableMessage {
                Text(message)
                    .font(.footnote)
                    .padding(10)
                    .frame(maxWidth: .infinity)
                    .background(Color.orange.opacity(0.2))
            }
        }
    }

    private var header: some View {
        HStack {
            Button("Back") {
                viewModel.leaveGame()
            }
            .frame(minHeight: 44)
            Spacer()
            Text("n = \(viewModel.nValue) · \(viewModel.gridSize)×\(viewModel.gridSize)")
                .foregroundColor(.secondary)
        }
    }

    private var hud: some View {
        HStack {
            Text("Event \(viewModel.currentEventNumber)/\(viewModel.totalEvents)")
            Spacer()
            Text("Correct: \(viewModel.correctCount)")
        }
        .font(.headline)
    }

    private var sidePanel: some View {
        VStack(alignment: .leading, spacing: 16) {
            header
            hud
            if viewModel.phase == .finished {
                finishedPanel
            } else {
                matchButtons
            }
            Spacer()
        }
    }

    @ViewBuilder
    private func stimulusArea(maxSide: CGFloat) -> some View {
        if viewModel.stimulusType.usesVisual {
            GridView(
                gridSize: viewModel.gridSize,
                highlightedCell: viewModel.highlightedCell
            )
            .frame(width: maxSide, height: maxSide)
            .frame(maxWidth: .infinity)
        } else {
            Image(systemName: "speaker.wave.3.fill")
                .font(.system(size: horizontalSizeClass == .regular ? 80 : 64))
                .foregroundColor(.blue)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
                .accessibilityLabel("Auditory stimulus active")
        }
    }

    private var matchButtons: some View {
        VStack(spacing: 12) {
            if viewModel.stimulusType.usesVisual {
                MatchButton(
                    title: "Position match",
                    flash: viewModel.visualMatchFlash
                ) {
                    viewModel.visualMatchPressed()
                }
            }
            if viewModel.stimulusType.usesAuditory {
                MatchButton(
                    title: "Sound match",
                    flash: viewModel.auditoryMatchFlash
                ) {
                    viewModel.auditoryMatchPressed()
                }
            }
            if viewModel.stimulusType == .both {
                MatchButton(
                    title: "Both match",
                    flash: viewModel.bothMatchFlash
                ) {
                    viewModel.bothMatchPressed()
                }
            }
        }
    }

    private var finishedPanel: some View {
        VStack(spacing: 12) {
            Text("Round finished")
                .font(.title2.bold())
            Text("Score: \(viewModel.roundScore) / \(viewModel.maxPossibleScore)")
            Text("High score: \(viewModel.highScore)")

            TextField("Your name", text: $viewModel.playerNameDraft)
                .textFieldStyle(.roundedBorder)
                .disabled(viewModel.didSaveCurrentRound)

            Button {
                viewModel.saveCurrentScore()
            } label: {
                Text(viewModel.didSaveCurrentRound ? "Saved" : "Save score")
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 48)
            }
            .buttonStyle(.borderedProminent)
            .disabled(
                viewModel.didSaveCurrentRound
                    || viewModel.playerNameDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            )

            Button("Back to home") {
                viewModel.leaveGame()
            }
            .frame(minHeight: 44)
        }
        .padding()
    }
}

// MARK: - Grid

struct GridView: View {
    let gridSize: Int
    let highlightedCell: Int?

    private var columns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 6), count: gridSize)
    }

    private var cellCount: Int { gridSize * gridSize }

    var body: some View {
        LazyVGrid(columns: columns, spacing: 6) {
            ForEach(1...cellCount, id: \.self) { cell in
                let isLit = cell == highlightedCell
                RoundedRectangle(cornerRadius: 8)
                    .fill(isLit ? Color.blue : Color.gray.opacity(0.25))
                    .aspectRatio(1, contentMode: .fit)
                    .scaleEffect(isLit ? 1.04 : 1.0)
                    .animation(.easeInOut(duration: 0.12), value: highlightedCell)
                    .accessibilityLabel(isLit ? "Cell \(cell) active" : "Cell \(cell)")
            }
        }
        // Keep the grid square across phones, tablets, portrait, and landscape.
        .aspectRatio(1, contentMode: .fit)
    }
}

// MARK: - Match button with green (hit) / orange (false alarm) feedback

struct MatchButton: View {
    let title: String
    let flash: MatchButtonFlash
    let action: () -> Void

    private var backgroundColor: Color {
        switch flash {
        case .none: return .blue
        case .correct: return .green
        case .wrong: return .orange
        }
    }

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.title3.bold())
                .frame(maxWidth: .infinity)
                .frame(minHeight: 48) // accessibility: minimum touch target (~44pt+)
                .padding(.vertical, 8)
                .foregroundColor(.white)
                .background(backgroundColor)
                .cornerRadius(14)
                .scaleEffect(flash == .none ? 1.0 : 1.06)
                .animation(.spring(response: 0.25, dampingFraction: 0.6), value: flash)
        }
        .accessibilityLabel(title)
        .accessibilityHint("Registers an n-back match for this channel")
    }
}

struct GameView_Previews: PreviewProvider {
    static var previews: some View {
        GameView()
            .environmentObject(N_Back_SwiftUIVM())
    }
}
