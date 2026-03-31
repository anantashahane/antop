// The Swift Programming Language
// https://docs.swift.org/swift-book
import Foundation

@main
@available(macOS 13, *)
struct SwiftExecutable {
    static func main() async {
        var stats = Statistics()
        let clock = ContinuousClock()

        print("Starting antop stream…")
        
        for await line in StreamPowerBlocks() {
            let eta = clock.measure {
                CaptureMachineName(from: line, into: &stats)
                CaptureEfficiencyCore(from: line, into: &stats)
                CapturePerformanceCore(from: line, into: &stats)
                CaptureGPU(from: line, into: &stats)
                CapturePower(from: line, into: &stats)
                CaputreThermalPressure(from: line, into: &stats)
            }

            print("\u{001B}[2J\u{001B}[H", terminator: "")
            print("---------------------------------------------")
            print(stats.machineName ??  "Unknown")
            print("Thermal pressure: \(stats.thermalPressure)")
            print("E-Core Cluster: \(stats.highEffeciencyUtility)% @ \(stats.highEffeciencyFrequency) MHz")
            print("P-Core Cluster: \(stats.highPerformanceUtility)% @ \(stats.highPerformanceFrequency) MHz")
            print("GPU Usage: \(stats.gpuUtility)% @ \(stats.gpuFrequency) MHz")
            print("  CPU Power: \(stats.CPUPower.get().last ?? 0) mW; average \(stats.CPUPower.getAverage())mW; peak \(stats.CPUPower.getMax()) mW")
            print("+ GPU Power: \(stats.GPUPower.get().last ?? 0) mW; average \(stats.GPUPower.getAverage())mW; peak \(stats.GPUPower.getMax()) mW")
            print("+ ANE Usage: \(stats.ANEPower.get().last ?? 0) mW; average \(stats.ANEPower.getAverage())mW; peak \(stats.ANEPower.getMax()) mW")
            print("---------------------------------------------")
            print("Package Power: \(stats.PackagePower) mW; average \(stats.PackagePower.getAverage()) mW; peak \(stats.PackagePower.getMax()) mW; took \(eta).")
            print("---------------------------------------------")
        }
    }
}