//
//  EPUBDataProviderManualParseParagraphStyleManager.swift
//  MyReader
//
//  Created by  Dennya on 05/11/2023.
//

import Foundation
import UIKit

extension EPUBDataProviderManualParse {
    final class ParagraphStyleManager {
        
        // MARK: - Interface
        
        func generateParagraphStyle(for attributes: Attributes, fontSize: CGFloat, pageSize: CGSize, config: EPUBDataProviderConfig) -> NSParagraphStyle {
            let ps = NSMutableParagraphStyle()
            ps.alignment = attributes.textAlign?.textAlign ?? .left
            
            ps.paragraphSpacingBefore = spacingsSum([attributes.paddingTop, attributes.marginTop], isHorizontal: false, fontSize: fontSize, pageSize: pageSize)
            ps.paragraphSpacing = spacingsSum([attributes.paddingBottom, attributes.marginBottom], isHorizontal: false, fontSize: fontSize, pageSize: pageSize)
            ps.tailIndent = -spacingsSum([attributes.paddingRight, attributes.marginRight], isHorizontal: true, fontSize: fontSize, pageSize: pageSize)
            
            let headIndent = spacingsSum([attributes.paddingLeft, attributes.marginLeft], isHorizontal: true, fontSize: fontSize, pageSize: pageSize)
            ps.firstLineHeadIndent = ps.firstLineHeadIndent + headIndent
            ps.headIndent = headIndent
            
            // TODO: I dont like that spacing between letters is different. And there are no hypens -
            
            return ps
        }
        
        // MARK: - Helper
        
        private func spacingsSum(_ spacings: [CSSNumericValue?], isHorizontal: Bool, fontSize: CGFloat, pageSize: CGSize) -> CGFloat {
            return spacings.compactMap({ $0 })
                .map({ numericValueToPoints($0, isHorizontal: isHorizontal, fontSize: fontSize, pageSize: pageSize)})
                .reduce(0, +)
        }
        
        private func numericValueToPoints(_ value: CSSNumericValue, isHorizontal: Bool, fontSize: CGFloat, pageSize: CGSize) -> CGFloat {
            switch value {
            case .pt(let pt): return pt
            case .px(let px): return px
            case .em(let em): return fontSize * em
            case .percent(let percent):
                let normalized = percent / 100
                return normalized * (isHorizontal ? pageSize.width : pageSize.height)
            }
        }
    }
}
