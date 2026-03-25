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
        }
            print("---------------------------------------------")
            print(stats.machineName ??  "Unknown")
            print("E-Core Cluster: \(stats.highEffeciencyUtility)% @ \(stats.highEffeciencyFrequency) MHz")
            print("P-Core Cluster: \(stats.highPerformanceUtility)% @ \(stats.highPerformanceFrequency) MHz")
            print("GPU Usage: \(stats.gpuUtility)% @ \(stats.gpuFrequency) MHz")
            print("  CPU Power: \(stats.CPUPower.get().last ?? 0) mW; average \(stats.CPUPower.getAverage()) mW")
            print("+ GPU Power: \(stats.GPUPower.get().last ?? 0) mW; average \(stats.GPUPower.getAverage()) mW")
            print("+ ANE Usage: \(stats.ANEPower.get().last ?? 0) mW; average \(stats.ANEPower.getAverage()) mW")
            print("---------------------------------------------")
            print("Package Power: \(stats.PackagePower) mW; average \(stats.PackagePower.getAverage()) mW; peak \(stats.PackagePower.getMax()); took \(eta).")
            print("---------------------------------------------")
        }
    }
}