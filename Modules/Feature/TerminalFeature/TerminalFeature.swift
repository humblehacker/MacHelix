import ComposableArchitecture
import Foundation

public struct TerminalFeature: ReducerProtocol {
    @Dependency(\.terminalManager) var terminalManager: TerminalManager
    public init() {}

    public struct State: Equatable {
        public var startupArgs: [String] = []
        public var currentDirectory: URL?
        public let uuid: UUID = UUID()

        public init(currentDirectory: URL? = nil) { self.currentDirectory = currentDirectory }
    }

    public enum Action: Equatable {
        case start(args: [String])
        case currentDirectoryChanged(_ directory: URL)
    }

    public func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
        switch action {
        case .currentDirectoryChanged(let dir):
            state.currentDirectory = dir
            return .none

        case .start(args: let args):
            state.startupArgs = args
            let uuid = state.uuid
            return .run { send in
                await terminalManager.startTerm(uuid: uuid)
            }
        }
    }
}
