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
    @State private var currentAndroidPath: String = "/sdcard"
    @State private var androidRootAliases: [String] = ["/sdcard"]
    @State private var macFiles: [FileEntry] = []
    @State private var androidFiles: [FileEntry] = []
    @State private var selectedMacFiles = Set<FileEntry.ID>()
    @State private var selectedAndroidFiles = Set<FileEntry.ID>()
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
                            FileRowView(file: file) {
                                if file.isSpecialAction {
                                    loadMacFiles()
                                    selectedMacFiles.remove(file.id)
                                } else if file.name == ".." {
                                    navigateMacFolder(to: file)
                                    selectedMacFiles.remove(file.id)
                                }
                            }
                        }

//                        ForEach(macFiles) { file in
//                            HStack {
//                                Image(systemName: file.isSpecialAction ? "arrow.clockwise" : (file.isFolder ? "folder" : "doc.text"))
//                                Text(file.name)
//                            }
//                            .contentShape(Rectangle()) // Make entire row selectable
//                            .onTapGesture {
//                                if file.isSpecialAction {
//                                    loadMacFiles()
//                                    selectedMacFiles.remove(file.id)  // Deselect Refresh immediately
//                                } else if file.name == ".." {
//                                    navigateMacFolder(to: file.name)
//                                    selectedMacFiles.remove(file.id)  // Deselect ".." immediately
//                                }
//                            }
//                        }
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
                                FileRowView(file: file) {
                                    if file.isSpecialAction {
                                        loadAndroidFiles()
                                        selectedAndroidFiles.remove(file.id)
                                    } else if file.name == ".." {
                                        navigateAndroidFolder(to: file)
                                        selectedAndroidFiles.remove(file.id)
                                    }
                                }
                            }

//                            ForEach(androidFiles) { file in
//                                HStack {
//                                    Image(systemName: file.isSpecialAction ? "arrow.clockwise" : (file.isFolder ? "folder" : "doc.text"))
//                                    Text(file.name)
//                                }
//                                .contentShape(Rectangle()) // Make entire row selectable
//                                .onTapGesture {
//                                    if file.isSpecialAction {
//                                        loadAndroidFiles()
//                                        selectedAndroidFiles.remove(file.id)
//                                    } else if file.name == ".." {
//                                        navigateAndroidFolder(to: file.name)
//                                        selectedAndroidFiles.remove(file.id)
//                                    }
//                                }
//
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

    struct FileRowView: View {
        let file: FileEntry
        let onTap: () -> Void

        var body: some View {
            HStack {
                Image(systemName: file.isSpecialAction ? "arrow.clockwise" : (file.isFolder ? "folder" : "doc.text"))
                Text(file.name)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                onTap()
            }
        }
    }

    
    func navigateMacFolder(to file: FileEntry) {
        // Will implement navigation logic later
    }

    func navigateAndroidFolder(to file: FileEntry) {
        // Will implement navigation logic later
    }

    func isMacFolder(fileName: String) -> Bool {
        if fileName == ".." { return true }  // Always treat ".." as folder
        let fullPath = currentMacPath + "/" + fileName
        var isDir: ObjCBool = false
        FileManager.default.fileExists(atPath: fullPath, isDirectory: &isDir)
        return isDir.boolValue
    }
    
    func loadMacFiles() {
        do {
            var files = try FileManager.default.contentsOfDirectory(atPath: currentMacPath)
            if currentMacPath != "/" {
                files.insert("..", at: 0)
            }
            var entries = files.map { fileName in
                FileEntry(name: fileName, isFolder: isMacFolder(fileName: fileName))
            }

            entries = entries.sortedWithFoldersFirst()

            entries.insert(FileEntry(name: "[ Refresh ]", isFolder: false, isSpecialAction: true), at: 0)

            macFiles = entries

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
                if !androidRootAliases.contains(resolvedPath) {
                    androidRootAliases.append(resolvedPath)
                }
                print("Resolved Android Path: \(resolvedPath)")

                let lsOutput = try runADBCommand(arguments: ["shell", "ls", "-la", resolvedPath])
                var entries: [FileEntry] = []

                let lines = lsOutput.components(separatedBy: "\n").filter { !$0.isEmpty }

                for line in lines {
                    if line.starts(with: "total") { continue }  // Skip summary line
                    let tokens = line.split(separator: " ", omittingEmptySubsequences: true)
                    guard let fileName = tokens.last else { continue }
                    let isDir = tokens[0].starts(with: "d")
                    entries.append(FileEntry(name: String(fileName), isFolder: isDir))
                }

                let isAtRootAlias = androidRootAliases.contains(resolvedPath)
                if !isAtRootAlias {
                    entries.insert(FileEntry(name: "..", isFolder: true), at: 0)
                }

                entries = entries.sortedWithFoldersFirst()

                entries.insert(FileEntry(name: "[ Refresh ]", isFolder: false, isSpecialAction: true), at: 0)

                androidFiles = entries
                
                showingAndroidFileList = true
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

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

        for fileID in selectedMacFiles {
            if let file = macFiles.first(where: { $0.id == fileID }), !file.isSpecialAction, file.name != ".." {
                let sourcePath = macPath + "/" + file.name
                let destinationPath = "/sdcard/" + file.name
                do {
                    let output = try runADBCommand(arguments: ["push", sourcePath, destinationPath])
                    print(output)
                } catch {
                    errorMessage = error.localizedDescription
                }
            }
        }
    }



    func copyToMac() {
        let macPath = ConfigManager.shared.macStartPath

        for fileID in selectedAndroidFiles {
            if let file = androidFiles.first(where: { $0.id == fileID }), !file.isSpecialAction, file.name != ".." {
                let sourcePath = "/sdcard/" + file.name
                let destinationPath = macPath + "/" + file.name
                do {
                    let output = try runADBCommand(arguments: ["pull", sourcePath, destinationPath])
                    print(output)
                } catch {
                    errorMessage = error.localizedDescription
                }
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

