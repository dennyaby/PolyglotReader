//
//  CSSDisplay.swift
//  MyReader
//
//  Created by  Dennya on 14/10/2023.
//

import Foundation

enum CSSDisplay: String, Equatable {
    
    case inline
    case block
    case contents
    case flex
    case grid
    case inlineBlock = "inline-block"
    case inlineFlex = "inline-flex"
    case inlineGrid = "inline-grid"
    case inlineTable = "inline-table"
    case listItem = "list-item"
    case runIn = "run-in"
    case table
    case tableCaption = "table-caption"
    case tableColumnGroup = "table-column-group"
    case tableHeaderGroup = "table-header-group"
    case tableFooterGroup = "table-footer-group"
    case tableRowGroup = "table-row-group"
    case tableCell = "table-cell"
    case tableColumn = "table-column"
    case tableRow = "table-row"
    case noDisplay = "none"
    case initial
    case inherit
    
    var isBlock: Bool {
        return self == .block
    }
}
