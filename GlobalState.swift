//
//  GlobalState.swift
//  File Manager GUI for adb MacOS Android
//
//  Created by Alfonso Fiore on 7/8/25.
//


// GlobalState.swift

import Foundation
import SwiftUI
import Combine

class GlobalState: ObservableObject {
    static let shared = GlobalState()

    @Published var errorMessage: String? = nil
    @Published var outputMessage: String? = nil
    @Published var successMessage: String? = nil

    private init() {} // Singleton pattern
}
