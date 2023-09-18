//
//  UserSettings.swift
//  MyReader
//
//  Created by  Dennya on 16/09/2023.
//

import Foundation

struct UserSettings {
    struct BookList {
        static let numberOfColumns = UserSettingAttribute<Int>(key: "BookList.NumberOfColumns")
    }
}
