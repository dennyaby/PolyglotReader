//
//  AppDateFormatters.swift
//  MyReader
//
//  Created by  Dennya on 12/09/2023.
//

import Foundation

extension DateFormatter {
    static var epubDefault: DateFormatter {
        return dateFormatter(for: "yyyy-MM-dd'T'HH:mm:ssZ")
    }
}
