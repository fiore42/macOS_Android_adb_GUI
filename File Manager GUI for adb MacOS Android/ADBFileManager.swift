//
//  ADBFileManager.swift
//  File Manager GUI for adb MacOS Android
//
//  Created by Alfonso Fiore on 4/8/25.
//

import SwiftUI
import Foundation

//func runadbCommand(arguments: [String]) -> String? {
//    let adbPath = ConfigManager.shared.adbPath
//    let adbURL = URL(fileURLWithPath: adbPath)
//
//    guard FileManager.default.fileExists(atPath: adbPath) else {
//        handleADBError("adb not found at \(adbPath). Please check config.json.")
//        return nil
//    }
//
//    let process = Process()
//    process.executableURL = adbURL
//    process.arguments = arguments
//
//    let pipe = Pipe()
//    process.standardOutput = pipe
//    process.standardError = pipe
//
//    do {
//        if errorVerbosity >= .verbose {
//            print("Running command: \(adbPath) \(arguments.joined(separator: " "))")
//        }
//        try process.run()
//    } catch {
//        handleADBError("Failed to start adb process at \(adbPath): \(error.localizedDescription)")
//        return nil
//    }
//
//    let data = pipe.fileHandleForReading.readDataToEndOfFile()
//    guard let output = String(data: data, encoding: .utf8) else {
//        handleADBError("Failed to read adb output as UTF-8.")
//        return nil
//    }
//
//    if errorVerbosity >= .verbose {
//        print("Command output: \(output)")
//    }
//
//    return output
//}
//
//private func handleADBError(_ message: String) {
//    DispatchQueue.main.async {
//        GlobalState.shared.errorMessage = message
//        DispatchQueue.main.asyncAfter(deadline: .now() + messageDuration) {
//            GlobalState.shared.errorMessage = nil
//        }
//    }
//}


func runadbCommand(arguments: [String]) throws -> String {
    
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
        if errorVerbosity >= .verbose {
            print("Running command: \(adbPath) \(arguments.joined(separator: " "))")
        }
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
    if errorVerbosity >= .verbose {
        print("Command output: \(output)")
    }

    return output
}
