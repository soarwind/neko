//
//  ProxyNodeView.swift
//  ClashX Dashboard
//
//

import SwiftUI

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
			Button(NSLocalizedString("View Proxy Details", comment: "")) {
				showDetails = true
			}
			Button(NSLocalizedString("Test Proxy Delay", comment: "")) {
				onTestLatency?()
			}
			.disabled(isBuiltInProxy)
		}
		.alert(NSLocalizedString("Proxy Details", comment: ""), isPresented: $showDetails) {
			Button(NSLocalizedString("OK", comment: ""), role: .cancel) {
			}
		} message: {
			Text(detailText)
		}
	}

	private var displayName: String {
		hideProxyNames.hide ? String(proxy.id.hiddenID) : proxy.name
	}

	private var detailText: String {
		let nameLabel = NSLocalizedString("Name", comment: "")
		let typeLabel = NSLocalizedString("Type", comment: "")
		let delayLabel = NSLocalizedString("Delay", comment: "")
		let udpLabel = NSLocalizedString("UDP", comment: "")
		let tfoLabel = NSLocalizedString("TFO", comment: "")
		let onLabel = NSLocalizedString("On", comment: "")
		let offLabel = NSLocalizedString("Off", comment: "")
		let udpValue = proxy.udpString.isEmpty ? offLabel : proxy.udpString
		let tfoValue = proxy.tfo ? onLabel : offLabel

		return [
			"\(nameLabel): \(displayName)",
			"\(typeLabel): \(proxy.type.rawString)",
			"\(delayLabel): \(proxy.delayString)",
			"\(udpLabel): \(udpValue)",
			"\(tfoLabel): \(tfoValue)"
		].joined(separator: "\n")
	}
}

//struct ProxyNodeView_Previews: PreviewProvider {
//    static var previews: some View {
//        ProxyNodeView()
//    }
//}
