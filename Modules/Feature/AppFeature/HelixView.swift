//
//  ContentView.swift
//  FileManager
//
//  Created by David Whetstone on 12/23/22.
//

import ComposableArchitecture
import Common
import HelixFeature
import SwiftUI
import TerminalFeature

public struct HelixView: View {
    let store: StoreOf<HelixFeature>

    public init(store: StoreOf<HelixFeature>) {
        self.store = store
    }

    public var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            TermView(store: store.scope(state: \.terminalState, action: HelixFeature.Action.terminal))
                .padding(4)
                .background(viewStore.backgroundColor?.toSwiftUI() ?? SwiftUI.Color.blue)
        }
    }
}

 struct ContentView_Previews: PreviewProvider {
     static var previews: some View {
         NavigationStack {
             HelixView(
                store: Store(initialState: HelixFeature.State()) {
                    HelixFeature()
                }
             )
         }
         .previewLayout(.sizeThatFits)
     }
 }

extension Common.Color {
    func toSwiftUI() -> SwiftUI.Color {
        SwiftUI.Color(red: Double(red)/256, green: Double(green)/256, blue: Double(blue)/256)
    }
}
