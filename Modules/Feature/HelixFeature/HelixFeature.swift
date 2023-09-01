import ComposableArchitecture
import Common
import Foundation
import TerminalFeature

public struct HelixFeature: Reducer, Sendable {
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
        public var backgroundColor: Color?

        public init(
            terminalState: TerminalFeature.State = TerminalFeature.State(),
            currentFileURL: URL? = nil,
            backgroundColor: Color? = nil
        ) {
            self.terminalState = terminalState
            self.currentFileURL = currentFileURL
            self.backgroundColor = backgroundColor
        }
    }

    public enum Action: Equatable, Sendable {
        case terminal(TerminalFeature.Action)
        case start(args: [String])
        case fileDropped(_ url: URL)
        case fileChanged(_ url: URL)
        case themeChanged(bgColor: Color)
        case cutMenuSelected
        case copyMenuSelected
        case pasteMenuSelected
        case selectAllMenuSelected
    }

    public var body: some Reducer<State, Action> {
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
                    "--ipc-output \(outputPipeURL.path)",
                    "-vvv"
                ]
                let cmd = [helixPath.path] + startupArgs.dropFirst() + additionalArgs
                let shellArgs = ["-l", "-c", cmd.joined(separator: " ")]

                let env = ["HELIX_RUNTIME": helixRoot.appendingPathComponent("runtime").path]


                return .run { [ipcManager] send in
                    await send(.terminal(.startShell(args: shellArgs, env: env)))
                    await ipcManager.start(inputPipeURL: inputPipeURL, outputPipeURL: outputPipeURL)
                    Task { await ipcManager.sendMessage("force_theme_update:") }

                    for await message in await ipcManager.serverMessages {
                        print(message)
                        let (command, rest) = parseMessage(message)

                        switch command {
                        case "fileChanged":
                            await send(.fileChanged(URL(fileURLWithPath: rest.first!)))

                        case "themeChanged":
                            // rest should contain #RGB value
                            let rgb = Color(hexColorString: rest.first!)
                            await send(.themeChanged(bgColor: rgb))

                        default:
                            print("unknown command \(message)")
                        }
                    }
                }

            case .fileChanged(let url):
                state.currentFileURL = url
                return .none

            case .themeChanged(bgColor: let bgColor):
                state.backgroundColor = bgColor
                return .send(.terminal(.backgroundColorChanged(bgColor)))

            case .fileDropped(let url):
                return .run { send in await ipcManager.sendMessage(":open \(url.path)") }

            case .cutMenuSelected:
                return .run { send in await ipcManager.sendMessage("cut") }

            case .copyMenuSelected:
                return .run { send in await ipcManager.sendMessage(":clipboard-yank") }

            case .pasteMenuSelected:
                return .run { send in await ipcManager.sendMessage(":clipboard-paste-before") }

            case .selectAllMenuSelected:
                return .run { send in await ipcManager.sendMessage("static_command:select_all") }
            }
        }
    }


    func parseMessage(_ message: String) -> (String, [String]) {
        let parts = message.split(separator: ":", maxSplits: 1)
        let command = String(parts.first!)
        let rest = parts
            .dropFirst()
            .joined()
            .components(separatedBy: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }

        return (command, rest)
    }
}
