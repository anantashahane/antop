import Foundation

@available(macOS 12, *)
func streamPowerMetrics() -> AsyncStream<String> {
    AsyncStream { continuation in
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/powermetrics")

        let pipe = Pipe()
        process.standardOutput = pipe

        do {
            try process.run()
        } catch {
            continuation.finish()
            return
        }

        let handle = pipe.fileHandleForReading

        Task {
            for try await line in handle.bytes.lines {
                continuation.yield(line)
            }

            continuation.finish()
        }

        continuation.onTermination = { _ in
            process.terminate()
        }
    }
}