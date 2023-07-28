import AppKit
import Combine
import ComposableArchitecture
import Foundation
import SwiftTerm

private enum TerminalManagerKey: DependencyKey {
    @MainActor static let liveValue = TerminalManager()
}

extension DependencyValues {
    var terminalManager: TerminalManager {
        get { self[TerminalManagerKey.self] }
        set { self[TerminalManagerKey.self] = newValue }
    }
}

@MainActor
public class TerminalManager: ObservableObject {
    let ipcManager: IPCManager
    var cancellables: Set<AnyCancellable> = []
    var terminalsByUUID: [UUID: TerminalHolder] = [:]
    var uuidsByTag: [ObjectIdentifier: UUID] = [:]
    var nextTag: Int = 0

    public init() {
        let pipePathPrefix: String = "\(Bundle.main.bundleIdentifier!).\(ProcessInfo.processInfo.processIdentifier)"
        self.ipcManager = IPCManager(
            inputPipeURL: URL(fileURLWithPath: "/tmp/\(pipePathPrefix).input.pipe"),
            outputPipeURL: URL(fileURLWithPath: "/tmp/\(pipePathPrefix).output.pipe")
        )
    }

    func terminal(for uuid: UUID, store: StoreOf<TerminalFeature>) -> LocalProcessTerminalView {
        if let holder = terminalHolder(uuid: uuid) {
            return holder.terminal
        }

        let term = LocalProcessTerminalView(frame: .zero)
        term.processDelegate = self
        holdTerminal(store: store, term: term, uuid: uuid)
        return term
    }

    let helixPath = "/Users/david/src/helix/target/debug/hx"

    func startTerm(uuid: UUID) {
        guard let holder = terminalHolder(uuid: uuid) else { return }

        let vars = Terminal.getEnvironmentVariables(termName: "ansi", trueColor: true, additionalVarsToCopy: ["SHELL"])
        let ipcArgs: [String] = [
//            "--ipc-input \(ipcManager.inputPipeURL.path)",
//            "--ipc-output \(ipcManager.outputPipeURL.path)"
        ]
        let cmd = [helixPath] + holder.viewStore.startupArgs.dropFirst() + ipcArgs
        let args = ["-l", "-c", cmd.joined(separator: " ")]
        let shell = shell()

        print("launching \(shell) \(args)")

        holder.terminal.startProcess(executable: shell, args: args, environment: vars.toVars())
    }

    func openFile(url: URL) {
        ipcManager.sendMessage("openFile:\(url.path)")
    }
    
    private func holdTerminal(store: StoreOf<TerminalFeature>, term: LocalProcessTerminalView, uuid: UUID) {
        let holder = TerminalHolder(store: store, terminal: term)
        terminalsByUUID[uuid] = holder
        uuidsByTag[holder.tag] = uuid
    }

    private func terminalHolder(uuid: UUID) -> TerminalHolder? {
        terminalsByUUID[uuid]
    }

    private func terminalHolder(tag: ObjectIdentifier) -> TerminalHolder? {
        guard let uuid = uuidsByTag[tag] else { return nil }
        return terminalHolder(uuid: uuid)
    }

    private func shell() -> String {
        let env = ProcessInfo.processInfo.environment
        let shell = env["SHELL"] ?? "/bin/zsh"
        return shell
    }
}

// TODO: this isn't really the right abstraction. The whole TerminalFeature and relation to helix needs to be rethought
@MainActor
class IPCManager {
    let inputPipeURL: URL
    let outputPipeURL: URL

    init(inputPipeURL: URL, outputPipeURL: URL) {
        self.inputPipeURL = inputPipeURL
        self.outputPipeURL = outputPipeURL

        createPipes()

        NotificationCenter.default.addObserver(forName: NSApplication.willTerminateNotification, object: nil, queue: nil) { [weak self] notification in
            guard let self else { return }
            self.sendMessage("exit")
            self.removePipes()
        }
    }

    private func createPipes() {
        mkfifo(inputPipeURL.path, 0o700)
        mkfifo(outputPipeURL.path, 0o700)
    }

    private func removePipes() {
        try? FileManager.default.removeItem(at: inputPipeURL)
        try? FileManager.default.removeItem(at: outputPipeURL)
    }

    func sendMessage(_ message: String) {
        let fileHandle = try! FileHandle(forWritingTo: inputPipeURL)
        defer { try! fileHandle.close() }

        let secData = message.data(using: .utf8)
        if let secData = secData {
            try! fileHandle.write(contentsOf: secData)
        }
    }
}

extension TerminalManager: LocalProcessTerminalViewDelegate {
    public func sizeChanged(source: SwiftTerm.LocalProcessTerminalView, newCols: Int, newRows: Int) {}

    public func setTerminalTitle(source: SwiftTerm.LocalProcessTerminalView, title: String) {}

    public func hostCurrentDirectoryUpdate(source: SwiftTerm.TerminalView, directory: String?) {
        guard
            let directory,
            let holder = terminalHolder(tag: ObjectIdentifier(source))
        else { return }
        holder.viewStore.send(.currentDirectoryChanged(URL(string: directory)!))
    }

    public func processTerminated(source: SwiftTerm.TerminalView, exitCode: Int32?) {
        print("process terminated: \(exitCode ?? 0)")
        exit(exitCode ?? 0)
    }
}

extension Terminal {
    public static func getEnvironmentVariables(termName: String? = nil, trueColor: Bool = true, additionalVarsToCopy: [String] = []) -> [String: String] {
        let localEnv: [String: String] = [
            "TERM": "\(termName ?? "xterm-256color")",
            "COLORTERM": trueColor ? "truecolor" : "",
            "LANG": "en_US.UTF-8", // Without this, tools like "vi" produce sequences that are not UTF-8 friendly
            "HELIX_RUNTIME": "/Users/david/src/helix/runtime" // TODO: how to configure this?
        ]

        let varsToCopy = ["LOGNAME", "USER", "DISPLAY", "LC_TYPE", "USER", "HOME"] + additionalVarsToCopy
        return ProcessInfo.processInfo.environment
                          .filter { varsToCopy.contains($0.key) }
                          .merging(localEnv, uniquingKeysWith: { l, r in l })
    }
}

extension Dictionary where Key == String, Value == String {
    func toVars() -> [String] {
        map { key, value in "\(key)=\(value)" }
    }
}
