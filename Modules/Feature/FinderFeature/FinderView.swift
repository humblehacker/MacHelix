//
//  FinderView.swift
//  FileManager
//
//  Created by David Whetstone on 12/24/22.
//

import ComposableArchitecture
import SwiftUI

public struct FinderView: View {
    let store: StoreOf<FinderFeature>

    public init(store: StoreOf<FinderFeature>) {
        self.store = store
    }

    public var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            Text(viewStore.currentDirectory?.path ?? "Not defined")
                .background(Color.orange)
        }
    }
}

struct FinderView_Previews: PreviewProvider {
    static var previews: some View {
        FinderView(
            store: Store(
                initialState: FinderFeature.State(currentDirectory: URL(string: "/Users/fooby/some-directory")),
                reducer: FinderFeature()
            )
        )
    }
}
