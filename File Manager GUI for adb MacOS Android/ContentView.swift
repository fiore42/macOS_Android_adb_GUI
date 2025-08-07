//
//  ContentView.swift
//  File Manager GUI for adb MacOS Android
//
//  Created by Alfonso Fiore on 4/8/25.
//

import SwiftUI
import Foundation

enum CopyDirection {
    case macToAdr
    case adrToMac
}

struct ContentView: View {
    private static let androidRoot = "/sdcard"
    @State private var currentMacPath = ConfigManager.shared.macStartPath
    @State private var currentAndroidPath: String = androidRoot
    @State private var androidRootAliases: [String] = [androidRoot]
    @State private var macFiles: [FileEntry] = []
    @State private var androidFiles: [FileEntry] = []
    @State private var selectedMacFiles = Set<FileEntry.ID>()
    @State private var selectedAndroidFiles = Set<FileEntry.ID>()

    @State private var errorMessage: String?
    @State private var copyOutput: String? = nil

    @State private var showLogViewer: Bool = false
    @State private var commitLogContent: String = ""
    @State private var showingADBDevicesOutput = false
    @State private var adbDevicesOutput: String = ""
    @State private var buttonsEnabled = false
    @State private var showingAndroidFileList = false
    @State private var macPaneFocused: Bool = true
    @State private var androidPaneFocused: Bool = false

    var body: some View {
        VStack {
            HStack(spacing: 0) {
                // Left Pane - Mac Files
                VStack(alignment: .leading) {
                    Text(LanguageManager.shared.localized("mac_files_label"))
                        .frame(maxWidth: .infinity)
                        .multilineTextAlignment(.center)
                    VStack(spacing: 0) {
                        ForEach($macFiles.filter { $0.wrappedValue.isSpecialAction || $0.wrappedValue.name == ".." }) { $file in
                            FileRowView(
                                file: $file,
                                isFocused: macPaneFocused,
                                selectedIDs: $selectedMacFiles,
                                onFocusChange: { macPaneFocused = true; androidPaneFocused = false },
                                onSpecialAction: { loadMacFiles() },
                                onNavigate: { navigateMacFolder(to: file) }
                            )
                        }
                        ScrollView {
                            LazyVStack(spacing: 0) {
                                ForEach($macFiles.filter { !$0.wrappedValue.isSpecialAction && $0.wrappedValue.name != ".." }) { $file in
                                    FileRowView(
                                        file: $file,
                                        isFocused: macPaneFocused,
                                        selectedIDs: $selectedMacFiles,
                                        onFocusChange: { macPaneFocused = true; androidPaneFocused = false },
                                        onSpecialAction: { loadMacFiles() },
                                        onNavigate: { navigateMacFolder(to: file) }

                                    )
                                }
                            }
                        }
                    }
                    .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                    .clipped()
                }
                .padding(.leading, 5)
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
                        VStack(spacing: 0) {
                            ForEach($androidFiles.filter { $0.wrappedValue.isSpecialAction || $0.wrappedValue.name == ".." }) { $file in
                                FileRowView(
                                    file: $file,
                                    isFocused: androidPaneFocused,
                                    selectedIDs: $selectedAndroidFiles,
                                    onFocusChange: { macPaneFocused = false; androidPaneFocused = true },
                                    onSpecialAction: { loadAndroidFiles() },
                                    onNavigate: { navigateAndroidFolder(to: file) }

                                )
                            }
                            ScrollView {
                                LazyVStack(spacing: 0) {
                                    ForEach($androidFiles.filter { !$0.wrappedValue.isSpecialAction && $0.wrappedValue.name != ".." }) { $file in
                                        FileRowView(
                                            file: $file,
                                            isFocused: androidPaneFocused,
                                            selectedIDs: $selectedAndroidFiles,
                                            onFocusChange: { macPaneFocused = false; androidPaneFocused = true },
                                            onSpecialAction: { loadAndroidFiles() },
                                            onNavigate: { navigateAndroidFolder(to: file) }
                                        )
                                    }
                                }
                            }
                        }

                        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                        .clipped()
                    }
                }
                .padding(.leading, 5)
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
                    copyFiles(direction: .macToAdr)
                }
                .disabled(!buttonsEnabled)

                Button(LanguageManager.shared.localized("copy_to_mac_button")) {
                    copyFiles(direction: .adrToMac)
                }
                .disabled(!buttonsEnabled)

                
//                Button(LanguageManager.shared.localized("copy_to_android_button")) {
//                    copyToAndroid()
//                }
//                .disabled(!buttonsEnabled)
//                
//                Button(LanguageManager.shared.localized("copy_to_mac_button")) {
//                    copyToMac()
//                }
//                .disabled(!buttonsEnabled)
                
            }
            .padding(.bottom, 5)
            if let output = copyOutput { // Command Output
                Text(output)
                    .foregroundColor(.white)
                    .padding()
            } else if let error = errorMessage { // Error Message
                Text(error)
                    .foregroundColor(.red)
                    .padding()
            }

        }
        .onAppear(perform: loadMacFiles)
    }

    struct FileRowView: View {
        @Binding var file: FileEntry
        var isFocused: Bool
        var selectedIDs: Binding<Set<FileEntry.ID>>
        var onFocusChange: () -> Void
        var onSpecialAction: () -> Void
        var onNavigate: () -> Void

        var body: some View {
            HStack {
                if !file.isSpecialAction && file.name != ".." {
                    Image(systemName: file.isSelected ? "checkmark.square" : "square")
                        .onTapGesture {
                            file.isSelected.toggle()
                            if file.isSelected {
                                selectedIDs.wrappedValue.insert(file.id)
                            } else {
                                selectedIDs.wrappedValue.remove(file.id)
                            }
                            onFocusChange()  // Ensure tap on checkbox focuses pane
                        }
                } else {
                    Spacer().frame(width: 23) // Empty space instead of checkbox
                }
                Image(systemName: file.isSpecialAction ? "arrow.clockwise" : (file.isFolder ? "folder" : "doc.text"))
                Text(file.name)
                Spacer()
            }
            .padding(.vertical, 2)
            .background(file.isSelected ? (isFocused ? Color.blue.opacity(0.3) : Color.gray.opacity(0.3)) : Color.clear)
            .contentShape(Rectangle())
            .onTapGesture {
                file.isSelected.toggle()
                if file.isSelected {
                    selectedIDs.wrappedValue.insert(file.id)
                } else {
                    selectedIDs.wrappedValue.remove(file.id)
                }
                onFocusChange()
                
                if file.isSpecialAction {
                    onSpecialAction()
                } else if file.name == ".." || file.isFolder {
                    onNavigate()
                }
            }
        }
    }


    
    func navigateMacFolder(to file: FileEntry) {
        if file.name == ".." {
            // Go up one level
            if currentMacPath != "/" {
                currentMacPath = URL(fileURLWithPath: currentMacPath).deletingLastPathComponent().path
            }
        } else if file.isFolder {
            // Go into the folder
            currentMacPath = currentMacPath + "/" + file.name
        }
        loadMacFiles()
    }


    func navigateAndroidFolder(to file: FileEntry) {
        if file.name == ".." {
            // Go up one level
            if currentAndroidPath != Self.androidRoot {
                currentAndroidPath = URL(fileURLWithPath: currentAndroidPath).deletingLastPathComponent().path
                if currentAndroidPath.isEmpty {
                    currentAndroidPath = Self.androidRoot  // Prevent empty path fallback
                }
            }
        } else if file.isFolder {
            // Navigate into folder
            currentAndroidPath = currentAndroidPath + "/" + file.name
        }
        loadAndroidFiles()
    }

    func isAndroidFolder(fileName: String) -> Bool {
        return true  // For now, we rely on `ls -la` parsing with `isFolder` already set correctly
    }


    func isMacFolder(fileName: String) -> Bool {
        if fileName == ".." { return true }  // Always treat ".." as folder
        let fullPath = currentMacPath + "/" + fileName
        var isDir: ObjCBool = false
        FileManager.default.fileExists(atPath: fullPath, isDirectory: &isDir)
        return isDir.boolValue
    }
    
    func loadMacFiles() {
        macFiles = []  // Clear list immediately
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
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
                print("Failed to load \(currentMacPath): \(error.localizedDescription)")

                DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                    errorMessage = nil
                }

                currentMacPath = ConfigManager.shared.macStartPath
                loadMacFiles()  // Retry with default start path
            }
        }
    }

    
//    func resolveAndroidPath(initialPath: String) throws -> String {
//        var currentPath = initialPath
//        while true {
//            let output = try runADBCommand(arguments: ["shell", "readlink", "-f", currentPath]).trimmingCharacters(in: .whitespacesAndNewlines)
//            if output.isEmpty || output == currentPath {
//                return currentPath
//            } else {
//                currentPath = output
//            }
//        }
//    }
    
    
    func shellSafe(_ path: String) -> String {
        let escaped = path.replacingOccurrences(of: "'", with: "'\\''")
        let quoted = "'\(escaped)'"
        if quoted != path {
            print("shellSafe: escaped input path for shell: \(path) → \(quoted)")
        }
        return quoted
    }

    func resolveAndroidPath(initialPath: String) throws -> String {
        var currentPath = initialPath

        while true {
            let safePath = shellSafe(currentPath)
            let fullCommand = "readlink -f \(safePath)"
            let output = try runADBCommand(arguments: ["shell", fullCommand])
                .trimmingCharacters(in: .whitespacesAndNewlines)

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
                let resolvedPath = try resolveAndroidPath(initialPath: currentAndroidPath)
                
                if currentAndroidPath == Self.androidRoot {
                    androidRootAliases.append(resolvedPath)
                    print("Added alias androidRootAlias: \(resolvedPath)")
                }
                currentAndroidPath = resolvedPath  // Always keep currentAndroidPath updated
                
                print("Resolved Android Path: \(resolvedPath)")

                let safeResolvedPath = shellSafe(resolvedPath)
                let lsOutput = try runADBCommand(arguments: ["shell", "ls -la \(safeResolvedPath)"])

//                let lsOutput = try runADBCommand(arguments: ["shell", "ls", "-la", resolvedPath])
                var entries: [FileEntry] = []

                let lines = lsOutput.components(separatedBy: "\n").filter { !$0.isEmpty }

                for line in lines {
                    if line.starts(with: "total") { continue }  // Skip summary line
                    let tokens = line.split(omittingEmptySubsequences: true, whereSeparator: { $0 == " " || $0 == "\t" })
                    guard tokens.count >= 8 else { continue }  // Ensure at least 9 tokens (standard ls -la format)

                    let fileName = tokens[7...].joined(separator: " ")

                    if fileName == "." || fileName == ".." {
                        continue  // Skip explicit . and .. entries from adb
                    }

                    let isDir = tokens[0].starts(with: "d")
                    entries.append(FileEntry(name: fileName, isFolder: isDir))

                }

                // Only add ".." if not at the root alias
                if !androidRootAliases.contains(resolvedPath) || ConfigManager.shared.androidBrowseAboveSDCard || resolvedPath != "/" {
                    print("resolvedPath: \(resolvedPath) androidRootAliases: \(androidRootAliases)")
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

    func copyFiles(direction: CopyDirection) {
        let macPath = currentMacPath
        let androidPath = currentAndroidPath

        let selectedFiles: Set<FileEntry.ID>
        let sourceFiles: [FileEntry]
        let adbCommand: (String, String) -> [String]
        let refresh: () -> Void

        switch direction {
        case .macToAdr:
            selectedFiles = selectedMacFiles
            sourceFiles = macFiles
            adbCommand = { src, dst in ["push", src, dst] }
            refresh = loadAndroidFiles
        case .adrToMac:
            selectedFiles = selectedAndroidFiles
            sourceFiles = androidFiles
            adbCommand = { src, dst in ["pull", src, dst] }
            refresh = loadMacFiles
        }
        
        print("selectedFiles \(selectedFiles)")

        DispatchQueue.global(qos: .userInitiated).async {
            for fileID in selectedFiles {
                if let file = sourceFiles.first(where: { $0.id == fileID }), !file.isSpecialAction, file.name != ".." {
                    let sourcePath = (direction == .macToAdr ? macPath : androidPath) + "/" + file.name
                    let destinationPath = (direction == .macToAdr ? androidPath : macPath) + "/" + file.name

                    DispatchQueue.main.async {
                        copyOutput = "Copying \(file.name)..."
                    }

                    do {
                        let output = try runADBCommand(arguments: adbCommand(sourcePath, destinationPath))
                        print(output)
                        DispatchQueue.main.async {
                            copyOutput = "Copied \(file.name)"
                        }
                    } catch {
                        DispatchQueue.main.async {
                            errorMessage = error.localizedDescription
                            copyOutput = nil
                        }
                    }
                }
            }

            // Refresh the destination side
            DispatchQueue.main.async {
                refresh()
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    copyOutput = nil
                }
            }
        }
    }

    

//    func copyToAndroid() {
//        let macPath = currentMacPath
//        let androidPath = currentAndroidPath
//
//        print("selectedMacFiles \(selectedMacFiles)")
//
//        DispatchQueue.global(qos: .userInitiated).async {
//            for fileID in selectedMacFiles {
//                if let file = macFiles.first(where: { $0.id == fileID }), !file.isSpecialAction, file.name != ".." {
//                    let sourcePath = macPath + "/" + file.name
//                    let destinationPath = androidPath + "/" + file.name
//
//                    DispatchQueue.main.async {
//                        copyOutput = "Copying \(file.name)..."
//                    }
//
//                    do {
//                        let output = try runADBCommand(arguments: ["push", sourcePath, destinationPath])
//                        print(output)
//                        DispatchQueue.main.async {
//                            copyOutput = "Copied \(file.name)"
//                        }
//                    } catch {
//                        DispatchQueue.main.async {
//                            errorMessage = error.localizedDescription
//                            copyOutput = nil
//                        }
//                    }
//                }
//            }
//
//            // Refresh Android side after copy on main thread
//            DispatchQueue.main.async {
//                loadAndroidFiles()
//                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
//                    copyOutput = nil
//                }
//            }
//        }
//    }
//
//
//
//
//    func copyToMac() {
//        let macPath = currentMacPath
//        let androidPath = currentAndroidPath
//
//        print("selectedAndroidFiles \(selectedAndroidFiles)")
//
//        DispatchQueue.global(qos: .userInitiated).async {
//            for fileID in selectedAndroidFiles {
//                if let file = androidFiles.first(where: { $0.id == fileID }), !file.isSpecialAction, file.name != ".." {
//                    let sourcePath = androidPath + "/" + file.name
//                    let destinationPath = macPath + "/" + file.name
//
//                    DispatchQueue.main.async {
//                        copyOutput = "Copying \(file.name)..."
//                    }
//
//                    do {
//                        let output = try runADBCommand(arguments: ["pull", sourcePath, destinationPath])
//                        print(output)
//                        DispatchQueue.main.async {
//                            copyOutput = "Copied \(file.name)"
//                        }
//                    } catch {
//                        DispatchQueue.main.async {
//                            errorMessage = error.localizedDescription
//                            copyOutput = nil
//                        }
//                    }
//                }
//            }
//
//            // Refresh Mac side after copy on main thread
//            DispatchQueue.main.async {
//                loadMacFiles()
//                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
//                    copyOutput = nil
//                }
//            }
//        }
//    }




}

@main
struct ADBFileManagerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

