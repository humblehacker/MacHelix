import AppFeature
import ComposableArchitecture
import TerminalFeature
import SwiftUI
import SwiftUIIntrospect

@main
struct HelixApp: App {
    let store = Store(initialState: AppFeature.State()) { AppFeature() }
    @ObservedObject var viewStore: ViewStoreOf<AppFeature>
    var args: [String] = CommandLine.arguments

    init() {
        if args[1] == "-NSDocumentRevisionsDebugMode" {
            args.remove(atOffsets: IndexSet([1, 2]))
        }
        print(args)
        self.viewStore = ViewStore(self.store, observe: { $0 })
    }

    var body: some Scene {
        WindowGroup {
            HelixView(store: store.scope(state: \.helixState, action: AppFeature.Action.helix))
                .task { store.send(.helix(.start(args: args))) }
                .navigationTitle(viewStore.currentDocumentURL?.lastPathComponent ?? "MacHelix")
                .navigationDocument(viewStore.currentDocumentURL ?? URL(fileURLWithPath: ""))
                .dropDestination(for: URL.self) { items, location in
                    guard let url = items.first else { return false }
                    viewStore.send(.fileDropped(url))
                    return true
                }
                .toolbar { ToolbarItem { Spacer() } } // empty toolbar forces title to left
                .introspect(.window, on: .macOS(.v14)) { window in
                    window.titlebarAppearsTransparent = true
                    NSApp.appearance = NSAppearance(named: viewStore.isDarkMode ? .darkAqua : .aqua)
                }
        }
        .windowStyle(.automatic)
        .windowToolbarStyle(.unified)
        .commands {
            CommandGroup(replacing: CommandGroupPlacement.pasteboard) {
                Button("Cut") { viewStore.send(.helix(.cutMenuSelected))}
                    .keyboardShortcut("x", modifiers: [.command])

                Button("Copy") { viewStore.send(.helix(.copyMenuSelected)) }
                    .keyboardShortcut("c", modifiers: [.command])

                Button("Paste") { viewStore.send(.helix(.pasteMenuSelected)) }
                    .keyboardShortcut("v", modifiers: [.command])
            }
            CommandGroup(after: .sidebar) {
                Toggle("Mouse reporting enabled",
                    isOn: viewStore.binding(
                        get: \.mouseReportingEnabled,
                        send: AppFeature.Action.mouseReportingToggled
                    )
                )
            }
        }
    }
}
