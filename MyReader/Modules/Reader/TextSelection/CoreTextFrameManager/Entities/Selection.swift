//
//  Selection.swift
//  MyReader
//
//  Created by  Dennya on 10/12/2023.
//

import Foundation

extension CoreTextFrameManager {
    struct Selection {
        let firstWord: Word
        let lastWord: Word?
        let range: NSRange
        let frames: [CGRect]
    }
}
