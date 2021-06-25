//
//  File.swift
//  
//
//  Created by Pablo Gonzalez on 25/6/21.
//

import Foundation
import Reqres

public class PXHttpConfigurator {
    static var configuration: PXConfiguration?
    
    public static func configure(withConfiguration config: PXConfiguration) {
        configuration = config
    }
    
    static var shouldPrintRequestsWhileDebugging: Bool {
        guard let config = configuration else { return false }
        return config.shouldPrintRequestsWhileDebugging
    }
}

public struct PXConfiguration {
    let shouldPrintRequestsWhileDebugging: Bool
    
    public init(shouldPrintRequestsWhileDebugging: Bool) {
        self.shouldPrintRequestsWhileDebugging = shouldPrintRequestsWhileDebugging
    }
}
