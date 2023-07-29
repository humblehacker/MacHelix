//
//  ContentView.swift
//  FileManager
//
//  Created by David Whetstone on 12/23/22.
//

import ComposableArchitecture
import SwiftUI
import TerminalFeature
import HelixFeature

public struct HelixView: View {
    let store: StoreOf<HelixFeature>

    public init(store: StoreOf<HelixFeature>) {
        self.store = store
    }

    public var body: some View {
        WithViewStore(store) { viewStore in
            TermView(store: store.scope(state: \.terminalState, action: HelixFeature.Action.terminal))
                .padding(4)
                .background(Color.black)
        }
    }
}

 struct ContentView_Previews: PreviewProvider {
     static var previews: some View {
         NavigationStack {
             HelixView(
                store: Store(
                    initialState: HelixFeature.State(),
                    reducer: HelixFeature()
                )
             )
         }
         .previewLayout(.sizeThatFits)
     }
 }
