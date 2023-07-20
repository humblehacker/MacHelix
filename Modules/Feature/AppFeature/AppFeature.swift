import ComposableArchitecture
import FinderFeature
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
        public var primaryPosition: Position
        public var terminalState: TerminalFeature.State
        public var finderState: FinderFeature.State {
            get { FinderFeature.State(currentDirectory: terminalState.currentDirectory) }
            set { terminalState.currentDirectory = newValue.currentDirectory }
        }

        public init(primaryPosition: Position = .top, terminalState: TerminalFeature.State = TerminalFeature.State()) {
            self.primaryPosition = primaryPosition
            self.terminalState = terminalState
        }
    }

    public enum Action: Equatable {
        case primaryPositionChanged(Position)
        case finder(FinderFeature.Action)
        case terminal(TerminalFeature.Action)
    }

    public var body: some ReducerProtocol<State, Action> {
        Scope(state: \.finderState, action: /Action.finder) { FinderFeature() }
            ._printChanges()
        Scope(state: \.terminalState, action: /Action.terminal) { TerminalFeature() }
            ._printChanges()

        Reduce { state, action in
            switch action {
            case .primaryPositionChanged(let position):
                state.primaryPosition = position
                return .none
            case .finder(_):
                return .none
            case .terminal(_):
                return .none
            }

        }
    }
}
