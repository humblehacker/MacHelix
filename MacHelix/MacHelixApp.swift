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
    let args: [String] = CommandLine.arguments

    init() {
        print(args)
    }

    var body: some Scene {
        WindowGroup {
            ContentView(store: store)
                .task {
                    await store.send(.terminal(.start(args: args)))
                }
        }.windowStyle(HiddenTitleBarWindowStyle())
    }
}
