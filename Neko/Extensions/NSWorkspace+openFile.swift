//
//  NSWorkspace+openFile.swift
//  Neko
//
//  Copyright © 2024 west2online. All rights reserved.
//

import Cocoa

extension NSWorkspace {
	func openFilePath(_ path: String) {
		open(.init(fileURLWithPath: path))
	}
	
}
