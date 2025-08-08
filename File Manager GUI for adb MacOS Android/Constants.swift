//
//  Constants.swift
//  File Manager GUI for adb MacOS Android
//
//  Created by Alfonso Fiore on 7/8/25.
//

import Foundation

let messageDuration: TimeInterval = 5.0

enum ErrorVerbosityLevel: Int, Comparable {
    case silent = 0        // No error messages
    case minimal = 1       // Only critical issues
    case normal = 2        // Default user-facing errors
    case verbose = 3       // Detailed debug info
    case debug = 4         // Very verbose logs for development

    static func < (lhs: ErrorVerbosityLevel, rhs: ErrorVerbosityLevel) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}

let errorVerbosity: ErrorVerbosityLevel = .debug
