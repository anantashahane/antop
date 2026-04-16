// The Swift Programming Language
// https://docs.swift.org/swift-book
import Foundation

@main
@available(macOS 13, *)
struct SwiftExecutable {
    static func main() async {
        let arguements = CommandLine.arguments
        if arguements.contains("--help") {
            print("Welcome to antop; a light weight client for power metrics.\n")
            print("$: sudo antop [Commands]\n")
            print("Commands\t\tUsage")
            print("--help\t\tPresents this guide.\n")
            print("no-ane\t\tDon't show ANE power history.")
        }
        if arguements.contains("no-ane") {
            await PresentData(ane: false)
        } else {
            await PresentData()
        }
    }
}