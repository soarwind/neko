//
//  SingBoxConfig.swift
//  Neko
//
//  Created by CYC on 2018/8/26.
//  Copyright © 2024 west2online. All rights reserved.
//

import Foundation
import Cocoa

class SingBoxConfig: NSObject {
    static let initRulePayload = "NekoMetaInitConfigQWERTYUIOP".lowercased()

    struct Log: Codable {
        var level: String?
    }

    struct Inbound: Codable {
        var type: String
        var tag: String?
        var listen: String?
        var listenPort: Int?
        var sniff: Bool?
        var interfaceName: String?
        var autoRoute: Bool?
        var stack: String?
        var strictRoute: Bool?
        var dnsHijack: [String]?

        enum CodingKeys: String, CodingKey {
            case type
            case tag
            case listen
            case listenPort = "listen_port"
            case sniff
            case interfaceName = "interface_name"
            case autoRoute = "auto_route"
            case stack
            case strictRoute = "strict_route"
            case dnsHijack = "dns_hijack"
        }
    }

    struct Outbound: Codable {
        var type: String
        var tag: String
    }

    struct RouteRule: Codable {
        var domain: [String]?
        var domainSuffix: [String]?
        var domainKeyword: [String]?
        var geoip: String?
        var outbound: String?

        enum CodingKeys: String, CodingKey {
            case domain
            case domainSuffix = "domain_suffix"
            case domainKeyword = "domain_keyword"
            case geoip
            case outbound
        }
    }

    struct Route: Codable {
        var rules: [RouteRule]?
        var final: String?
    }

    struct ClashAPI: Codable {
        var externalController: String
        var externalUI: String?
        var secret: String?
        var storeSelected: Bool?
        var mode: String?

        enum CodingKeys: String, CodingKey {
            case externalController = "external_controller"
            case externalUI = "external_ui"
            case secret
            case storeSelected = "store_selected"
            case mode
        }
    }

    struct Experimental: Codable {
        var clashApi: ClashAPI?

        enum CodingKeys: String, CodingKey {
            case clashApi = "clash_api"
        }
    }

    struct Config: Codable {
        var log: Log?
        var inbounds: [Inbound]
        var outbounds: [Outbound]
        var route: Route?
        var experimental: Experimental?
        var safePaths: String?

        var path: String {
            guard let data = try? JSONEncoder().encode(self),
                  let string = String(data: data, encoding: .utf8),
                  let path = RemoteConfigManager.createCacheConfig(string: string) else {
                assertionFailure("Create init config file failed.")
                return ""
            }
            return path
        }

        mutating func loadDefaultConfigFile(_ path: String) {
            let fm = FileManager.default
            guard let data = fm.contents(atPath: path),
                  let config = try? JSONDecoder().decode(Config.self, from: data) else {
                return
            }

            log = config.log
            inbounds = config.inbounds
            outbounds = config.outbounds
            route = config.route
            experimental = config.experimental
        }

        mutating func updatePorts(_ usedPorts: String) {
            let usedPorts = usedPorts.split(separator: ",").compactMap { Int($0) }
            var availablePorts = Set(1..<65534)
            availablePorts.subtract(usedPorts)

            func update(_ port: Int?) -> Int? {
                guard let p = port, p != 0 else {
                    return port
                }

                if availablePorts.contains(p) {
                    availablePorts.remove(p)
                    return p
                } else if let p = Set(p..<65534).intersection(availablePorts).min() {
                    availablePorts.remove(p)
                    return p
                } else {
                    return nil
                }
            }

            if let index = inbounds.firstIndex(where: { ["mixed", "http", "socks"].contains($0.type) }) {
                var inbound = inbounds[index]
                inbound.listenPort = update(inbound.listenPort)
                inbounds[index] = inbound
            }

            if var clashApi = experimental?.clashApi {
                let ecPort: Int = {
                    if let port = clashApi.externalController.components(separatedBy: ":").last,
                       let p = Int(port) {
                        return p
                    } else {
                        return 9090
                    }
                }()

                let updatedPort = update(ecPort) ?? 9090
                clashApi.externalController = "127.0.0.1:\(updatedPort)"
                experimental?.clashApi = clashApi
            }
        }
    }

    static func generateInitConfig(_ callback: @escaping ((Config) -> Void)) {
        var config = defaultConfig()
        ApiRequest.findConfigPath(configName: ConfigManager.selectConfigName) {
            config.loadDefaultConfigFile($0 ?? "")
            callback(config)
        }
    }

    static func defaultConfig() -> Config {
        let log = Log(level: ConfigManager.selectLoggingApiLevel.rawValue)
        let inbound = Inbound(
            type: "mixed",
            tag: "mixed-in",
            listen: "127.0.0.1",
            listenPort: 7890,
            sniff: true,
            interfaceName: nil,
            autoRoute: nil,
            stack: nil,
            strictRoute: nil,
            dnsHijack: nil
        )
        let outbounds = [
            Outbound(type: "direct", tag: "direct"),
            Outbound(type: "block", tag: "block")
        ]
        let route = Route(
            rules: [
                RouteRule(domainKeyword: [initRulePayload], outbound: "block"),
                RouteRule(domainSuffix: ["google.com"], outbound: "direct"),
                RouteRule(domainKeyword: ["google"], outbound: "direct"),
                RouteRule(domain: ["google.com"], outbound: "direct"),
                RouteRule(domainSuffix: ["ad.com"], outbound: "block"),
                RouteRule(geoip: "cn", outbound: "direct")
            ],
            final: "direct"
        )
        let clashApi = ClashAPI(
            externalController: "127.0.0.1:9090",
            externalUI: defaultExternalUI(),
            secret: nil,
            storeSelected: true,
            mode: ConfigManager.selectOutBoundMode.rawValue
        )
        let experimental = Experimental(clashApi: clashApi)
        return Config(log: log, inbounds: [inbound], outbounds: outbounds, route: route, experimental: experimental, safePaths: nil)
    }

    static func defaultExternalUI() -> String? {
        var subpath = "dashboard/"

        switch ConfigManager.webDashboard {
        case .yacd:
            subpath += "yacd"
        case .metacubexd:
            subpath += "xd"
        case .zashboard:
            subpath += "zashboard"
        }

        guard let htmlPath = Bundle.main.path(forResource: "index", ofType: "html", inDirectory: subpath) else {
            return nil
        }
        return URL(fileURLWithPath: htmlPath).deletingLastPathComponent().path
    }

    static func updateConfigTun(_ config: Data, enable: Bool) -> String? {
        guard var payload = (try? JSONSerialization.jsonObject(with: config, options: [])) as? [String: Any] else {
            return nil
        }

        var inbounds = payload["inbounds"] as? [[String: Any]] ?? []

        if enable {
            if let index = inbounds.firstIndex(where: { ($0["type"] as? String) == "tun" }) {
                var tunInbound = inbounds[index]
                tunInbound["auto_route"] = true
                tunInbound["stack"] = "system"
                tunInbound["strict_route"] = true
                tunInbound["dns_hijack"] = ["any:53"]
                inbounds[index] = tunInbound
            } else {
                inbounds.append([
                    "type": "tun",
                    "tag": "tun-in",
                    "interface_name": "utun0",
                    "auto_route": true,
                    "stack": "system",
                    "strict_route": true,
                    "dns_hijack": ["any:53"]
                ])
            }
        } else {
            inbounds.removeAll(where: { ($0["type"] as? String) == "tun" })
        }

        payload["inbounds"] = inbounds

        guard let data = try? JSONSerialization.data(withJSONObject: payload, options: [.prettyPrinted]),
              let string = String(data: data, encoding: .utf8),
              let path = RemoteConfigManager.createCacheConfig(string: string) else {
            return nil
        }
        return path
    }
}
