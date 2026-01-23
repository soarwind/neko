//
//  DBProxyStorage.swift
//  ClashX Dashboard
//
//

import Cocoa
import SwiftUI
import Yams

class DBProxyStorage: ObservableObject {
	@Published var groups = [DBProxyGroup]()
	
	init() {
		
	}
	
	init(_ resp: ClashProxyResp) {
		groups = resp.proxyGroups.map {
			DBProxyGroup($0, resp: resp)
		}
	}
}

class DBProxyGroup: ObservableObject, Identifiable {
	let id = UUID().uuidString
	@Published var name: ClashProxyName
	@Published var type: ClashProxyType
	@Published var now: ClashProxyName? {
		didSet {
			currentProxy = proxies.first {
				$0.name == now
			}
		}
	}
	
	@Published var proxies: [DBProxy]
	@Published var currentProxy: DBProxy?
	
    @Published var hidden: Bool
    
	init(_ group: ClashProxy, resp: ClashProxyResp) {
		name = group.name
		type = group.type
		now = group.now
        hidden = group.hidden ?? false

		proxies = group.all?.compactMap { name in
			resp.proxiesMap[name]
		}.map(DBProxy.init) ?? []
		
		currentProxy = proxies.first {
			$0.name == now
		}
	}
}

class DBProxy: ObservableObject {
	let id: String
	@Published var name: ClashProxyName
	@Published var type: ClashProxyType
	@Published var udpString: String
	@Published var tfo: Bool
    @Published var rawConfig: String = ""
    @Published var configDict: [String: Any]?
    let providerName: String?
	
	var delay: Int {
		didSet {
        // ... (lines 68-76 unchanged)

// ...

    func loadFullConfig() {
        ConfigManager.getConfigPath(configName: ConfigManager.selectConfigName) { [weak self] path in
            guard let self = self else { return }
            DispatchQueue.global(qos: .userInitiated).async {
                func updateConfig(with proxyConfig: [String: Any]) {
                    DispatchQueue.main.async {
                        var merged = proxyConfig
                        let cleanMerged = DBProxy.cleanConfig(merged)
                        self.configDict = cleanMerged // Update structured data
                        do {
                            let yamlString = try Yams.dump(object: [cleanMerged])
                            self.rawConfig = yamlString
                        } catch {
                             if let jsonData = try? JSONSerialization.data(withJSONObject: cleanMerged, options: .prettyPrinted),
                                let jsonString = String(data: jsonData, encoding: .utf8) {
                                 self.rawConfig = jsonString
                             }
                        }
                    }
                }
                
                guard let content = try? String(contentsOfFile: path),
                      let yaml = try? Yams.load(yaml: content) as? [String: Any] else {
                    return
                }
                // ... (rest of logic same as before)
			delayString = DBProxy.delayString(delay)
			delayColor = DBProxy.delayColor(delay)
		}
	}
	
	@Published var delayString: String
	@Published var delayColor: Color
	
	init(_ proxy: ClashProxy) {
		id = proxy.id ?? UUID().uuidString
		name = proxy.name
		type = proxy.type
		tfo = proxy.tfo
		delay = proxy.history.last?.delayInt ?? 0
        providerName = proxy.enclosingProvider?.name
				
		udpString = {
			if proxy.udp {
				return "UDP"
			} else if proxy.xudp {
				return "XUDP"
			} else {
				return ""
			}
		}()
		delayString = DBProxy.delayString(delay)
		delayColor = DBProxy.delayColor(delay)
        
        if let config = proxy.rawConfig {
             let cleanConfig = DBProxy.cleanConfig(config)
             do {
                 let yaml = try Yams.dump(object: [cleanConfig])
                 rawConfig = yaml
             } catch {
                 // Fallback to JSON if YAML fails
                 if let jsonData = try? JSONSerialization.data(withJSONObject: cleanConfig, options: .prettyPrinted),
                    let jsonString = String(data: jsonData, encoding: .utf8) {
                     rawConfig = jsonString
                 } else {
                     rawConfig = "Error encoding config: \(error)"
                 }
             }
        }
	}
    
    static func cleanConfig(_ config: [String: Any]) -> [String: Any] {
        var newConfig = config
        for (key, value) in config {
            if value is NSNull {
                newConfig.removeValue(forKey: key)
            } else if let dict = value as? [String: Any] {
                newConfig[key] = cleanConfig(dict)
            } else if let array = value as? [Any] {
                newConfig[key] = cleanConfig(array)
            }
        }
        return newConfig
    }
    
    static func cleanConfig(_ array: [Any]) -> [Any] {
        return array.compactMap { item -> Any? in
            if item is NSNull {
                return nil
            } else if let dict = item as? [String: Any] {
                return cleanConfig(dict)
            } else if let subArray = item as? [Any] {
                return cleanConfig(subArray)
            } else {
                return item
            }
        }
	}
	
	static func delayString(_ delay: Int) -> String {
		switch delay {
		case 0:
			return NSLocalizedString("fail", comment: "")
		default:
			return "\(delay) ms"
		}
	}
	
	static func delayColor(_ delay: Int) -> Color {
		let httpsTest = ConfigManager.shared.benchMarkUrl.hasPrefix("https://")
		
		switch delay {
		case 0:
            return .red
		case ..<200 where !httpsTest:
			return .green
		case ..<800 where httpsTest:
			return .green
		case 200..<500 where !httpsTest:
			return .yellow
		case 800..<1500 where httpsTest:
			return .yellow
		default:
			return .orange
		}
	}
    func loadFullConfig() {
        ConfigManager.getConfigPath(configName: ConfigManager.selectConfigName) { [weak self] path in
            guard let self = self else { return }
            DispatchQueue.global(qos: .userInitiated).async {
                func updateConfig(with proxyConfig: [String: Any]) {
                    DispatchQueue.main.async {
                        var merged = proxyConfig
                        let cleanMerged = DBProxy.cleanConfig(merged)
                        self.configDict = cleanMerged
                        do {
                            let yamlString = try Yams.dump(object: [cleanMerged])
                            self.rawConfig = yamlString
                        } catch {
                             if let jsonData = try? JSONSerialization.data(withJSONObject: cleanMerged, options: .prettyPrinted),
                                let jsonString = String(data: jsonData, encoding: .utf8) {
                                 self.rawConfig = jsonString
                             }
                        }
                    }
                }
                
                guard let content = try? String(contentsOfFile: path),
                      let yaml = try? Yams.load(yaml: content) as? [String: Any] else {
                    return
                }
                
                // If it belongs to a provider
                if let providerName = self.providerName,
                   let providers = yaml["proxy-providers"] as? [String: Any],
                   let provider = providers[providerName] as? [String: Any] {
                   
                    // Get provider path
                    var providerPath: String?
                    if let pathStr = provider["path"] as? String {
                         // Resolve path relative to config file
                         let configDir = (path as NSString).deletingLastPathComponent
                         if pathStr.hasPrefix("/") {
                             providerPath = pathStr
                         } else {
                             providerPath = (configDir as NSString).appendingPathComponent(pathStr)
                         }
                    }
                    
                    if let pPath = providerPath,
                       let pContent = try? String(contentsOfFile: pPath),
                       let pYaml = try? Yams.load(yaml: pContent) as? [String: Any],
                       let pProxies = pYaml["proxies"] as? [[String: Any]] {
                        
                        if let proxyConfig = pProxies.first(where: { ($0["name"] as? String) == self.name }) {
                             updateConfig(with: proxyConfig)
                             return
                        }
                    }
                }

                // If not found in provider or no provider, search in main config proxies
                if let proxies = yaml["proxies"] as? [[String: Any]] {
                    if let proxyConfig = proxies.first(where: { ($0["name"] as? String) == self.name }) {
                        updateConfig(with: proxyConfig)
                    }
                }
            }
        }
    }
}


extension String {
    var hiddenID: String {
        guard UUID(uuidString: self) != nil else { return "" }
        let components = split(separator: "-").map(String.init)
        guard components.count == 5 else { return "" }
        
        let re = components[0].prefix(2)
        + components[1].prefix(1)
        + components[2].prefix(1)
        + components[3].prefix(1)
        + components[4].suffix(3)
        
        return String(re)
    }
}
