import ComposableArchitecture
import Common
import Foundation

public struct TerminalFeature: Reducer {
    @Dependency(\.terminalManager) var terminalManager: TerminalManager
    public init() {}

    public struct State: Equatable, Sendable {
        public let uuid: UUID = UUID()
        public var backgroundColor: Color? = nil

        public init() {}
    }

    public enum Action: Equatable, Sendable {
        case mouseReportingChanged(enabled: Bool)
        case startShell(args: [String], env: [String: String])
        case backgroundColorChanged(_ color: Color)
    }

    public func reduce(into state: inout State, action: Action) -> Effect<Action> {
        switch action {
        case .mouseReportingChanged(let enabled):
            return .run { [uuid = state.uuid] send in
                await terminalManager.setMouseReporting(enabled: enabled, uuid: uuid)
            }

        case .startShell(args: let args, env: let env):
            return .run { [uuid = state.uuid] send in
                await terminalManager.shell(uuid: uuid, args: args, environment: env)
            }
        case .backgroundColorChanged(let color):
            state.backgroundColor = color
            return .none
        }
    }
}
