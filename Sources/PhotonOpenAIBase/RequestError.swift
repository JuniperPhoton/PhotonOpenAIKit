//
//  File.swift
//  
//
//  Created by Photon Juniper on 2023/3/17.
//

import Foundation

/// Error that would be thrown during request.
/// You use ``message`` to check the message info.
///
/// If the response contains status code that is not between 200-300,
/// then ``code`` is set.
///
/// To get the general information:
/// ```
/// let errorMessage = String(describing: error)
/// ```
public struct RequestError: Error, CustomStringConvertible {
    public let message: String
    public let code: Int
    
    public init(_ message: String = "", code: Int = -1) {
        self.message = message
        self.code = code
    }
    
    /// Description about ``message`` and ``code``.
    public var description: String {
        return "Error: \(message) code: \(code)"
    }
}
