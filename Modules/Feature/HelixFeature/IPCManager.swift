import AppKit
import Dependencies
import Foundation

private enum IPCManagerKey: DependencyKey {
    @MainActor static let liveValue = IPCManager()
}

extension DependencyValues {
    var ipcManager: IPCManager {
        get { self[IPCManagerKey.self] }
        set { self[IPCManagerKey.self] = newValue }
    }
}

actor IPCManager {
    private(set) var inputPipeURL: URL? = nil
    private(set) var outputPipeURL: URL? = nil
    private var notificationTask: Task<Void, Never>?

    init() {}

    public func start(inputPipeURL: URL, outputPipeURL: URL) {
        self.inputPipeURL = inputPipeURL
        self.outputPipeURL = outputPipeURL

        createPipes()

        notificationTask = Task { @MainActor [weak self] in
            for await _ in NotificationCenter.default.notifications(named: NSApplication.willTerminateNotification) {
                guard let self else { return }
                await self.sendMessage("exit")
                await self.removePipes()
            }
        }
    }

    func sendMessage(_ message: String) {
        guard let inputPipeURL = inputPipeURL else { return }

        let fileHandle = try! FileHandle(forWritingTo: inputPipeURL)
        defer { try! fileHandle.close() }

        let secData = message.data(using: .utf8)
        if let secData = secData {
            try! fileHandle.write(contentsOf: secData)
        }
    }

    private func createPipes() {
        guard let inputPipeURL = inputPipeURL, let outputPipeURL = outputPipeURL else { return }
        mkfifo(inputPipeURL.path, 0o700)
        mkfifo(outputPipeURL.path, 0o700)
    }

    private func removePipes() {
        guard let inputPipeURL = inputPipeURL, let outputPipeURL = outputPipeURL else { return }
        try? FileManager.default.removeItem(at: inputPipeURL)
        try? FileManager.default.removeItem(at: outputPipeURL)
    }
}
