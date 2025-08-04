//
//  ConfigManager.swift
//  File Manager GUI for adb MacOS Android
//
//  Created by Alfonso Fiore on 4/8/25.
//


import SwiftUI
import Foundation

func executableDirectory() -> URL {
    let path = Bundle.main.executableURL?.deletingLastPathComponent()
    return path ?? URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
}
