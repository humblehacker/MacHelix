import ComposableArchitecture
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
        public var terminalState: TerminalFeature.State
        public init(terminalState: TerminalFeature.State = TerminalFeature.State()) {
            self.terminalState = terminalState
        }
    }

    public enum Action: Equatable {
        case terminal(TerminalFeature.Action)
    }

    public var body: some ReducerProtocol<State, Action> {
        Scope(state: \.terminalState, action: /Action.terminal) { TerminalFeature() }
            ._printChanges()

        Reduce { state, action in
            switch action {
            case .terminal(_):
                return .none
            }

        }
    }
}
