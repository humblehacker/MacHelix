//
//  TerminalHolder.swift
//  FileManager
//
//  Created by David Whetstone on 12/26/22.
//

import ComposableArchitecture
import Foundation
import SwiftTerm

public class TerminalHolder {
    let store: StoreOf<TerminalFeature>
    let viewStore: ViewStoreOf<TerminalFeature>
    var terminal: LocalProcessTerminalView
    let tag: ObjectIdentifier

    public init(store: StoreOf<TerminalFeature>, terminal: LocalProcessTerminalView) {
        self.store = store
        self.viewStore = ViewStore(store)
        self.terminal = terminal
        self.tag = ObjectIdentifier(terminal)
    }
}
