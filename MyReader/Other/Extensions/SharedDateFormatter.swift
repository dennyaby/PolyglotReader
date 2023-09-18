//
//  SharedDateFormatter.swift
//  MyReader
//
//  Created by  Dennya on 11/09/2023.
//

import Foundation

extension DateFormatter {
    
    private static var shared: [String: DateFormatter] = [:]
    
    static func key(for format: String, timeZone: TimeZone, locale: Locale) -> String {
        return "\(format)<>\(timeZone.description)<>\(locale.identifier)"
    }
    
    static func dateFormatter(for format: String, timeZone: TimeZone = .current, locale: Locale = .current) -> DateFormatter {
        let key = self.key(for: format, timeZone: timeZone, locale: locale)
        if let existing = self.shared[key] {
            return existing
        }
        
        var new = DateFormatter()
        new.dateFormat = format
        new.timeZone = timeZone
        new.locale = locale
        
        self.shared[key] = new
        return new
    }
}
