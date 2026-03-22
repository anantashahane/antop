// The Swift Programming Language
// https://docs.swift.org/swift-book
import Foundation

@main
@available(macOS 12, *)
struct SwiftExecutable {
    static func main() async {
        var stats = Statistics()
        print("Starting antop stream…")
        for await line in StreamPowerBlocks() {
            CaptureMachineName(from: line, into: &stats)
            CaptureEfficiencyCore(from: line, into: &stats)
            CapturePerformanceCore(from: line, into: &stats)
            CaptureGPU(from: line, into: &stats)
            CapturePower(from: line, into: &stats)
            print("---------------------------------------------")
            print(stats.machineName ??  "Unknown")
            print("E-Core Cluster: \(stats.highEffeciencyUtility)% @ \(stats.highEffeciencyFrequency) MHz")
            print("P-Core Cluster: \(stats.highPerformanceUtility)% @ \(stats.highPerformanceFrequency) MHz")
            print("GPU Usage: \(stats.gpuUtility)% @ \(stats.gpuFrequency) MHz")
            print("  CPU Power: \(stats.CPUPower) mW")
            print("+ GPU Power: \(stats.GPUPower) mW")
            print("+ ANE Usage: \(stats.ANEPower) mW")
            print("---------------------------------------------")
            print("Package Power: \(stats.PackagePower) mW")
            print("---------------------------------------------")
        }
    }
}