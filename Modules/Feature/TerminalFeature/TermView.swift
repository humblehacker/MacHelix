import Combine
import ComposableArchitecture
import Common
import SwiftTerm
import SwiftUI

public struct TermView: NSViewRepresentable {
    @Dependency(\.terminalManager) var terminalManager: TerminalManager
    var store: StoreOf<TerminalFeature>

    public init(store: StoreOf<TerminalFeature>) {
        self.store = store
    }

    public func makeNSView(context: Context) -> SwiftTerm.TerminalView {
        let vs = context.coordinator.viewStore
        let view = terminalManager.terminal(for: vs.state.uuid, store: store)
        if let color = vs.backgroundColor {
            view.nativeBackgroundColor = color.toNSColor()
        }
        return view
    }

    public func updateNSView(_ nsView: SwiftTerm.TerminalView, context: Context) {
        let vs = context.coordinator.viewStore
        if let color = vs.backgroundColor {
            nsView.nativeBackgroundColor = color.toNSColor()
        }
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(viewStore: ViewStore(store, observe: { $0 }))
    }

    public class Coordinator {
        var viewStore: ViewStoreOf<TerminalFeature>

        init(viewStore: ViewStoreOf<TerminalFeature>) {
            self.viewStore = viewStore
        }
    }
}

extension Common.Color {
    func toNSColor() -> NSColor {
        NSColor(red: Double(red)/256, green: Double(green)/256, blue: Double(blue)/256, alpha: 1.0)
    }
}

struct TermView_Previews: PreviewProvider {
    static var previews: some View {
        TermView(
            store: Store(
                initialState: TerminalFeature.State()) {
                    TerminalFeature()
                }
            )
    }
}
