//
//  URLResolver.swift
//  MyReader
//
//  Created by  Dennya on 01/11/2023.
//

import Foundation

final class URLResolver {
    
    static func resolveResource(path: String, linkedFrom url: URL) -> URL {
        fatalError("") // TODO: - Implement and test. Next plan - call this for font faces paths from css parser. After that you should test how font descriptor works - add a custom font (for example italic and bold), get its descriptor and test if descritor values are correct. After that test how matching works -  ask for a specific font family, but with 1) same parameters as font, 2) close parameters, and 3) different parameters. Test this with different font combinations in the app - for example if you have only bold but asking for light. And if you have bold and light, but asking for normal. What variables do we have - font weight and italic/non italic? Or something else
    }
}
