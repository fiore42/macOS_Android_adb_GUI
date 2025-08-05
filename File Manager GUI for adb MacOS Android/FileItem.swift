//
//  FileItem.swift
//  File Manager GUI for adb MacOS Android
//
//  Created by Alfonso Fiore on 4/8/25.
//


import Foundation

struct FileEntry: Identifiable {
    let id = UUID().uuidString
    let name: String
    let isFolder: Bool
    var isSpecialAction: Bool = false  // For entries like "Refresh"
    var isSelected: Bool = false  
}

extension Array where Element == FileEntry {
    func sortedWithFoldersFirst() -> [FileEntry] {
        var parentDir: [FileEntry] = []
        var folders: [FileEntry] = []
        var files: [FileEntry] = []

        for entry in self {
            if ConfigManager.shared.hideHiddenFiles && entry.name != ".." && entry.name.starts(with: ".") {
                continue  // Skip hidden files/folders except ".."
            }
            if entry.name == ".." {
                parentDir.append(entry)
            } else if entry.isFolder {
                folders.append(entry)
            } else {
                files.append(entry)
            }
        }

        folders.sort { $0.name.localizedCompare($1.name) == .orderedAscending }
        files.sort { $0.name.localizedCompare($1.name) == .orderedAscending }

        return parentDir + folders + files
    }
}
