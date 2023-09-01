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
    private var childListenTask: Task<Void, Never>? = nil
    private var serverMessagesStream: AsyncStream<String>?
    private var serverMessagesContinuation: AsyncStream<String>.Continuation?

    public var serverMessages: AsyncStream<String> {
        if let stream = serverMessagesStream {
            return stream
        }

        let (stream, continuation) = AsyncStream<String>.makeStream()

        continuation.onTermination = { [weak self] _ in
            guard let self else { return }
            Task {
                await self.resetServerMessages()
            }
        }

        serverMessagesStream = stream
        serverMessagesContinuation = continuation

        return stream
    }

    init() {}

    public func start(inputPipeURL: URL, outputPipeURL: URL) {
        self.inputPipeURL = inputPipeURL
        self.outputPipeURL = outputPipeURL

        createPipes()
        listen()

        notificationTask = Task { [weak self] in
            for await _ in await NotificationCenter.default.notifications(named: NSApplication.willTerminateNotification) {
                guard let self else { return }
                await self.childListenTask?.cancel()
                await self.sendMessage("exit")
                await self.removePipes()
            }
        }
    }

    func sendMessage(_ message: String) {
        guard let inputPipeURL else { return }

        print("sending message \(message)")

        let fileHandle = try! FileHandle(forWritingTo: inputPipeURL)
        defer { try! fileHandle.close() }

        let secData = message.data(using: .utf8)
        if let secData = secData {
            try! fileHandle.write(contentsOf: secData)
        }
    }

    private func resetServerMessages() {
        serverMessagesContinuation?.finish()
        serverMessagesStream = nil
        serverMessagesContinuation = nil
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

    private func listen() {
        guard childListenTask == nil else { return print("already listening") }
        guard let outputPipeURL else { return }

        childListenTask = Task.detached { [weak self] in
            guard let self else { return }
            let fileHandle = try! FileHandle(forReadingFrom: outputPipeURL)
            defer { fileHandle.closeFile() }

            while !Task.isCancelled {
                if let message = fileHandle.availableData.utf8String, !message.isEmpty {
                    await serverMessagesContinuation?.yield(message)
                }
            }
        }
    }
}

extension Data {
    var utf8String: String? {
        String(data: self, encoding: .utf8)
    }
}
