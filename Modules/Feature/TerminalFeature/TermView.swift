//
//  TermView.swift
//  FileManager
//
//  Created by David Whetstone on 12/23/22.
//

import Combine
import ComposableArchitecture
import SwiftTerm
import SwiftUI

public struct TermView: NSViewRepresentable {
    @Dependency(\.terminalManager) var terminalManager: TerminalManager
    var store: StoreOf<TerminalFeature>

    public init(store: StoreOf<TerminalFeature>) {
        self.store = store
    }

    public func makeNSView(context: Context) -> SwiftTerm.TerminalView {
        let vs = ViewStore(store)
        return terminalManager.terminal(for: vs.state.uuid, store: store)
    }

    public func updateNSView(_ nsView: SwiftTerm.TerminalView, context: Context) {
    }
}

struct TermView_Previews: PreviewProvider {
    static var previews: some View {
        TermView(
            store: Store(
                initialState: TerminalFeature.State(currentDirectory: nil),
                reducer: TerminalFeature()
            )
        )
    }
}


