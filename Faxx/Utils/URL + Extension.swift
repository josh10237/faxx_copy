//
//  URL + Extension.swift
//  Faxx
//
//  Created by Raul Cheng on 12/29/20.
//

import Foundation

extension URL {
    subscript(queryParam:String) -> String? {
        guard let url = URLComponents(string: self.absoluteString) else { return nil }
        return url.queryItems?.first(where: { $0.name == queryParam })?.value
    }
}
