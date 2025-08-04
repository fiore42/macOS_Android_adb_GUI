//
//  FileItem.swift
//  File Manager GUI for adb MacOS Android
//
//  Created by Alfonso Fiore on 4/8/25.
//


import Foundation

struct FileEntry: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let isFolder: Bool
}

func sortAndOrganizeFiles(fileNames: [String], isFolderCheck: (String) -> Bool) -> [String] {
    var parentEntry: String? = nil
    var folders: [String] = []
    var files: [String] = []

    for fileName in fileNames {
        if fileName == ".." {
            parentEntry = fileName
        } else if isFolderCheck(fileName) {
            folders.append(fileName)
        } else {
            files.append(fileName)
        }
    }

    folders.sort { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
    files.sort { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }

    var result = [String]()
    if let parent = parentEntry {
        result.append(parent)
    }
    result.append(contentsOf: folders)
    result.append(contentsOf: files)

    return result
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
