import AppKit
import Combine
import ComposableArchitecture
import Foundation
import SwiftTerm

private enum TerminalManagerKey: DependencyKey {
    @MainActor static let liveValue = TerminalManager()
}

public extension DependencyValues {
    var terminalManager: TerminalManager {
        get { self[TerminalManagerKey.self] }
        set { self[TerminalManagerKey.self] = newValue }
    }
}

@MainActor
public class TerminalManager: ObservableObject {
    var cancellables: Set<AnyCancellable> = []
    var terminalsByUUID: [UUID: TerminalHolder] = [:]
    var uuidsByTag: [ObjectIdentifier: UUID] = [:]
    var nextTag: Int = 0

    func terminal(for uuid: UUID, store: StoreOf<TerminalFeature>) -> LocalProcessTerminalView {
        if let holder = terminalHolder(uuid: uuid) {
            return holder.terminal
        }

        let term = LocalProcessTerminalView(frame: .zero)
        term.processDelegate = self
        holdTerminal(store: store, term: term, uuid: uuid)
        return term
    }

    public func shell(
        uuid: UUID,
        args: [String] = [],
        environment: [String: String]? = nil,
        execName: String? = nil
    ) {
        startTerm(
            uuid: uuid,
            executable: shell(),
            args: args,
            environment: environment,
            execName: execName
        )
    }

    public func startTerm(
        uuid: UUID,
        executable: String,
        args: [String] = [],
        environment: [String: String]? = nil,
        execName: String? = nil
    ) {
        guard let holder = terminalHolder(uuid: uuid) else { return }

        var derivedEnvironment: [String: String] = [:]
        if let environment {
            derivedEnvironment = Terminal.getEnvironmentVariables(termName: "ansi", trueColor: true, other: ["SHELL"])
                .merging(environment, uniquingKeysWith: { _, new in new })
        }

        holder.terminal.startProcess(
            executable: executable,
            args: args,
            environment: derivedEnvironment.toVars(),
            execName: execName
        )
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

extension TerminalManager: LocalProcessTerminalViewDelegate {
    public func sizeChanged(source: SwiftTerm.LocalProcessTerminalView, newCols: Int, newRows: Int) {}

    public func setTerminalTitle(source: SwiftTerm.LocalProcessTerminalView, title: String) {}

    public func hostCurrentDirectoryUpdate(source: SwiftTerm.TerminalView, directory: String?) {
//        guard
//            let directory,
//            let holder = terminalHolder(tag: ObjectIdentifier(source))
//        else { return }
//        holder.viewStore.send(.currentDirectoryChanged(URL(string: directory)!))
    }

    public func processTerminated(source: SwiftTerm.TerminalView, exitCode: Int32?) {
        print("process terminated: \(exitCode ?? 0)")
        exit(exitCode ?? 0)
    }
}

extension Terminal {
    // modified copy of Terminal.getEnvironmentVariables(termName:trueColor) in SwiftTerm
    public static func getEnvironmentVariables(termName: String? = nil, trueColor: Bool = true, other: [String] = []) -> [String: String] {
        let localEnv: [String: String] = [
            "TERM": "\(termName ?? "xterm-256color")",
            "COLORTERM": trueColor ? "truecolor" : "",
            "LANG": "en_US.UTF-8" // Without this, tools like "vi" produce sequences that are not UTF-8 friendly
        ]

        let varsToCopy = ["LOGNAME", "USER", "DISPLAY", "LC_TYPE", "USER", "HOME"] + other
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
