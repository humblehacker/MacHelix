//
//  ContentView.swift
//  FileManager
//
//  Created by David Whetstone on 12/23/22.
//

import ComposableArchitecture
import FinderFeature
import SwiftUI
import TerminalFeature

public struct ContentView: View {
    let store: StoreOf<AppFeature>

    public init(store: StoreOf<AppFeature>) {
        self.store = store
    }

    public var body: some View {
        WithViewStore(store) { viewStore in
            SplitView(
                primaryPosition: viewStore.primaryPosition,
                primaryContent: {
                    FinderView(store: store.scope(state: \.finderState, action: AppFeature.Action.finder))
                },
                secondaryContent: {
                    TermView(store: store.scope(state: \.terminalState, action: AppFeature.Action.terminal))
                        .padding(4)
                        .background(Color.black)
                }
            )
            .toolbar {
                ToolbarItemGroup {
                    Picker(
                        "",
                        selection: viewStore.binding(
                            get: { $0.primaryPosition },
                            send: { .primaryPositionChanged($0) }
                        )
                    ) {
                        Image(systemName: "square.righthalf.filled").tag(Position.left)
                        Image(systemName: "square.lefthalf.filled").tag(Position.right)
                        Image(systemName: "square.bottomhalf.filled").tag(Position.top)
                        Image(systemName: "square.tophalf.filled").tag(Position.bottom)
                    }
                    .pickerStyle(.segmented)
                }
            }
        }
    }
}

struct SplitView<Content1, Content2>: View where Content1: View, Content2: View {
    let primaryPosition: Position
    let primaryContent: Content1
    let secondaryContent: Content2

    init(primaryPosition: Position,
         @ViewBuilder primaryContent: () -> Content1,
         @ViewBuilder secondaryContent: () -> Content2
    ) {
        self.primaryPosition = primaryPosition
        self.primaryContent = primaryContent()
        self.secondaryContent = secondaryContent()
    }

    var body: some View {
        GeometryReader { geo in
            if (primaryPosition == .top) {
                VSplitView {
                    primaryContent.frame(maxWidth: .infinity, maxHeight: .infinity)
                    secondaryContent.frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .frame(width: geo.size.width, height: geo.size.height)
            } else if primaryPosition == .bottom {
                VSplitView {
                    secondaryContent.frame(maxWidth: .infinity, maxHeight: .infinity)
                    primaryContent.frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .frame(width: geo.size.width, height: geo.size.height)
            } else if primaryPosition == .left {
                HSplitView {
                    primaryContent.frame(maxWidth: .infinity, maxHeight: .infinity)
                    secondaryContent.frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .frame(width: geo.size.width, height: geo.size.height)
            } else if primaryPosition == .right {
                HSplitView {
                    secondaryContent.frame(maxWidth: .infinity, maxHeight: .infinity)
                    primaryContent.frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .frame(width: geo.size.width, height: geo.size.height)
            }
        }
    }
}

 struct ContentView_Previews: PreviewProvider {
     static var previews: some View {
         NavigationStack {
             ContentView(
                store: Store(
                    initialState: AppFeature.State(
                        primaryPosition: Position.right
                    ),
                    reducer: AppFeature()
                )
             )
         }
         .previewLayout(.sizeThatFits)
     }
 }
