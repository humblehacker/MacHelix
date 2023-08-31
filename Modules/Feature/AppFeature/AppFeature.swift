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

public struct AppFeature: Reducer {

    public init() {}

    public struct State: Equatable {
        public var mouseReportingEnabled: Bool = true
        public var currentDocumentURL: URL?
        public var helixState: HelixFeature.State
        public init(helixState: HelixFeature.State = HelixFeature.State()) {
            self.helixState = helixState
        }
    }

    public enum Action: Equatable, Sendable {
        case helix(HelixFeature.Action)
        case fileDropped(URL)
        case mouseReportingToggled
    }

    public var body: some Reducer<State, Action> {
        Scope(state: \.helixState, action: /Action.helix) { HelixFeature() }
            ._printChanges()

        Reduce { state, action in
            switch action {

            case .mouseReportingToggled:
                state.mouseReportingEnabled.toggle()
                return .send(.helix(.terminal(.mouseReportingChanged(enabled: state.mouseReportingEnabled))))

            case .helix(.fileChanged(let url)):
                state.currentDocumentURL = url
                return .none

            case .helix(_):
                return .none

            case .fileDropped(let url):
                return .run { send in
                    await send(.helix(.fileDropped(url)))
                }
            }
        }._printChanges()
    }
}
