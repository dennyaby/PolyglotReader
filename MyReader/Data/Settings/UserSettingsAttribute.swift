//
//  UserSettings.swift
//  MyReader
//
//  Created by  Dennya on 16/09/2023.
//

import Foundation

class UserSettingAttribute<Type> {
    
    enum StorageType {
        case standardUserDefaults
    }
    
    private let key: String
    private let defaultValue: Type?
    private let storageType: StorageType
    
    init(key: String, defaultValue: Type? = nil, storageType: StorageType = .standardUserDefaults) {
        self.key = key
        self.defaultValue = defaultValue
        self.storageType = storageType
    }
    
    func getValue() -> Type? {
        switch storageType {
        case .standardUserDefaults:
            return (UserDefaults.standard.value(forKey: key) as? Type) ?? defaultValue
        }
    }
    
    
    func setValue(_ value: Type?) {
        switch storageType {
        case .standardUserDefaults:
            if let value = value {
                UserDefaults.standard.setValue(value, forKey: key)
            } else {
                UserDefaults.standard.removeObject(forKey: key)
            }
            UserDefaults.standard.synchronize()
        }
    }
}
