//
//  SelectionState.swift
//  MyReader
//
//  Created by  Dennya on 11/12/2023.
//

import Foundation

extension TextSelectionManager {
    struct SelectionState {
        let displayResult: TextSelectionDisplayManager.DisplayResult
        let range: NSRange
        
        var textSelectionInfo: TextSelectionInfo {
            return .init(range: range, selectionFrames: displayResult.displayFrames)
        }
    }
}
