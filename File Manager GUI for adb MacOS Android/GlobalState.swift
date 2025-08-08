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
    
    func setErrorMessage(_ message: String, verbosityLevel: ErrorVerbosityLevel = .normal) {
        self.errorMessage = message
        if errorVerbosity >= verbosityLevel {
            print("errorMessage: \(message)")
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + messageDuration) {
            self.errorMessage = nil
        }
    }

    func setOutputMessage(_ message: String, verbosityLevel: ErrorVerbosityLevel = .normal) {
        self.outputMessage = message
        if errorVerbosity >= verbosityLevel {
            print("outputMessage: \(message)")
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + messageDuration) {
            self.outputMessage = nil
        }
    }

    func setSuccessMessage(_ message: String, verbosityLevel: ErrorVerbosityLevel = .normal) {
        self.successMessage = message
        if errorVerbosity >= verbosityLevel {
            print("successMessage: \(message)")
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + messageDuration) {
            self.successMessage = nil
        }
    }
    
}

