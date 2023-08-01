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
        let view = terminalManager.terminal(for: vs.state.uuid, store: store)
        // TODO: set color to match helix's background color
        view.nativeBackgroundColor = NSColor(red: 41/256, green: 42/256, blue: 54/256, alpha: 1.0)
        return view
    }

    public func updateNSView(_ nsView: SwiftTerm.TerminalView, context: Context) {
    }
}

struct TermView_Previews: PreviewProvider {
    static var previews: some View {
        TermView(
            store: Store(
                initialState: TerminalFeature.State(),
                reducer: TerminalFeature()
            )
        )
    }
}
