//
//  NSColor+Extension.swift
//  Neko
//
//  Copyright © 2023 west2online. All rights reserved.
//

import Foundation
import Cocoa

extension NSColor {
    func withDisabledEffect() -> NSColor {
        let color: NSColor
        if #available(OSX 10.14, *) {
            color = self.withSystemEffect(.disabled)
        } else {
            color = self.withAlphaComponent(0.5)
        }
        return color
    }
}
