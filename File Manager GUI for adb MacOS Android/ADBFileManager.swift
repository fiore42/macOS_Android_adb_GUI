//
//  ADBFileManager.swift
//  File Manager GUI for adb MacOS Android
//
//  Created by Alfonso Fiore on 4/8/25.
//

import SwiftUI
import Foundation

// ConfigManager remains the same
class ConfigManager: ObservableObject {
    static let shared = ConfigManager()
    
    @Published var adbPath: String = "/usr/local/bin/adb"
    @Published var macStartPath: String = FileManager.default.homeDirectoryForCurrentUser.path

    init() {
        loadConfig()
    }

    func loadConfig() {
        let configURL = URL(fileURLWithPath: "config.json")
        do {
            let data = try Data(contentsOf: configURL)
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                if let path = json["adb_path"] as? String {
                    adbPath = path
                }
                if let startPath = json["mac_start_path"] as? String {
                    macStartPath = startPath
                }
            }
        } catch {
            print("Failed to load config.json: \(error.localizedDescription)")
        }
    }
}

// ADB Runner remains the same
func runADBCommand(arguments: [String]) throws -> String {
    let adbPath = ConfigManager.shared.adbPath
    let adbURL = URL(fileURLWithPath: adbPath)

    guard FileManager.default.fileExists(atPath: adbPath) else {
        throw NSError(domain: "ADBError", code: 1, userInfo: [
            NSLocalizedDescriptionKey: "adb not found at \(adbPath). Please check config.json."
        ])
    }

    let process = Process()
    process.executableURL = adbURL
    process.arguments = arguments

    let pipe = Pipe()
    process.standardOutput = pipe
    process.standardError = pipe

    do {
        try process.run()
    } catch {
        throw NSError(domain: "ADBError", code: 2, userInfo: [
            NSLocalizedDescriptionKey: "Failed to start adb process at \(adbPath): \(error.localizedDescription)"
        ])
    }

    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    guard let output = String(data: data, encoding: .utf8) else {
        throw NSError(domain: "ADBError", code: 3, userInfo: [
            NSLocalizedDescriptionKey: "Failed to read adb output as UTF-8."
        ])
    }
    return output
}
