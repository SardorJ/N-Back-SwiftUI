//
//  ActionIconView.swift
//  N-Back-SwiftUI
//
//  Created by Jonas Willén on 2023-10-03.
//
//  Kept from the starter template. HomeView is the main entry UI now;
//  this view remains as a simple stimulus-picker helper if needed later.
//

import SwiftUI

struct ActionIconView: View {
    @EnvironmentObject var theViewModel: N_Back_SwiftUIVM

    var body: some View {
        VStack(alignment: .center) {
            Text("STIMULUS").font(.largeTitle)
            HStack(spacing: 30) {
                Button {
                    theViewModel.selectStimulus(.auditory)
                } label: {
                    SoundIconView()
                }
                Button {
                    theViewModel.selectStimulus(.visual)
                } label: {
                    ImageIconView()
                }
            }
        }
    }
}

struct ActionIconView_Previews: PreviewProvider {
    static var previews: some View {
        ActionIconView()
            .environmentObject(N_Back_SwiftUIVM())
    }
}
