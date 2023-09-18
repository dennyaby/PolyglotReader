//
//  AddButton.swift
//  MyReader
//
//  Created by  Dennya on 08/09/2023.
//

import UIKit

extension UIButton.State: Hashable {}

protocol StyledButton {
    var buttonStyle: ButtonStyle { get }
    func updateConfiguration()
}

struct ButtonStyle {
    
    // MARK: - Properties
    
    private var titleForState: [UIButton.State: String]
    private var foregroundColorForState: [UIButton.State: UIColor]
    private var opacityForState: [UIButton.State: CGFloat]
    
    // MARK: - Init
    
    init(title: String, foregroundColor: UIColor, opacityWhenHighlithed: CGFloat) {
        self.init(titleForState:  [.normal: title], foregroundColorForState: [.normal: foregroundColor], opacityForState: [.normal: 1, .highlighted: opacityWhenHighlithed])
    }
    
    init(titleForState: [UIButton.State: String], foregroundColorForState: [UIButton.State: UIColor], opacityForState: [UIButton.State: CGFloat]) {
        self.titleForState = titleForState
        self.foregroundColorForState = foregroundColorForState
        self.opacityForState = opacityForState
    }
    
    // MARK: - Interface
    
    func getConfig(for state: UIButton.State) -> UIButton.Configuration {
        var config = UIButton.Configuration.plain()
        config.title = titleForState[state] ?? titleForState[.normal]
        config.baseForegroundColor = foregroundColorForState[state] ?? foregroundColorForState[.normal]
        return config
    }
    
    func alpha(for state: UIButton.State) -> CGFloat {
        return opacityForState[state] ?? 1
    }
    
    static let plainStyle: UIButton.Configuration = {
        var config = UIButton.Configuration.plain()
//        config.color
        return config
    }()
}
