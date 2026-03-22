import Foundation

struct Statistics {
    var machineName: String?

    // Effeciency Core Data
    var highEffeciencyFrequency: Int = 0
    var highEffeciencyUtility: Double = 0

    // Performance Core Date
    var highPerformanceFrequency: Int = 0
    var highPerformanceUtility: Double = 0

    //GPU Performance
    var gpuFrequency : Int = 0
    var gpuUtility: Double = 0

    // Power
    var CPUPower : Int = 0
    var GPUPower : Int = 0
    var PackagePower: Int = 0
    var ANEPower : Int = 0
}

import Foundation

func capture(_ pattern: String, in line: String) -> String? {
    guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
    let range = NSRange(line.startIndex..., in: line)
    
    guard let match = regex.firstMatch(in: line, range: range),
          let r = Range(match.range(at: 1), in: line) else {
        return nil
    }
    
    return String(line[r])
}

func CaptureMachineName(from line: String, into stats: inout Statistics) {
    if let name = capture(#"^Machine model: (.*)"#, in: line) {
        stats.machineName = name
    }
}

func CapturePower(from line: String, into stats: inout Statistics) {
    if let CPUPower = capture(#"CPU Power:\s+([0-9]+)"#, in: line) {
        stats.CPUPower = Int(CPUPower) ?? stats.CPUPower
    }
    if let GPUPower = capture(#"GPU Power:\s+([0-9]+)"#, in: line) {
        stats.GPUPower = Int(GPUPower) ?? stats.GPUPower
    }
    if let ANEPower = capture(#"ANE Power:\s+([0-9]+)"#, in: line) {
        stats.ANEPower = Int(ANEPower) ?? stats.ANEPower
    }
    if let PackagePower = capture(#"Combined Power \(CPU \+ GPU \+ ANE\):\s([0-9]+)"#, in: line) {
        stats.PackagePower = Int(PackagePower) ?? stats.PackagePower
    }
}

func CaptureEfficiencyCore(from line: String, into stats: inout Statistics) {
    if let freq = capture(#"E-Cluster HW active frequency: ([0-9]+)"#, in: line) {
        stats.highEffeciencyFrequency = Int(freq) ?? stats.highEffeciencyFrequency
    }

    if let util = capture(#"E-Cluster HW active residency:\s+([0-9.]+)"#, in: line) {
        stats.highEffeciencyUtility = Double(util) ?? stats.highEffeciencyUtility
    }
}

func CapturePerformanceCore(from line: String, into stats: inout Statistics) {
    if let freq = capture(#"P-Cluster HW active frequency: ([0-9]+)"#, in: line) {
        stats.highPerformanceFrequency = Int(freq) ?? stats.highPerformanceFrequency
    }

    if let util = capture(#"P-Cluster HW active residency:\s+([0-9.]+)"#, in: line) {
        stats.highPerformanceUtility = Double(util) ?? stats.highPerformanceUtility
    }
}

func CaptureGPU(from line: String, into stats: inout Statistics) {
    if let gpuFrequency = capture(#"GPU HW active frequency:\s+([0-9])"#, in: line) {
        stats.gpuFrequency = Int(gpuFrequency) ?? stats.gpuFrequency
    }

    if let gpuUtility = capture(#"GPU HW active residency:\s+([0-9])"#, in: line) {
        stats.gpuUtility = Double(gpuUtility) ?? stats.gpuUtility
    }
}

@available(macOS 12, *)
func StreamPowerBlocks() -> AsyncStream<String> {
    AsyncStream { continuation in
        Task {
            var buffer: [String] = []

            for await line in streamPowerMetrics() {
                if line.starts(with: "*** Sampled system activity") {
                    if !buffer.isEmpty {
                        let data = buffer.joined(separator: "\n")
                        continuation.yield(data)
                        buffer.removeAll()
                    }
                }
            }

            continuation.finish()
        }
    }
}

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