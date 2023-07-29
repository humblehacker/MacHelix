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
                HelixView(store: store.scope(state: \.helixState, action: AppFeature.Action.helix))
                    .task { store.send(.helix(.start(args: args))) }
                    .navigationTitle(viewStore.currentDocumentURL?.lastPathComponent ?? "MacHelix")
                    .navigationDocument(viewStore.currentDocumentURL ?? URL(fileURLWithPath: ""))
                    .dropDestination(for: URL.self) { items, location in
                        guard let url = items.first else { return false }
                        viewStore.send(.fileDropped(url))
                        return true
                    }
            }
        }
        .commands {
            CommandGroup(after: .sidebar) {
                WithViewStore(store) { viewStore in
                    Toggle("Mouse reporting enabled",
                        isOn: viewStore.binding(
                            get: \.mouseReportingEnabled,
                            send: AppFeature.Action.mouseReportingToggled
                        )
                    )
                }
                Divider()
            }
        }
    }
}
