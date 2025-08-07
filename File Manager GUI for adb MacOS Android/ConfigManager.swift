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
    
    @Published var adbPath: String = "/opt/homebrew/bin/adb" //adb_path
    @Published var macStartPath: String = FileManager.default.homeDirectoryForCurrentUser.path //mac_start_path
    @Published var defaultLanguage: String = "en" //default_language
    @Published var hideHiddenFiles: Bool = true //hide_hidden_files
    @Published var androidBrowseAboveSDCard: Bool = false //android_browse_above_sdcard

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
                    let langFileURL = configURL.deletingLastPathComponent().appendingPathComponent("languages/\(language).json")
                    if FileManager.default.fileExists(atPath: langFileURL.path) {
                        defaultLanguage = language
                    } else {
                        if errorVerbosity >= .minimal {
                            print("Language file \(langFileURL.lastPathComponent) not found in languages/. Falling back to 'en'.")
                        }
                        defaultLanguage = "en"
                    }
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

                if let androidBrowseAbove = json["android_browse_above_sdcard"] {
                    if let boolValue = androidBrowseAbove as? Bool {
                        androidBrowseAboveSDCard = boolValue
                    } else if let stringValue = androidBrowseAbove as? String {
                        androidBrowseAboveSDCard = (stringValue.lowercased() == "true")
                    } else {
                        androidBrowseAboveSDCard = false  // fallback if type is unexpected
                    }
                }
                
            }
        } catch {
            if errorVerbosity >= .minimal {
                print("Failed to load config.json at \(configURL.path): \(error.localizedDescription)")
            }
        }
    }
}

func executableDirectory() -> URL {
    let path = Bundle.main.executableURL?.deletingLastPathComponent()
    return path ?? URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
}
