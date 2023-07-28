//
//  HelixApp.swift
//  Helix
//
//  Created by David Whetstone on 7/20/23.
//
//

import AppFeature
import ComposableArchitecture
import TerminalFeature
import SwiftUI

@main
struct HelixApp: App {
    let store: StoreOf<AppFeature> = Store(initialState: AppFeature.State(), reducer: AppFeature())
    var args: [String] = CommandLine.arguments

    init() {
        if args[1] == "-NSDocumentRevisionsDebugMode" {
            args.remove(atOffsets: IndexSet([1, 2]))
        }
        print(args)
    }

    var body: some Scene {
        WindowGroup {
            WithViewStore(store) { viewStore in
                ContentView(store: store)
                    .task { store.send(.terminal(.start(args: args))) }
                    .navigationTitle(viewStore.currentDocumentURL?.lastPathComponent ?? "MacHelix")
                    .navigationDocument(viewStore.currentDocumentURL ?? URL(fileURLWithPath: ""))
                    .dropDestination(for: URL.self) { items, location in
                        guard let url = items.first else { return false }
                        viewStore.send(.fileDropped(url))
                        return true
                    }
            }
        }
        .windowStyle(.automatic)
    }
}
