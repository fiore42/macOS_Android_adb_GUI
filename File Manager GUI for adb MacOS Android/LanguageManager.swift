//
//  LanguageManager.swift
//  File Manager GUI for adb MacOS Android
//
//  Created by Alfonso Fiore on 4/8/25.
//

import Foundation
import SwiftUI

class LanguageManager: ObservableObject {
    static let shared = LanguageManager()

    @Published var translations: [String: String] = [:]

    init() {
        loadLanguage(code: ConfigManager.shared.defaultLanguage)
    }

    func loadLanguage(code: String) {
        let languageFile = executableDirectory().appendingPathComponent("languages/\(code).json")

        guard FileManager.default.fileExists(atPath: languageFile.path) else {
            fatalError("Language file \(languageFile.path) not found. Please ensure it exists.")
        }

        do {
            let data = try Data(contentsOf: languageFile)
            if let dict = try JSONSerialization.jsonObject(with: data) as? [String: String] {
                translations = dict
                print("Loaded language: \(code)")
            } else {
                fatalError("Invalid language JSON structure in \(code).json.")
            }
        } catch {
            fatalError("Failed to load language file \(code): \(error.localizedDescription)")
        }
    }


    func localized(_ key: String) -> String {
        translations[key] ?? key
    }
}

// A custom view wrapper for localized strings
struct LocalizedText: View {
    @ObservedObject var lang = LanguageManager.shared
    var key: String

    var body: some View {
        Text(lang.localized(key))
    }
}
