//
//  ContentView.swift
//  N-Back-SwiftUI
//
//  Created by Jonas Willén on 2023-09-19.
//

import SwiftUI

/// Root view: Home (with navigation to Settings / Scores) or Game from ViewModel phase.
/// The ViewModel does not navigate itself — the View observes `phase`.
struct ContentView: View {
    @EnvironmentObject var theViewModel: N_Back_SwiftUIVM

    var body: some View {
        Group {
            if theViewModel.phase == .idle {
                NavigationStack {
                    HomeView()
                }
            } else {
                GameView()
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ContentView()
                .environmentObject(N_Back_SwiftUIVM())
                .previewDevice(PreviewDevice(rawValue: "iPhone 14 Pro Max"))
                .previewDisplayName("iPhone 14 Pro Max")

            ContentView()
                .environmentObject(N_Back_SwiftUIVM())
                .previewDevice(PreviewDevice(rawValue: "iPhone SE (3rd generation)"))
                .previewDisplayName("iPhone SE")

            ContentView()
                .environmentObject(N_Back_SwiftUIVM())
                .previewDevice(PreviewDevice(rawValue: "iPad (A16)"))
                .previewDisplayName("iPad")

            ContentView()
                .environmentObject(N_Back_SwiftUIVM())
                .previewDevice(PreviewDevice(rawValue: "iPhone 14 Pro Max"))
                .previewInterfaceOrientation(.landscapeRight)
                .previewDisplayName("Landscape")
        }
    }
}
