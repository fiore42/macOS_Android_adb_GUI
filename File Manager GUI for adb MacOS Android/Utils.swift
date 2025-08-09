//
//  Utils.swift
//  File Manager GUI for adb MacOS Android
//
//  Created by Alfonso Fiore on 9/8/25.
//

import Foundation

enum ByteUnit: String {
    case KB = "KB"
    case MB = "MB"
    case GB = "GB"

    var divisor: Double {
        switch self {
        case .KB: return 1024
        case .MB: return 1024 * 1024
        case .GB: return 1024 * 1024 * 1024
        }
    }
}

struct ProcessResult {
    let exitCode: Int32
    let stdout: String
    let stderr: String
}

@discardableResult
func runProcess(executable: String, arguments: [String]) throws -> ProcessResult {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: executable)
    process.arguments = arguments

    let outPipe = Pipe()
    let errPipe = Pipe()
    process.standardOutput = outPipe
    process.standardError  = errPipe

    try process.run()
    process.waitUntilExit()

    let outData = outPipe.fileHandleForReading.readDataToEndOfFile()
    let errData = errPipe.fileHandleForReading.readDataToEndOfFile()

    let stdout = String(data: outData, encoding: .utf8) ?? ""
    let stderr = String(data: errData, encoding: .utf8) ?? ""

    return ProcessResult(exitCode: process.terminationStatus, stdout: stdout, stderr: stderr)
}


func getFileSize(direction: CopyDirection, path: String) -> Int64 {
    if errorVerbosity >= .debug {
        print("getFileSize direction \(direction)")
    }

    switch direction {
    case .macToAdr:
        do {
            // du -sk <path>  -> size in KB (summary)
            let result = try runProcess(executable: "/usr/bin/env", arguments: ["du", "-sk", path])

            if errorVerbosity >= .debug, !result.stderr.isEmpty {
                print("du stderr: \(result.stderr)")
            }

            // Parse leading KB number
            if let kbString = result.stdout
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .components(separatedBy: .whitespaces)
                .first,
               let kb = Int64(kbString) {

                let bytes = kb * 1024
                if errorVerbosity >= .debug {
                    print("du reported size for \(path): \(bytes) bytes")
                }
                return bytes
            }
        } catch {
            if errorVerbosity >= .minimal {
                print("Error running du for \(path): \(error.localizedDescription)")
            }
        }
        return 0

    case .adrToMac:
        let command = "du -sb \(shellSafe(path)) | cut -f1"
        do {
            let output = try runadbCommand(arguments: ["shell", command])
            return Int64(output.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0
        } catch {
            return 0
        }
    }
}

func shellSafe(_ path: String) -> String {
    let escaped = path.replacingOccurrences(of: "'", with: "'\\''")
    let quoted = "'\(escaped)'"
    if quoted != path {
        if errorVerbosity >= .verbose {
            print("shellSafe: escaped input path for shell: \(path) → \(quoted)")
        }
    }
    return quoted
}

func unitForTotalBytes(_ total: Int64) -> ByteUnit {
    if total < Int64(1 << 20) {         // < 1 MB
        return .KB
    } else if total < Int64(1 << 30) {  // < 1 GB
        return .MB
    } else {
        return .GB
    }
}

/// Formats a byte count using a fixed unit (so copied & total use the same unit).
func formatBytes(_ bytes: Int64, using unit: ByteUnit) -> (Double, String) {
    (Double(bytes) / unit.divisor, unit.rawValue)
}

/// Formats a bytes-per-second rate into KB/s, MB/s, or GB/s.
func formatRate(_ bytesPerSecond: Double) -> (Double, String) {
    let absBps = abs(bytesPerSecond)
    if absBps < Double(1 << 20) {                      // < 1 MB/s
        return (bytesPerSecond / 1024, "KB/sec")
    } else if absBps < Double(1 << 30) {               // < 1 GB/s
        return (bytesPerSecond / (1024 * 1024), "MB/sec")
    } else {
        return (bytesPerSecond / (1024 * 1024 * 1024), "GB/sec")
    }
}

/// Delta-based speed (bytes/sec) between two samples, with optional debug.
func computeSpeed(prevBytes: Int64, prevTime: Date, currentBytes: Int64, currentTime: Date) -> Double {
    let deltaBytes = max(0, currentBytes - prevBytes)
    let deltaTime  = max(0.001, currentTime.timeIntervalSince(prevTime))
    let bps = Double(deltaBytes) / deltaTime
    if errorVerbosity >= .debug {
        print("computeSpeed: Δbytes=\(deltaBytes), Δtime=\(String(format: "%.3f", deltaTime))s, bps=\(String(format: "%.1f", bps))")
    }
    return bps
}
