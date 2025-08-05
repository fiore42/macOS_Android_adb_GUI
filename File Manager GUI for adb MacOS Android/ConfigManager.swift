//
//  ConfigManager.swift
//  File Manager GUI for adb MacOS Android
//
//  Created by Alfonso Fiore on 4/8/25.
//

//import SwiftUI
import Foundation

class ConfigManager: ObservableObject {
    static let shared = ConfigManager()
    
    @Published var adbPath: String = "/opt/homebrew/bin/adb"
    @Published var macStartPath: String = FileManager.default.homeDirectoryForCurrentUser.path
    @Published var defaultLanguage: String = "en"
    @Published var hideHiddenFiles: Bool = true  // New parameter with default fallback


    init() {
        loadConfig()
    }

    func loadConfig() {
        let configURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath).appendingPathComponent("config.json")        
        
        do {
            let data = try Data(contentsOf: configURL)
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                if let path = json["adb_path"] as? String {
                    adbPath = path
                }
                if let startPath = json["mac_start_path"] as? String {
                    if startPath.hasPrefix("~") {
                        let homeDir = FileManager.default.homeDirectoryForCurrentUser.path
                        let relativePath = String(startPath.dropFirst()) // Remove ~
                        macStartPath = homeDir + relativePath
                    } else {
                        macStartPath = startPath
                    }
                }
                if let language = json["default_language"] as? String {
                    defaultLanguage = language
                }
                if let hideHidden = json["hide_hidden_files"] {
                    if let boolValue = hideHidden as? Bool {
                        hideHiddenFiles = boolValue
                    } else if let stringValue = hideHidden as? String {
                        hideHiddenFiles = (stringValue.lowercased() == "true")
                    } else {
                        hideHiddenFiles = false  // fallback if type is unexpected
                    }
                }

            }
        } catch {
            print("Failed to load config.json at \(configURL.path): \(error.localizedDescription)")
        }
    }
}

func executableDirectory() -> URL {
    let path = Bundle.main.executableURL?.deletingLastPathComponent()
    return path ?? URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
}
