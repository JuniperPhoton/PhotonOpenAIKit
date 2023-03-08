//
//  File.swift
//  
//
//  Created by Photon Juniper on 2023/3/10.
//

import Foundation

public enum AIModel: String, Codable {
    case gpt_3_5_turbo = "gpt-3.5-turbo"
    case gpt_3_5_turbo_0301 = "gpt-3.5-turbo-0301"
    case text_davinci_003 = "text-davinci-003"
    case text_davinci_002 = "text-davinci-002"
    case code_davinci_002 = "code-davinci-002"
}
