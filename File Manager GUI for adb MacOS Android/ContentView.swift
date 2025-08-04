//
//  ContentView.swift
//  File Manager GUI for adb MacOS Android
//
//  Created by Alfonso Fiore on 4/8/25.
//

import SwiftUI
import Foundation

struct ContentView: View {
    @State private var macFiles: [String] = []
    @State private var androidFiles: [String] = []
    @State private var selectedMacFiles = Set<String>()
    @State private var selectedAndroidFiles = Set<String>()
    @State private var errorMessage: String?
    @State private var showLogViewer: Bool = false
    @State private var commitLogContent: String = ""

    var body: some View {
        VStack {
            HStack {
                VStack {
                    Text("Mac Files")
                    List(selection: $selectedMacFiles) {
                        ForEach(macFiles, id: \.self) { file in
                            Text(file)
                        }
                    }
                }

                VStack {
                    Text("Android Files")
                    List(selection: $selectedAndroidFiles) {
                        ForEach(androidFiles, id: \.self) { file in
                            Text(file)
                        }
                    }
                }
            }
            .frame(maxHeight: .infinity)

            HStack {
                Button("Load Android Files") {
                    loadAndroidFiles()
                }
                Button("Copy to Android") {
                    copyToAndroid()
                }
                Button("Copy to Mac") {
                    copyToMac()
                }
            }

            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding()
            }
        }
        .onAppear(perform: loadMacFiles)
        .sheet(isPresented: $showLogViewer) {
            VStack(alignment: .leading) {
                Text("Build Auto-Commit Log")
                    .font(.headline)
                    .padding()
                ScrollView {
                    Text(commitLogContent)
                        .padding()
                        .font(.system(size: 12, design: .monospaced))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .frame(minWidth: 600, minHeight: 400)
        }
    }

    func loadMacFiles() {
        let path = ConfigManager.shared.macStartPath
        do {
            macFiles = try FileManager.default.contentsOfDirectory(atPath: path)
        } catch {
            errorMessage = "Failed to load Mac files from \(path): \(error.localizedDescription)"
        }
    }

    func loadAndroidFiles() {
        do {
            let output = try runADBCommand(arguments: ["shell", "ls", "/sdcard"])
            androidFiles = output.components(separatedBy: "\n").filter { !$0.isEmpty }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func copyToAndroid() {
        let macPath = ConfigManager.shared.macStartPath
        for file in selectedMacFiles {
            let sourcePath = macPath + "/" + file
            let destinationPath = "/sdcard/" + file
            do {
                let output = try runADBCommand(arguments: ["push", sourcePath, destinationPath])
                print(output)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func copyToMac() {
        let macPath = ConfigManager.shared.macStartPath
        for file in selectedAndroidFiles {
            let sourcePath = "/sdcard/" + file
            let destinationPath = macPath + "/" + file
            do {
                let output = try runADBCommand(arguments: ["pull", sourcePath, destinationPath])
                print(output)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

}

@main
struct ADBFileManagerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

// Sample config.json file content:
// {
//     "adb_path": "/opt/homebrew/bin/adb",
//     "mac_start_path": "/Users/username/Downloads"
// }
