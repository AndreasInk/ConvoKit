//
//  BezelRectangle.swift
//
//
//  Created by Andreas Ink on 1/3/24.
//

import SwiftUI

@available(iOS 17.0, *)
extension Shape where Self == RoundedRectangle {
    static var bezelRectangle: RoundedRectangle {
        RoundedRectangle(cornerRadius: 26,
                         style: .circular)
    }
}
