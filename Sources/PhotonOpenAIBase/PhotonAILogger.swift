//
//  File.swift
//  
//
//  Created by Photon Juniper on 2023/3/10.
//

import Foundation
import OSLog

/// Providers OSLogger to log inside the package.
/// You can set ``debug`` to false if you don't want to log anythings.
public class PhotonAILogger {
    public static var debug = true
    
    static let defaultLogger = Logger(subsystem: "com.juniperphoton.PhotonOpenAIKit", category: "request")
}

/// Run the ``block`` with a default logger if ``PhotonAILogger.debug`` is set to true.
public func runOnDefaultLog(block: (Logger) -> Void) {
    if PhotonAILogger.debug {
        block(PhotonAILogger.defaultLogger)
    }
}
