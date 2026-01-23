//
//  Paths.swift
//  Neko
//
//  Created by CYC on 2018/8/26.
//  Copyright © 2018年 west2online. All rights reserved.
//
import Foundation

let kConfigFolderPath = "\(NSHomeDirectory())/.config/sing-box/"

let kDefaultConfigFilePath = "\(kConfigFolderPath)config.json"

let kDefauleMetaCoreName = "sing-box"

let kSafeConfigName = ".sing-box_config"

enum Paths {
    static func localConfigPath(for name: String) -> String {
        return "\(kConfigFolderPath)\(configFileName(for: name))"
    }

    static func configFileName(for name: String) -> String {
        return "\(name).json"
    }

    static func defaultCorePath() -> URL? {
		Paths
			.applicationSupportDirectory()?
			.appendingPathComponent(".private_core")
			.appendingPathComponent(kDefauleMetaCoreName)
    }

    static func defaultCoreGzPath() -> String? {
		guard let path = Bundle.main.path(forResource: kDefauleMetaCoreName, ofType: "gz") else {
			return nil
		}
		return FileManager.default.fileExists(atPath: path) ? path : nil
    }

    static func alphaCorePath() -> URL? {
		Paths
			.applicationSupportDirectory()?
			.appendingPathComponent(kDefauleMetaCoreName)
    }

	static func applicationSupportDirectory() -> URL? {
		FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
			.first?
			.appendingPathComponent("com.sagernet.sing-box")
	}

	static func tempPath() -> String {
		guard let url = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
			.first?
			.appendingPathComponent("com.SagerNet.sing-box") else {
			return NSTemporaryDirectory().appending("com.SagerNet.sing-box")
		}
		
		try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
		
		return url.path
	}
}
