//
//  FileItem.swift
//  File Manager GUI for adb MacOS Android
//
//  Created by Alfonso Fiore on 4/8/25.
//


import Foundation

struct FileItem: Identifiable {
    let id = UUID()
    let name: String
    let isFolder: Bool
}

func sortAndOrganizeFiles(fileNames: [String], isFolderCheck: (String) -> Bool) -> [String] {
    var folders: [String] = []
    var files: [String] = []

    for fileName in fileNames {
        if isFolderCheck(fileName) {
            folders.append(fileName)
        } else {
            files.append(fileName)
        }
    }

    folders.sort { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
    files.sort { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }

    return folders + files
}

