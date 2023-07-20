import ComposableArchitecture
import Foundation

public struct FinderFeature: ReducerProtocol {
    public init() {}

    public struct State: Equatable {
        public var currentDirectory: URL?

        public init(currentDirectory: URL?) {
            self.currentDirectory = currentDirectory
        }
    }

    public enum Action: Equatable {
        case currentDirectoryChanged(_ directory: URL)
    }

    public func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
        switch action {

        case .currentDirectoryChanged(let directory):
            state.currentDirectory = directory
            return .none
        }
    }
}
