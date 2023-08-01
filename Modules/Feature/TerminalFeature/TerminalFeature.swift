import ComposableArchitecture
import Foundation

public struct TerminalFeature: ReducerProtocol {
    @Dependency(\.terminalManager) var terminalManager: TerminalManager
    public init() {}

    public struct State: Equatable, Sendable {
        public let uuid: UUID = UUID()

        public init() {}
    }

    public enum Action: Equatable, Sendable {
        case mouseReportingChanged(enabled: Bool)
        case startShell(args: [String], env: [String: String])
    }

    public func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
        switch action {
        case .mouseReportingChanged(let enabled):
            return .run { [uuid = state.uuid] send in
                await terminalManager.setMouseReporting(enabled: enabled, uuid: uuid)
            }

        case .startShell(args: let args, env: let env):
            return .run { [uuid = state.uuid] send in
                await terminalManager.shell(uuid: uuid, args: args, environment: env)
            }
        }
    }
}
