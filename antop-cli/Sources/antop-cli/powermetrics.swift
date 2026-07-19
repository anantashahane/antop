import Darwin.Mach
import Foundation

// #MARK: -Data Structures
class LimitedArray<T: Comparable & Numeric>: CustomStringConvertible {
    var description: String {
        return "\(self.get())"
    }
    private var max: T? = nil
    private let size: Int
    private var pointer: Int
    private var data: [T]

    init(size: Int) {
        precondition(size > 0, "Size must be > 0")
        self.size = size
        self.pointer = 0
        self.data = [T]()
        self.data.reserveCapacity(size)
    }

    func append(_ element: T) {
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
        self.pointer = (self.pointer + 1) % self.size
    }

    func get() -> [T] {
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
            return (Double(integerData.reduce(0, +)) / Double(integerData.count) * 100).rounded()
                / 100
        }
        return 0
    }

    func getMax() -> T {
        return self.max ?? T.zero
    }

    func getLast() -> T {
        if self.data.count == 0 {
            return T.zero
        }
        return self.data[(self.size + pointer - 1) % self.size]
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
    var gpuFrequency: Int = 0
    var gpuUtility: Double = 0

    // Thermal Pressure.
    var thermalPressure: String = "Nominal"

    // Power
    var CPUPower = LimitedArray<Int>(size: 256)
    var GPUPower = LimitedArray<Int>(size: 256)
    var PackagePower = LimitedArray<Int>(size: 256)
    var ANEPower = LimitedArray<Int>(size: 256)

    //Memory
    var totalMemory: Double = 0
    var usedMemory: Double = 0

    var totalSwapMemory: Double = 0
    var usedSwapMemory: Double = 0
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

    static let gpuFrequency = regex(#"GPU HW active frequency:\s+([0-9]+)"#)
    static let gpuActivity = regex(#"GPU HW active residency:\s+([0-9.]+)"#)

    static let thermalPressure = regex(#"Current pressure level:\s+([a-zA-Z]+)"#)

    private static func regex(_ pattern: String) -> NSRegularExpression {
        try! NSRegularExpression(pattern: pattern)
    }
}

func capture(_ regex: NSRegularExpression, in line: String) -> String? {
    let range = NSRange(line.startIndex..., in: line)

    guard let match = regex.firstMatch(in: line, range: range),
        let r = Range(match.range(at: 1), in: line)
    else {
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
            "cpu_power,gpu_power,thermal",
            "-i",
            "1000",
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

func getTotalMemory(stats: inout Statistics) {
    var memSize: UInt64 = 0
    var len = MemoryLayout<UInt64>.size
    guard sysctlbyname("hw.memsize", &memSize, &len, nil, 0) == 0 else {
        return
    }
    stats.totalMemory = Double(memSize) / pow(1024, 3)
}

func getMemoryUsage(stats: inout Statistics) {
    let gb: Double = pow(1024, 3)
    var vm_stats = vm_statistics64()
    var count = mach_msg_type_number_t(
        MemoryLayout.size(ofValue: vm_stats) / MemoryLayout<integer_t>.size
    )
    let result = withUnsafeMutablePointer(to: &vm_stats) {
        $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
            host_statistics64(
                mach_host_self(),
                HOST_VM_INFO64,
                $0,
                &count
            )
        }
    }

    guard result == KERN_SUCCESS else {
        return
    }

    var pageSize: vm_size_t = 0
    host_page_size(mach_host_self(), &pageSize)
    let pageSizeBytes = Double(pageSize)
    let free =
        Double(vm_stats.free_count + vm_stats.speculative_count) * pageSizeBytes / gb
    let used = stats.totalMemory - free
    stats.usedMemory = used

    var swap = xsw_usage()
    var swapLen = MemoryLayout<xsw_usage>.size

    if sysctlbyname("vm.swapusage", &swap, &swapLen, nil, 0) != 0 {
        return
    }

    stats.usedSwapMemory = Double(swap.xsu_used) / gb
    stats.totalSwapMemory = Double(swap.xsu_total) / gb
}

//#MARK: -UI Code

struct Winsize {
    var ws_row: UInt16 = 0
    var ws_col: UInt16 = 0
    var ws_xpixel: UInt16 = 0
    var ws_ypixel: UInt16 = 0
}

func getTerminalSize() -> (rows: Int, cols: Int, terminalWindowTooSmall: Bool)? {
    let limit = (rows: 28, columns: 144)
    var w = winsize()
    let result = ioctl(STDOUT_FILENO, UInt(TIOCGWINSZ), &w)
    if result == -1 {
        return nil  // Could not get size
    }
    return (
        rows: max(limit.rows, Int(w.ws_row)), cols: max(limit.columns, Int(w.ws_col)),
        terminalWindowTooSmall: (limit.rows > Int(w.ws_row) || limit.columns > Int(w.ws_col))
    )
}

func BuildUI(
    headStack: inout VStack, stats: inout Statistics, buffer: inout ScreenBuffer, ane: Bool
) {
    let efficiencyCluster = BarChart(
        frame: Frame(start: (row: 1, column: 1), end: (row: 10, column: 10)), name: "E-Cores",
        progress: stats.highEffeciencyUtility)
    let performanceCluster = BarChart(
        frame: Frame(start: (row: 1, column: 1), end: (row: 10, column: 10)), name: "P-Cores",
        progress: stats.highPerformanceUtility)
    let gpuStats = BarChart(
        frame: Frame(start: (row: 1, column: 1), end: (row: 10, column: 10)), name: "GPU",
        progress: stats.gpuUtility)

    let memoryStats = BarChart(
        frame: Frame(start: (row: 1, column: 1), end: (row: 10, column: 10)),
        name: "Memory",
        progress: stats.usedMemory / stats.totalMemory)

    let hstack = HStack(
        frame: Frame(start: (row: 1, column: 1), end: (row: 10, column: 10)), name: "Package Power",
        withBorder: true)
    let gpuPowerHistory = PowerChart(
        frame: Frame(start: (row: 1, column: 1), end: (row: 10, column: 10)), name: "GPU",
        history: stats.GPUPower)
    let cpuPowerHistory = PowerChart(
        frame: Frame(start: (row: 1, column: 1), end: (row: 10, column: 10)), name: "CPU",
        history: stats.CPUPower)
    let anePowerHistory = PowerChart(
        frame: Frame(start: (row: 1, column: 1), end: (row: 10, column: 10)), name: "ANE",
        history: stats.ANEPower)

    hstack.addChild(view: cpuPowerHistory)
    hstack.addChild(view: gpuPowerHistory)
    if ane {
        hstack.addChild(view: anePowerHistory)
    }

    headStack.addChild(view: efficiencyCluster)
    headStack.addChild(view: performanceCluster)
    headStack.addChild(view: gpuStats)
    headStack.addChild(view: memoryStats)
    headStack.addChild(view: hstack)
}

func UpdateView(line: String, into stats: inout Statistics, ui: any View) {
    CaptureMachineName(from: line, into: &stats)
    CaptureEfficiencyCore(from: line, into: &stats)
    CapturePerformanceCore(from: line, into: &stats)
    CaptureGPU(from: line, into: &stats)
    CapturePower(from: line, into: &stats)
    CaputreThermalPressure(from: line, into: &stats)
    ui.Update(stats: &stats)
}

@available(macOS 12, *)
func PresentData(ane: Bool = true) async {
    var stats = Statistics()
    var buffer = ScreenBuffer(width: 10, height: 10)
    var headStack = VStack(
        frame: Frame(start: (row: 1, column: 1), end: (row: 10, column: 10)), name: "root")
    getTotalMemory(stats: &stats)
    BuildUI(headStack: &headStack, stats: &stats, buffer: &buffer, ane: ane)
    print(buffer.ClearScreen())
    for await line in StreamPowerBlocks() {
        UpdateView(line: line, into: &stats, ui: headStack)
        getMemoryUsage(stats: &stats)
        if let (row, column, tooSmall) = getTerminalSize() {
            if !tooSmall {
                buffer.update(width: column, height: row)
                headStack.frame = Frame(start: (row: 1, column: 1), end: (row: row, column: column))
                headStack.layout()
                headStack.render(into: &buffer)
                print(buffer.GetScreen(), terminator: "")
            } else {
                print(buffer.ClearScreen())
                print(
                    """
                    ┌──────────────────────────────┐
                    │  ⚠ TERMINAL SIZE ERROR       │
                    │                              │
                    │  Window is too small.        │
                    │  Please resize.              │
                    └──────────────────────────────┘
                    """)
            }
        }
    }
}
