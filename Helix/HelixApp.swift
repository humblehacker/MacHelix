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

    var body: some Scene {
        WindowGroup {
            ContentView(store: store)
        }
    }
}
