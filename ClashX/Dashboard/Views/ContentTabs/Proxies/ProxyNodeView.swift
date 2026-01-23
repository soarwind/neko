//
//  ProxyNodeView.swift
//  ClashX Dashboard
//
//

import SwiftUI
import AppKit

struct ProxyNodeView: View {
	
	@ObservedObject var proxy: DBProxy
	@State var selectable: Bool
	@Binding var now: String?
	var onTestLatency: (() -> Void)?
	
	@EnvironmentObject var hideProxyNames: HideProxyNames
	
	
	init(proxy: DBProxy, selectable: Bool, now: Binding<String?> = .init(get: {nil}) { _ in }, onTestLatency: (() -> Void)? = nil) {
		self.proxy = proxy
		self.selectable = selectable
		self._now = now
		self.onTestLatency = onTestLatency
		self.isBuiltInProxy = [.pass, .direct, .reject].contains(proxy.type)
	}
	
	@State private var isBuiltInProxy: Bool
	@State private var mouseOver = false
	@State private var showDetails = false
	
	var body: some View {
		VStack {
			HStack(alignment: .center) {
				Text(hideProxyNames.hide
					 ? String(proxy.id.hiddenID)
					 : proxy.name)
					.truncationMode(.tail)
					.lineLimit(1)
				Spacer(minLength: 6)
				
				Text(proxy.udpString)
					.foregroundColor(.secondary)
					.font(.system(size: 11))
					.show(isVisible: !isBuiltInProxy)
			}
			
			Spacer(minLength: 6)
				.show(isVisible: !isBuiltInProxy)
			HStack(alignment: .center) {
                Text(proxy.type.rawString)
					.foregroundColor(.secondary)
					.font(.system(size: 12))
				
				Text("[TFO]")
					.font(.system(size: 9))
					.show(isVisible: proxy.tfo)
				Spacer(minLength: 6)
				Text(proxy.delayString)
					.foregroundColor(proxy.delayColor)
					.font(.system(size: 11))
			}
			.show(isVisible: !isBuiltInProxy)
		}
		.onHover {
			guard selectable else { return }
			mouseOver = $0
		}
		.frame(height: 34)
		.padding(12)
		.overlay(
			RoundedRectangle(cornerRadius: 6)
				.stroke({
					if mouseOver, now == proxy.name {
						return Color.accentColor
					} else if mouseOver {
						return Color.accentColor.opacity(0.7)
					} else {
						return Color.clear
					}
				}(), lineWidth: 2)
				.padding(1)
		)
		
		.background(now == proxy.name ? Color.accentColor.opacity(0.7) : Color("SwiftUI Colors/ContentBackgroundColor"))
		.contextMenu {
			Button("View Proxy Details") {
                proxy.loadFullConfig()
				showDetails = true
			}
			Button("Test Proxy Delay") {
				onTestLatency?()
			}
			.disabled(isBuiltInProxy)
		}
		.popover(isPresented: $showDetails) {
            ProxyDetailView(proxy: proxy, showDetails: $showDetails)
		}
	}

	private var displayName: String {
		hideProxyNames.hide ? String(proxy.id.hiddenID) : proxy.name
	}


}

struct ProxyDetailView: View {
    @ObservedObject var proxy: DBProxy
    @Binding var showDetails: Bool
    @State private var selectedTab = 0
    
    var body: some View {
        VStack(spacing: 0) {
            Picker("", selection: $selectedTab) {
                Text("Info").tag(0)
                Text("Config").tag(1)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(10)
            
            if selectedTab == 0 {
                // Formatted Info View
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        if let config = proxy.configDict {
                            ForEach(config.keys.sorted(), id: \.self) { key in
                                if !["name", "type", "proxies"].contains(key),
                                   let value = config[key] {
                                    HStack(alignment: .top) {
                                        Text(key.capitalized)
                                            .font(.system(size: 11, weight: .bold))
                                            .foregroundColor(.secondary)
                                            .frame(width: 80, alignment: .leading)
                                        
                                        Text("\(value)")
                                            .font(.system(size: 11, design: .monospaced))
                                            .textSelection(.enabled)
                                            .lineLimit(nil)
                                        Spacer()
                                    }
                                    Divider().opacity(0.5)
                                }
                            }
                        } else {
                            Text("Loading configuration...")
                                .foregroundColor(.secondary)
                                .padding()
                        }
                    }
                    .padding()
                }
            } else {
                // Raw Config View
                ScrollView {
                    Text(proxy.rawConfig)
                        .font(.system(.caption, design: .monospaced))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                }
            }
            
            Divider()
            
            HStack {
                Button("Copy Config") {
                    let pasteboard = NSPasteboard.general
                    pasteboard.clearContents()
                    pasteboard.setString(proxy.rawConfig, forType: .string)
                    showDetails = false
                }
                
                Button("Close") {
                    showDetails = false
                }
            }
            .padding(12)
        }
        .frame(width: 320, height: 450)
    }
}


//struct ProxyNodeView_Previews: PreviewProvider {
//    static var previews: some View {
//        ProxyNodeView()
//    }
//}
