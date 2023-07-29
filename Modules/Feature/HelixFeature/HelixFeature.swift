import ComposableArchitecture
import Foundation
import TerminalFeature

public struct HelixFeature: ReducerProtocol {
    @Dependency(\.ipcManager) var ipcManager
    public var terminalState: TerminalFeature.State
    private static let pipePathPrefix: String = "\(Bundle.main.bundleIdentifier!).\(ProcessInfo.processInfo.processIdentifier)"
    private let inputPipeURL = URL(fileURLWithPath: "/tmp/\(pipePathPrefix).input.pipe")
    private let outputPipeURL = URL(fileURLWithPath: "/tmp/\(pipePathPrefix).output.pipe")

    public init() {
        terminalState = TerminalFeature.State()
    }

    public struct State: Equatable {
        public var terminalState: TerminalFeature.State

        public init(terminalState: TerminalFeature.State = TerminalFeature.State()) {
            self.terminalState = terminalState
        }
    }

    public enum Action: Equatable {
        case terminal(TerminalFeature.Action)
        case start(args: [String])
        case fileDropped(_ url: URL)
    }

    public var body: some ReducerProtocol<State, Action> {
        Scope(state: \.terminalState, action: /Action.terminal) { TerminalFeature() }
            ._printChanges()

        Reduce { state, action in
            switch action {
            case .terminal(_):
                return .none

            case .start(let startupArgs):
                let helixRoot = Bundle.main.bundleURL.appendingPathComponent("Contents/helix")
                let helixPath = helixRoot.appendingPathComponent("bin/hx")

                let additionalArgs: [String] = [
                    "--ipc-input \(inputPipeURL.path)",
                    "--ipc-output \(outputPipeURL.path)"
                ]
                let cmd = [helixPath.path] + startupArgs.dropFirst() + additionalArgs
                let shellArgs = ["-l", "-c", cmd.joined(separator: " ")]

                let env = ["HELIX_RUNTIME": helixRoot.appendingPathComponent("runtime").path]

                return .run { @MainActor send in
                    send(.terminal(.startShell(args: shellArgs, env: env)))
                    await ipcManager.start(inputPipeURL: inputPipeURL, outputPipeURL: outputPipeURL)
                }

            case .fileDropped(let url):
                return .run { send in await
                    ipcManager.sendMessage("openFile:\(url.path)")
                }
            }
        }
    }
}
