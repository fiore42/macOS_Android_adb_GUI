//
//  FileItem.swift
//  File Manager GUI for adb MacOS Android
//
//  Created by Alfonso Fiore on 4/8/25.
//


import Foundation

//struct FileEntry: Identifiable, Hashable {
//    let id = UUID()
//    let name: String
//    let isFolder: Bool
//}

struct FileEntry: Identifiable, Hashable {
    var id: String { name }  // Ensure name is unique enough
    let name: String
    let isFolder: Bool
}


extension Array where Element == FileEntry {
    func sortedWithFoldersFirst() -> [FileEntry] {
        var parentDir: [FileEntry] = []
        var folders: [FileEntry] = []
        var files: [FileEntry] = []

        for entry in self {
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
