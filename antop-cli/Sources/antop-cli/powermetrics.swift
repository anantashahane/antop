import Foundation

// #MARK: -Data Structures
class LimitedArray<T: Comparable & Numeric> : CustomStringConvertible {
    var description: String {
        return "\(self.get())"
    }
    private var max : T? = nil
    private let size : Int
    private var pointer : Int
    private var data : Array<T>

    init(size: Int) {
        precondition(size > 0, "Size must be > 0")
        self.size = size
        self.pointer = 0
        self.data = Array<T>()
        self.data.reserveCapacity(size)
    }

    func append(_ element : T) {
        if let max = self.max {
            if max < element {
                self.max = element
            }
        } else {
            self.max = element
        }
        if self.data.count < self.size {
            self.data.append(element)
        } else {
            self.data[pointer] = element
        }
        self.pointer  = (self.pointer + 1) % self.size
    }

    func get() -> Array<T> {
        if self.data.count < self.size {
            return self.data
        }
        return Array(self.data[self.pointer...] + self.data[0..<self.pointer])
    }

    func getAverage() -> Double where T: Numeric {
        guard !self.data.isEmpty else { return 0 }
        if let floatingData = data as? [Double] {
            return floatingData.reduce(0, +) / Double(floatingData.count)
        } else if let integerData = data as? [Int] {
            return Double(integerData.reduce(0, +)) / Double(integerData.count)
        }
        return 0
    }

    func getMax() -> T {
        return self.max ?? T.zero
    }
}

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

    var thermalPressure: String = "Nominal"

    // Power
    var CPUPower = LimitedArray<Int>(size: 30)
    var GPUPower = LimitedArray<Int>(size: 30)
    var PackagePower = LimitedArray<Int>(size: 30)
    var ANEPower = LimitedArray<Int>(size: 30)
}

// #MARK: Regex captures from powermetrics
enum CaptureRegex {
    static let machineModel = regex(#"^Machine model: (.*)"#)

    static let cpuPower = regex(#"CPU Power:\s+([0-9]+)"#)
    static let gpuPower = regex(#"GPU Power:\s+([0-9]+)"#)
    static let anePower = regex(#"ANE Power:\s+([0-9]+)"#)
    static let packagePower = regex(#"Combined Power \(CPU \+ GPU \+ ANE\):\s([0-9]+)"#)

    static let efficiencyCoreFrequency = regex(#"E-Cluster HW active frequency: ([0-9]+)"#)
    static let efficiencyCoreActivity = regex(#"E-Cluster HW active residency:\s+([0-9.]+)"#)
    static let performanceCoreFrequency = regex(#"P-Cluster HW active frequency: ([0-9]+)"#)
    static let performanceCoreActivity = regex(#"P-Cluster HW active residency:\s+([0-9.]+)"#)
    
    static let gpuFrequency = regex(#"GPU HW active frequency:\s+([0-9])"#)
    static let gpuActivity = regex(#"GPU HW active residency:\s+([0-9])"#)
    
    static let thermalPressure = regex(#"Current pressure level:\s+([a-zA-Z]+)"#)


    private static func regex(_ pattern: String) -> NSRegularExpression {
        try! NSRegularExpression(pattern: pattern)
    }
}

func capture(_ regex: NSRegularExpression, in line: String) -> String? {
    let range = NSRange(line.startIndex..., in: line)
    
    guard let match = regex.firstMatch(in: line, range: range),
          let r = Range(match.range(at: 1), in: line) else {
        return nil
    }
    
    return String(line[r])
}

func CaptureMachineName(from line: String, into stats: inout Statistics) {
    if let name = capture(CaptureRegex.machineModel, in: line) {
        stats.machineName = name
    }
}

func CapturePower(from line: String, into stats: inout Statistics) {
    if let CPUPower = capture(CaptureRegex.cpuPower, in: line) {
        stats.CPUPower.append(Int(CPUPower) ?? 0)
    }
    if let GPUPower = capture(CaptureRegex.gpuPower, in: line) {
        stats.GPUPower.append(Int(GPUPower) ?? 0)
    }
    if let ANEPower = capture(CaptureRegex.anePower, in: line) {
        stats.ANEPower.append(Int(ANEPower) ?? 0)
    }
    if let PackagePower = capture(CaptureRegex.packagePower, in: line) {
        stats.PackagePower.append(Int(PackagePower) ?? 0)
    }
}

func CaptureEfficiencyCore(from line: String, into stats: inout Statistics) {
    if let freq = capture(CaptureRegex.efficiencyCoreFrequency, in: line) {
        stats.highEffeciencyFrequency = Int(freq) ?? stats.highEffeciencyFrequency
    }

    if let util = capture(CaptureRegex.efficiencyCoreActivity, in: line) {
        stats.highEffeciencyUtility = Double(util) ?? stats.highEffeciencyUtility
    }
}

func CapturePerformanceCore(from line: String, into stats: inout Statistics) {
    if let freq = capture(CaptureRegex.performanceCoreFrequency, in: line) {
        stats.highPerformanceFrequency = Int(freq) ?? stats.highPerformanceFrequency
    }

    if let util = capture(CaptureRegex.performanceCoreActivity, in: line) {
        stats.highPerformanceUtility = Double(util) ?? stats.highPerformanceUtility
    }
}

func CaptureGPU(from line: String, into stats: inout Statistics) {
    if let gpuFrequency = capture(CaptureRegex.gpuFrequency, in: line) {
        stats.gpuFrequency = Int(gpuFrequency) ?? stats.gpuFrequency
    }

    if let gpuUtility = capture(CaptureRegex.gpuActivity, in: line) {
        stats.gpuUtility = Double(gpuUtility) ?? stats.gpuUtility
    }
}

func CaputreThermalPressure(from line: String, into stats: inout Statistics) {
    if let pressure = capture(CaptureRegex.thermalPressure, in: line) {
        stats.thermalPressure = pressure
    }
}

//#MARK: - Real time powermetrics data.
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
                buffer.append(line)
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
        process.arguments = [
            "/usr/bin/powermetrics",
            "--samplers",
            "cpu_power,gpu_power,thermal"
        ]

        let pipe = Pipe()
        process.standardOutput = pipe

        let errPipe = Pipe()
        process.standardError = errPipe

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

//#MARK: -UI Code
struct Winsize {
    var ws_row: UInt16 = 0
    var ws_col: UInt16 = 0
    var ws_xpixel: UInt16 = 0
    var ws_ypixel: UInt16 = 0
}

// Function to get terminal size
func getTerminalSize() -> (rows: Int, cols: Int)? {
    var w = winsize()
    let result = ioctl(STDOUT_FILENO, UInt(TIOCGWINSZ), &w)
    if result == -1 {
        return nil // Could not get size
    }
    return (rows: Int(w.ws_row), cols: Int(w.ws_col))
}

func GetLabel(text: String, prefix: String = "| ", isTab: Bool, width: Int) -> String {
    var return_text = ""
    if isTab {
        return_text = "\(prefix)- \(text)\(String(repeating: "-", count: abs(width - text.count - (2 * prefix.count) - 2)))\(prefix)"
    } else {
        return_text = "\(prefix) \(text)\(String(repeating: " ", count: abs(width - text.count - (2 * prefix.count) - 1)))\(prefix)"
    }
    return return_text
}

func GetBar(ratio: Double, width: Int, prefix: String) -> String {
    let clampedRatio = max(0, min(100, ratio)) // ensure 0..100
    let len = width - (prefix.count * 2)  // inner bar length
    let filledLength = Int(Double(len) * clampedRatio / 100.0)
    let emptyLength = len - filledLength

    // Top bar
    let top = prefix + String(repeating: "█", count: filledLength) + String(repeating: "░", count: emptyLength) + prefix

    // Bottom separator
    let bottom = prefix + String(repeating: "-", count: len) + prefix

    return top + bottom
}

func GetLabelledBar(label: String, percentage: Double, width: Int, prefix: String = "|") -> String {
    var text = ""
    // Header.
    text += GetLabel(text: label, prefix: prefix + prefix, isTab: true, width: width)
    text += "\(GetBar(ratio:percentage, width: width, prefix: prefix + prefix))"
    return text
}

@available(macOS 13, *)
func PresentData() async {
    var stats = Statistics()
    let clock = ContinuousClock()
    for await line in StreamPowerBlocks() {
        let eta = clock.measure {
            CaptureMachineName(from: line, into: &stats)
            CaptureEfficiencyCore(from: line, into: &stats)
            CapturePerformanceCore(from: line, into: &stats)
            CaptureGPU(from: line, into: &stats)
            CapturePower(from: line, into: &stats)
            CaputreThermalPressure(from: line, into: &stats)
        }
        if let (rows, column) = getTerminalSize() {
            print("\u{001B}[2J\u{001B}[H")
            print(GetLabel(text: stats.machineName ?? "Unknown", prefix: "|", isTab: true, width: column))
            print(GetLabel(text: "Thermal pressure: \(stats.thermalPressure)", prefix: "|", isTab: false, width: column))
            print(GetLabelledBar(label: "E-Core Cluster: \(stats.highEffeciencyUtility)% @\(stats.highEffeciencyFrequency) MHz", percentage: stats.highEffeciencyUtility, width: column))
            print(GetLabelledBar(label: "P-Core Cluster: \(stats.highPerformanceUtility)% @\(stats.highPerformanceFrequency) MHz", percentage: stats.highPerformanceUtility, width: column))
            print(GetLabelledBar(label: "GPU Usage: \(stats.gpuUtility)% @\(stats.gpuFrequency) MHz", percentage: stats.gpuUtility, width: column))
            print("  CPU Power: \(stats.CPUPower.get().last ?? 0) mW; average \(stats.CPUPower.getAverage())mW; peak \(stats.CPUPower.getMax()) mW")
            print("+ GPU Power: \(stats.GPUPower.get().last ?? 0) mW; average \(stats.GPUPower.getAverage())mW; peak \(stats.GPUPower.getMax()) mW")
            print("+ ANE Usage: \(stats.ANEPower.get().last ?? 0) mW; average \(stats.ANEPower.getAverage())mW; peak \(stats.ANEPower.getMax()) mW")
            print("---------------------------------------------")
            print("Package Power: \(stats.PackagePower) mW; average \(stats.PackagePower.getAverage()) mW; peak \(stats.PackagePower.getMax()) mW; took \(eta).")
            print("---------------------------------------------")
        }
    }
}