import ComposableArchitecture
import Foundation
import TerminalFeature

public struct HelixFeature: ReducerProtocol, Sendable {
    @Dependency(\.ipcManager) var ipcManager
    public var terminalState: TerminalFeature.State
    private static let pipePathPrefix: String = "\(Bundle.main.bundleIdentifier!).\(ProcessInfo.processInfo.processIdentifier)"
    private let inputPipeURL = URL(fileURLWithPath: "/tmp/\(pipePathPrefix).input.pipe")
    private let outputPipeURL = URL(fileURLWithPath: "/tmp/\(pipePathPrefix).output.pipe")

    public init() {
        terminalState = TerminalFeature.State()
    }

    public struct State: Equatable, Sendable {
        public var terminalState: TerminalFeature.State
        public var currentFileURL: URL?

        public init(
            terminalState: TerminalFeature.State = TerminalFeature.State(),
            currentFileURL: URL? = nil
        ) {
            self.terminalState = terminalState
            self.currentFileURL = currentFileURL
        }
    }

    public enum Action: Equatable, Sendable {
        case terminal(TerminalFeature.Action)
        case start(args: [String])
        case fileDropped(_ url: URL)
        case fileChanged(_ url: URL)
    }

    public var body: some ReducerProtocol<State, Action> {
        Scope(state: \.terminalState, action: /Action.terminal) { TerminalFeature() }

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

                return .run { [ipcManager] send in
                    await send(.terminal(.startShell(args: shellArgs, env: env)))
                    await ipcManager.start(inputPipeURL: inputPipeURL, outputPipeURL: outputPipeURL)

                    for await message in await ipcManager.serverMessages {
                        print(message)
                        let parts = message.components(separatedBy: ":")
                        let (command, rest) = (parts.first, parts.dropFirst())
                        switch command {
                        case "fileChanged":
                            await send(.fileChanged(URL(fileURLWithPath: rest.first!)))
                        default:
                            print("unknown command \(message)")
                        }
                    }
                }

            case .fileChanged(let url):
                state.currentFileURL = url
                return .none

            case .fileDropped(let url):
                return .run { send in await
                    ipcManager.sendMessage("openFile:\(url.path)")
                }
            }
        }
    }
}
