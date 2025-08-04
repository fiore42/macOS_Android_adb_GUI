//
//  ContentView.swift
//  File Manager GUI for adb MacOS Android
//
//  Created by Alfonso Fiore on 4/8/25.
//

import SwiftUI
import Foundation

struct ContentView: View {
    @State private var currentMacPath = ConfigManager.shared.macStartPath
//    @State private var macFiles: [String] = []
    @State private var macFiles: [FileEntry] = []
//    @State private var androidFiles: [String] = []
    @State private var androidFiles: [FileEntry] = []
    @State private var selectedMacFiles = Set<String>()
    @State private var selectedAndroidFiles = Set<String>()
    @State private var errorMessage: String?
    @State private var showLogViewer: Bool = false
    @State private var commitLogContent: String = ""
    @State private var showingADBDevicesOutput = false
    @State private var adbDevicesOutput: String = ""
    @State private var buttonsEnabled = false
    @State private var showingAndroidFileList = false


    var body: some View {
        VStack {
            HStack(spacing: 0) {
                // Left Pane - Mac Files
                VStack(alignment: .leading) {
                    Text(LanguageManager.shared.localized("mac_files_label"))
                        .frame(maxWidth: .infinity)
                        .multilineTextAlignment(.center)
                    List(selection: $selectedMacFiles) {
                        ForEach(macFiles) { file in
                            HStack {
                                Image(systemName: file.isFolder ? "folder" : "doc.text")
                                Text(file.name)
                            }
                        }
                    }
                    .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                    .clipped()
                }
                .frame(minWidth: 0, maxWidth: .infinity)
                
                // Right Pane - Android Files or ADB Devices Output
                VStack(alignment: .leading) {
                    Text(LanguageManager.shared.localized("android_files_label"))
                        .frame(maxWidth: .infinity)
                        .multilineTextAlignment(.center)
                    if showingADBDevicesOutput && !showingAndroidFileList {
                        ScrollView([.vertical, .horizontal]) {
                            Text(adbDevicesOutput)
                                .padding()
                                .foregroundColor(adbDevicesOutput == LanguageManager.shared.localized("ok_ready_to_copy") ? .green : .red)
                        }
                        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                        .clipped()
                    } else {
                        List(selection: $selectedAndroidFiles) {
                            ForEach(androidFiles) { file in
                                HStack {
                                    Image(systemName: file.isFolder ? "folder" : "doc.text")
                                    Text(file.name)
                                }
                            }

//                            ForEach(androidFiles, id: \.self) { file in
//                                HStack {
//                                    Image(systemName: isAndroidFolder(fileName: file) ? "folder" : "doc.text")
//                                    Text(file)
//                                }
//                            }

                        }
                        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                        .clipped()
                    }
                }
                .frame(minWidth: 0, maxWidth: .infinity)
            }
            .frame(maxHeight: .infinity)
            
            // Action Buttons
            HStack {
                Button(LanguageManager.shared.localized("adb_devices_button")) {
                    checkADBDevices()
                }
                Button(LanguageManager.shared.localized("load_android_files_button")) {
                    loadAndroidFiles()
                }
                .disabled(!buttonsEnabled)
                
                Button(LanguageManager.shared.localized("copy_to_android_button")) {
                    copyToAndroid()
                }
                .disabled(!buttonsEnabled)
                
                Button(LanguageManager.shared.localized("copy_to_mac_button")) {
                    copyToMac()
                }
                .disabled(!buttonsEnabled)
                
            }
            
            // Error Message
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding()
            }
        }
        .onAppear(perform: loadMacFiles)
    }



    func isMacFolder(fileName: String) -> Bool {
        if fileName == ".." { return true }  // Always treat ".." as folder
        let fullPath = currentMacPath + "/" + fileName
        var isDir: ObjCBool = false
        FileManager.default.fileExists(atPath: fullPath, isDirectory: &isDir)
        return isDir.boolValue
    }
//    
//    func isAndroidFolder(fileName: String) -> Bool {
//        // Naive check for now: if name doesn't contain '.' it's probably a folder (adjust later)
//        if fileName == ".." { return true }
//        return !fileName.contains(".")
//    }
    
    func loadMacFiles() {
        do {
            var files = try FileManager.default.contentsOfDirectory(atPath: currentMacPath)
            if currentMacPath != "/" {
                files.insert("..", at: 0)
            }
            let entries = files.map { fileName in
                FileEntry(name: fileName, isFolder: isMacFolder(fileName: fileName))
            }
            macFiles = entries.sortedWithFoldersFirst()
        } catch {
            errorMessage = "Failed to load Mac files from \(currentMacPath): \(error.localizedDescription)"
        }
    }
    
    func resolveAndroidPath(initialPath: String) throws -> String {
        var currentPath = initialPath
        while true {
            let output = try runADBCommand(arguments: ["shell", "readlink", "-f", currentPath]).trimmingCharacters(in: .whitespacesAndNewlines)
            if output.isEmpty || output == currentPath {
                return currentPath
            } else {
                currentPath = output
            }
        }
    }


    func loadAndroidFiles() {
        androidFiles = []
        showingAndroidFileList = false

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            do {
                let resolvedPath = try resolveAndroidPath(initialPath: "/sdcard")
                print("Resolved Android Path: \(resolvedPath)")

                let lsOutput = try runADBCommand(arguments: ["shell", "ls", "-la", resolvedPath])
                var entries: [FileEntry] = []

                let lines = lsOutput.components(separatedBy: "\n").filter { !$0.isEmpty }

                for line in lines {
                    let tokens = line.split(separator: " ", omittingEmptySubsequences: true)
                    guard tokens.count >= 9 else { continue }
                    let fileName = tokens[8]
                    let isDir = tokens[0].starts(with: "d")
                    entries.append(FileEntry(name: String(fileName), isFolder: isDir))
                }

                if resolvedPath != "/sdcard" {
                    entries.insert(FileEntry(name: "..", isFolder: true), at: 0)
                }

                androidFiles = entries.sortedWithFoldersFirst()
                showingAndroidFileList = true
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    
//    func loadAndroidFiles() {
//        androidFiles = []
//        showingAndroidFileList = false
//
//        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
//            do {
//                let currentPath = "/sdcard"  // <-- Later, you can make this dynamic when navigating
//                let output = try runADBCommand(arguments: ["ls", currentPath])
//                var files = output.components(separatedBy: "\n")
//                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
//                    .filter { !$0.isEmpty }
//                    .map { line in
//                        let parts = line.split(separator: " ", maxSplits: 3, omittingEmptySubsequences: true)
//                        return parts.count == 4 ? String(parts[3]) : line
//                    }
//
//                if currentPath != "/sdcard" {
//                    files.insert("..", at: 0)
//                }
//
//                androidFiles = sortAndOrganizeFiles(fileNames: files) { fileName in
//                    return isAndroidFolder(fileName: fileName)
//                }
//                showingAndroidFileList = true
//            } catch {
//                errorMessage = error.localizedDescription
//            }
//        }
//    }

    func checkADBDevices() {
        do {
            let output = try runADBCommand(arguments: ["devices"])
            let lines = output.components(separatedBy: "\n").filter { !$0.isEmpty }
            let deviceLines = lines.dropFirst() // skip header line
            
            let authorizedDevices = deviceLines.filter { $0.contains("\tdevice") }
            let unauthorizedDevices = deviceLines.filter { $0.contains("\tunauthorized") }

            if authorizedDevices.isEmpty && unauthorizedDevices.isEmpty {
                adbDevicesOutput = LanguageManager.shared.localized("no_device_found")
                buttonsEnabled = false
                showingAndroidFileList = false
            } else if authorizedDevices.count > 1 {
                adbDevicesOutput = LanguageManager.shared.localized("multiple_authorized_devices")
                buttonsEnabled = false
                showingAndroidFileList = false
            } else if authorizedDevices.count == 1 {
                adbDevicesOutput = LanguageManager.shared.localized("ok_ready_to_copy")
                buttonsEnabled = true
                showingAndroidFileList = false
            } else if unauthorizedDevices.count >= 1 && authorizedDevices.isEmpty {
                adbDevicesOutput = LanguageManager.shared.localized("no_authorized_device_found")
                buttonsEnabled = false
                showingAndroidFileList = false
            }
            showingADBDevicesOutput = true
        } catch {
            adbDevicesOutput = "ADB Error: \(error.localizedDescription)"
            showingADBDevicesOutput = true
            buttonsEnabled = false
            showingAndroidFileList = false
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
