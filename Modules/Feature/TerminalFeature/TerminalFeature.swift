import ComposableArchitecture
import Foundation

public struct TerminalFeature: ReducerProtocol {
    public init() {}

    public struct State: Equatable {
        public var currentDirectory: URL?
        public let uuid: UUID = UUID()

        public init(currentDirectory: URL? = nil) { self.currentDirectory = currentDirectory }
    }

    public enum Action: Equatable {
        case currentDirectoryChanged(_ directory: URL)
    }

    public func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
        switch action {
        case .currentDirectoryChanged(let dir):
            state.currentDirectory = dir
            return .none
        }
    }
}
