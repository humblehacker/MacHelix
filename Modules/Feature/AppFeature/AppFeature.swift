import ComposableArchitecture
import Foundation
import TerminalFeature
import HelixFeature

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
        public var helixState: HelixFeature.State
        public init(helixState: HelixFeature.State = HelixFeature.State()) {
            self.helixState = helixState
        }
    }

    public enum Action: Equatable {
        case helix(HelixFeature.Action)
        case fileDropped(URL)
    }

    public var body: some ReducerProtocol<State, Action> {
        Scope(state: \.helixState, action: /Action.helix) { HelixFeature() }
            ._printChanges()

        Reduce { state, action in
            switch action {

            case .helix(_):
                return .none

            case .fileDropped(let url):
                // TODO: setting currentDocumentURL here is temporary until IPC from hx is implemented
                state.currentDocumentURL = url
                return .run { send in
                    await send(.helix(.fileDropped(url)))
                }
            }
        }
    }
}
