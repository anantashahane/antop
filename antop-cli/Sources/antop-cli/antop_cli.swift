// The Swift Programming Language
// https://docs.swift.org/swift-book
import Foundation

@main
@available(macOS 12, *)
struct SwiftExecutable {
    static func main() async {
        print("Starting antop stream…")
        
        for await line in streamPowerMetrics() {
            print(line)
        }
    }
}