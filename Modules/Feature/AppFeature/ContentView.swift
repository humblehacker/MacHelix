//
//  ContentView.swift
//  FileManager
//
//  Created by David Whetstone on 12/23/22.
//

import ComposableArchitecture
import SwiftUI
import TerminalFeature

public struct ContentView: View {
    let store: StoreOf<AppFeature>

    public init(store: StoreOf<AppFeature>) {
        self.store = store
    }

    public var body: some View {
        WithViewStore(store) { viewStore in
            TermView(store: store.scope(state: \.terminalState, action: AppFeature.Action.terminal))
                .padding(4)
                .background(Color.black)
        }
    }
}

 struct ContentView_Previews: PreviewProvider {
     static var previews: some View {
         NavigationStack {
             ContentView(
                store: Store(
                    initialState: AppFeature.State(),
                    reducer: AppFeature()
                )
             )
         }
         .previewLayout(.sizeThatFits)
     }
 }
