//
//  RandomStringGenerator.swift
//  MyReader
//
//  Created by  Dennya on 16/09/2023.
//

import Foundation

struct RandomStringGenerator {
    
    struct Config {}
    
    static func generate(config: Config = Config()) -> String {
        return UUID().uuidString
    }
}
