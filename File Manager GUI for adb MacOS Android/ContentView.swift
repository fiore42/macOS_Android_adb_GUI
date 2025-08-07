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

struct WindowAccessor: NSViewRepresentable {
    var onWindowAvailable: (NSWindow) -> Void

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            if let window = view.window {
                self.onWindowAvailable(window)
            }
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
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

    @ObservedObject private var global = GlobalState.shared

//    @State private var errorMessage: String? = nil
//    @State private var outputMessage: String? = nil
//    @State private var successMessage: String? = nil


    @State private var showLogViewer: Bool = false
    @State private var commitLogContent: String = ""
    @State private var copyEnabled = false
    @State private var macPaneFocused: Bool = true
    @State private var androidPaneFocused: Bool = false
    
    var activePaneHasSelection: Bool {
        (macPaneFocused && !selectedMacFiles.isEmpty) ||
        (androidPaneFocused && !selectedAndroidFiles.isEmpty)
    }

    var copyButtonText: String {
        macPaneFocused
            ? LanguageManager.shared.localized("copy_to_android_button")
            : LanguageManager.shared.localized("copy_to_mac_button")
    }

    var copyButtonDirection: CopyDirection {
        macPaneFocused ? .macToAdr : .adrToMac
    }


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
                                selectionEnabled: copyEnabled,
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
                                        selectionEnabled: copyEnabled,
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
                
                // Right Pane - Android Files
                VStack(alignment: .leading) {
                    Text(LanguageManager.shared.localized("android_files_label"))
                        .frame(maxWidth: .infinity)
                        .multilineTextAlignment(.center)

                        VStack(spacing: 0) {
                            ForEach($androidFiles.filter { $0.wrappedValue.isSpecialAction || $0.wrappedValue.name == ".." }) { $file in
                                FileRowView(
                                    file: $file,
                                    isFocused: androidPaneFocused,
                                    selectedIDs: $selectedAndroidFiles,
                                    selectionEnabled: copyEnabled,
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
                                            selectionEnabled: copyEnabled,
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
                .padding(.leading, 5)
                .frame(minWidth: 0, maxWidth: .infinity)
            }
            .frame(maxHeight: .infinity)
            
            // Action Buttons
            HStack {
                Button(LanguageManager.shared.localized("load_android_files_button")) {
                    checkadbDevices()
                    if copyEnabled {
                        loadAndroidFiles()
                    }
                }
                
                Button(copyButtonText) {
                    copyFiles(direction: copyButtonDirection)
                }
                .disabled(!activePaneHasSelection)

                
            }
            .padding(.bottom, 5)
            
            if let output = global.outputMessage {
                Text(output)
                    .foregroundColor(.white)
                    .padding()
            } else if let success = global.successMessage {
                Text(success)
                    .foregroundColor(.green)
                    .padding()
            } else if let error = global.errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .padding()
            }

        }
        .onAppear(perform: loadMacFiles)
        .background(
            WindowAccessor { window in
                window.title = "My Custom Title"
            }
        )
    }

    struct FileRowView: View {
        @Binding var file: FileEntry
        var isFocused: Bool
        var selectedIDs: Binding<Set<FileEntry.ID>>
        var selectionEnabled: Bool
        var onFocusChange: () -> Void
        var onSpecialAction: () -> Void
        var onNavigate: () -> Void

        var body: some View {
            HStack {
                if !file.isSpecialAction && file.name != ".." {
                    Image(systemName: file.isSelected ? "checkmark.square" : "square")
                        .onTapGesture {
                            guard selectionEnabled else { return }
                            file.isSelected.toggle()
                            if file.isSelected {
                                selectedIDs.wrappedValue.insert(file.id)
                                print("Count [\(selectedIDs.wrappedValue.count)]. Added file to selection: \(file.id)")

                            } else {
                                selectedIDs.wrappedValue.remove(file.id)
                                print("Count [\(selectedIDs.wrappedValue.count)]. Removed file to selection: \(file.id)")
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
                if selectionEnabled {
                    file.isSelected.toggle()
                    if file.isSelected {
                        selectedIDs.wrappedValue.insert(file.id)
                        print("Count [\(selectedIDs.wrappedValue.count)]. Added file to selection: \(file.id)")
                    } else {
                        selectedIDs.wrappedValue.remove(file.id)
                        print("Count [\(selectedIDs.wrappedValue.count)]. Removed file to selection: \(file.id)")
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
        macFiles = []  // Clear list of files
        selectedMacFiles.removeAll() // Clear list of selected files

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
                entries.insert(FileEntry(name: LanguageManager.shared.localized("refresh"), isFolder: false, isSpecialAction: true), at: 0)

                macFiles = entries
            } catch {
                
                GlobalState.shared.errorMessage = "\(LanguageManager.shared.localized("failed_load_mac_files")) \(currentMacPath): \(error.localizedDescription)"
                if errorVerbosity >= .verbose {
                    print("Failed to load \(currentMacPath): \(error.localizedDescription)")
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + messageDuration) {
                    GlobalState.shared.errorMessage = nil
                }

                currentMacPath = ConfigManager.shared.macStartPath
                loadMacFiles()  // Retry with default start path
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

    func resolveAndroidPath(initialPath: String) throws -> String {
        var currentPath = initialPath
        
        var output: String = ""


        while true {
            let safePath = shellSafe(currentPath)
            let fullCommand = "readlink -f \(safePath)"
            
            do {
                output = try runadbCommand(arguments: ["shell", fullCommand])
                    .trimmingCharacters(in: .whitespacesAndNewlines)
            } catch {
                GlobalState.shared.errorMessage = error.localizedDescription
                DispatchQueue.main.asyncAfter(deadline: .now() + messageDuration) {
                    GlobalState.shared.errorMessage = nil
                }
            }

            

            // If the path is already resolved or resolving failed, return it
            if output.isEmpty || output == currentPath {
                return currentPath
            } else {
                // Otherwise, try resolving further in the next loop
                currentPath = output
            }
        }
    }

    
    func loadAndroidFiles() {
        androidFiles = [] // Clear list of files
        selectedAndroidFiles.removeAll() // Clear list of selected files

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            do {
                let resolvedPath = try resolveAndroidPath(initialPath: currentAndroidPath)
                
                if currentAndroidPath == Self.androidRoot {
                    androidRootAliases.append(resolvedPath)
                    if errorVerbosity >= .verbose {
                        print("Added alias androidRootAlias: \(resolvedPath)")
                    }
                }
                currentAndroidPath = resolvedPath  // Always keep currentAndroidPath updated
                
                if errorVerbosity >= .verbose {
                    print("Resolved Android Path: \(resolvedPath)")
                }

                let safeResolvedPath = shellSafe(resolvedPath)
                let lsOutput = try runadbCommand(arguments: ["shell", "ls -la \(safeResolvedPath)"])

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

                // Only add ".." if not at the root alias or browsing above root is allowed
                if resolvedPath != "/" &&
                   (ConfigManager.shared.androidBrowseAboveSDCard || !androidRootAliases.contains(resolvedPath)) {
                    if errorVerbosity >= .verbose {
                        print("resolvedPath: \(resolvedPath) androidRootAliases: \(androidRootAliases)")
                    }

                    entries.insert(FileEntry(name: "..", isFolder: true), at: 0)
                }

                entries = entries.sortedWithFoldersFirst()
                entries.insert(FileEntry(name: "[ Refresh ]", isFolder: false, isSpecialAction: true), at: 0)

                androidFiles = entries
                //showingAndroidFileList = true
            } catch {
                GlobalState.shared.errorMessage = error.localizedDescription
            }
        }
    }


    func checkadbDevices() {
        do {
            let output = try runadbCommand(arguments: ["devices"])
            let lines = output.components(separatedBy: "\n").filter { !$0.isEmpty }
            let deviceLines = lines.dropFirst() // skip header line
            
            let authorizedDevices = deviceLines.filter { $0.contains("\tdevice") }
            let unauthorizedDevices = deviceLines.filter { $0.contains("\tunauthorized") }

            if authorizedDevices.count == 1 {
                GlobalState.shared.successMessage = LanguageManager.shared.localized("ok_ready_to_load")
                copyEnabled = true
            } else if authorizedDevices.isEmpty && unauthorizedDevices.isEmpty {
                GlobalState.shared.errorMessage = LanguageManager.shared.localized("no_device_found")
                copyEnabled = false
            } else if authorizedDevices.count > 1 {
                GlobalState.shared.errorMessage = LanguageManager.shared.localized("multiple_authorized_devices")
                copyEnabled = false
            } else if unauthorizedDevices.count >= 1 && authorizedDevices.isEmpty {
                GlobalState.shared.errorMessage = LanguageManager.shared.localized("no_authorized_device_found")
                copyEnabled = false
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + messageDuration) {
                GlobalState.shared.errorMessage = nil
                GlobalState.shared.successMessage = nil
            }

        } catch {
            GlobalState.shared.errorMessage = "adb Error: \(error.localizedDescription)"
            copyEnabled = false
            DispatchQueue.main.asyncAfter(deadline: .now() + messageDuration) {
                GlobalState.shared.errorMessage = nil
            }
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
        
        if errorVerbosity >= .debug {
            print("selectedFiles \(selectedFiles)")
        }

        DispatchQueue.global(qos: .userInitiated).async {
            for fileID in selectedFiles {
                if let file = sourceFiles.first(where: { $0.id == fileID }), !file.isSpecialAction, file.name != ".." {
                    let sourcePath = (direction == .macToAdr ? macPath : androidPath) + "/" + file.name
                    let destinationPath = (direction == .macToAdr ? androidPath : macPath) + "/" + file.name

                    DispatchQueue.main.async {
                        GlobalState.shared.outputMessage = "\(LanguageManager.shared.localized("copying")) \(file.name)..."
                    }

                    do {
                        let output = try runadbCommand(arguments: adbCommand(sourcePath, destinationPath))
                        if errorVerbosity >= .verbose {
                            print(output)
                        }
                        DispatchQueue.main.async {
                            GlobalState.shared.outputMessage = "\(LanguageManager.shared.localized("copied")) \(file.name)"
                        }
                    } catch {
                        DispatchQueue.main.async {
                            GlobalState.shared.errorMessage = error.localizedDescription
                            GlobalState.shared.outputMessage = nil
                        }
                    }
                }
            }

            // Refresh the destination side
            DispatchQueue.main.async {
                refresh()
                DispatchQueue.main.asyncAfter(deadline: .now() + messageDuration) {
                    GlobalState.shared.outputMessage = nil
                }
            }
        }
    }

    


}

@main
struct adbFileManagerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

