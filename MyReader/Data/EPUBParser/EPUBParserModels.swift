//
//  EPUBParserModels.swift
//  MyReader
//
//  Created by  Dennya on 12/09/2023.
//

import Foundation

extension EPUBParser {
    enum MediaType: Equatable {
        case unknown(String)
        case oebpsPackage
        
        init(from: String) {
            switch from {
            case "application/oebps-package+xml":
                self = .oebpsPackage
            default:
                self = .unknown(from)
            }
        }
    }
    
    enum PageProgressionDirection {
        case leftToRight
        case rightToLeft
        case defaultDireciton
        
        init(from: String) {
            switch from {
            case "ltr": self = .leftToRight
            case "rtl": self = .rightToLeft
            default: self = .defaultDireciton
            }
        }
    }
    
    enum EPUBLayout {
        case reflowable
        case prePaginated
        
        init(from: String) {
            switch from {
            case "pre-paginated": self = .prePaginated
            default: self = .reflowable
            }
        }
    }
    
    enum EPUBOrientation {
        case landscape
        case portrait
        case auto
        
        init(from: String) {
            switch from {
            case "landscape": self = .landscape
            case "portrait": self = .portrait
            default: self = .auto
            }
        }
    }
    
    enum EPUBSyntheticSpreads {
        case none
        case landscape
        case both
        case auto
        
        init(from: String) {
            switch from {
            case "none":
                self = .none
            case "landscape":
                self = .landscape
            case "both":
                self = .both
            default:
                self = .auto
            }
        }
    }
    
    enum EPUBRenditionFlow {
        case paginated
        case scrolledContinuous
        case scrolledDoc
        case auto
        
        init(from: String) {
            switch from {
            case "paginated":
                self = .paginated
            case "scrolled-continuous":
                self = .scrolledContinuous
            case "scrolled-doc":
                self = .scrolledDoc
            default:
                self = .auto
            }
        }
    }
    
    struct ManifestItem {
        
        enum Properties: String {
            case coverImage = "cover-image"
            case mathml = "mathml"
            case nav = "nav"
            case remoteResources = "remote-resources"
            case scripted = "scripted"
            case svg = "svg"
            case switchProperty = "switch"
        }
        
        let href: String
        let id: String
        let mediaType: MediaType
        let fallback: String?
        let mediaOverlay: String?
        let properties: Properties?
    }
    
    struct SpineItem {
        
        enum Properties: String {
            case pageSpreadLeft = "page-spread-left"
            case pageSpreadRight = "page-spread-right"
        }
        
        let id: String?
        let idref: String
        let isLinear: Bool?
        let properties: Properties?
    }
    
    struct MetaItem {
        let name: String?
        let content: String?
        let property: String?
    }
}
