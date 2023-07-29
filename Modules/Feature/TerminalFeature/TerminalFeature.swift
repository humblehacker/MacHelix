import ComposableArchitecture
import Foundation

public struct TerminalFeature: ReducerProtocol {
    @Dependency(\.terminalManager) var terminalManager: TerminalManager
    public init() {}

    public struct State: Equatable {
        public let uuid: UUID = UUID()

        public init() {}
    }

    public enum Action: Equatable {
        case startShell(args: [String], env: [String: String])
    }

    public func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
        switch action {
        case .startShell(args: let args, env: let env):
            return .run { [uuid = state.uuid] send in
                await terminalManager.shell(uuid: uuid, args: args, environment: env)
            }
        }
    }
}
