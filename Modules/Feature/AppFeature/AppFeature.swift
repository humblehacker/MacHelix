import ComposableArchitecture
import Foundation
import TerminalFeature

public enum Position {
    case left
    case right
    case top
    case bottom
}

public struct AppFeature: ReducerProtocol {

    public init() {}

    public struct State: Equatable {
        public var currentDocumentURL: URL?
        public var terminalState: TerminalFeature.State
        public init(terminalState: TerminalFeature.State = TerminalFeature.State()) {
            self.terminalState = terminalState
        }
    }

    public enum Action: Equatable {
        case terminal(TerminalFeature.Action)
        case fileDropped(URL)
    }

    public var body: some ReducerProtocol<State, Action> {
        Scope(state: \.terminalState, action: /Action.terminal) { TerminalFeature() }
            ._printChanges()

        Reduce { state, action in
            switch action {

            case .terminal(_):
                return .none
                
            case .fileDropped(let url):
                // TODO: setting currentDocumentURL here is temporary until IPC from hx is implemented
                state.currentDocumentURL = url
                return .run { send in
                    await send(.terminal(.fileDropped(url)))
                }
            }
        }
    }
}
