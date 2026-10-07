import SwiftUI
import WebKit

struct IPv4AddressVisualWebView: UIViewRepresentable {
    let example: IPv4VisualExample
    let selectedOctet: Int?
    let solved: Bool
    let theme: ColorScheme
    let fontScale: Double
    let reduceMotion: Bool
    let isActive: Bool
    let onSelect: (Int) -> Void
    let onHeight: (CGFloat) -> Void
    let onFailure: () -> Void
    var introduction: IPv4IntroductionProgress? = nil

    func makeCoordinator() -> Coordinator { Coordinator(parent: self) }

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .nonPersistent()
        configuration.userContentController.add(context.coordinator, name: "ipv4Visual")

        let view = WKWebView(frame: .zero, configuration: configuration)
        view.navigationDelegate = context.coordinator
        view.isOpaque = false
        view.backgroundColor = .clear
        view.scrollView.isScrollEnabled = false
        context.coordinator.webView = view

        if let file = Bundle.main.url(forResource: "ipv4-address-visual", withExtension: "html") {
            context.coordinator.fileURL = file
            view.loadFileURL(file, allowingReadAccessTo: file)
        } else {
            DispatchQueue.main.async { context.coordinator.parent.onFailure() }
        }
        return view
    }

    func updateUIView(_ view: WKWebView, context: Context) {
        context.coordinator.parent = self
        context.coordinator.sendStateIfReady()
    }

    static func dismantleUIView(_ view: WKWebView, coordinator: Coordinator) {
        view.stopLoading()
        view.navigationDelegate = nil
        view.configuration.userContentController.removeScriptMessageHandler(forName: "ipv4Visual")
        coordinator.webView = nil
    }

    final class Coordinator: NSObject, WKScriptMessageHandler, WKNavigationDelegate {
        var parent: IPv4AddressVisualWebView
        weak var webView: WKWebView?
        var fileURL: URL?
        private var ready = false
        private var lastState: String?
        private var wasActive = true

        init(parent: IPv4AddressVisualWebView) { self.parent = parent }

        func sendStateIfReady() {
            guard ready, let webView else { return }
            if !parent.isActive && wasActive {
                webView.callAsyncJavaScript("window.WangGanIPv4.pause()", in: nil, in: .page) { _ in }
            }
            wasActive = parent.isActive

            let stateKey = "\(parent.example.ip)/\(parent.example.prefix)/\(parent.example.mode.rawValue)/\(parent.selectedOctet ?? 0)/\(parent.solved)/\(parent.theme)/\(parent.fontScale)/\(parent.reduceMotion)/\(parent.introduction?.stage ?? -1)/\(parent.introduction?.rangeValue ?? 0)"
            guard lastState != stateKey else { return }
            lastState = stateKey
            var input: [String: Any] = [
                "ip": parent.example.ip,
                "prefix": parent.example.prefix,
                "mode": parent.example.mode.rawValue,
                "selectedOctet": parent.selectedOctet as Any? ?? NSNull(),
                "solved": parent.solved,
                "theme": parent.theme == .dark ? "dark" : "light",
                "fontScale": parent.fontScale,
                "reduceMotion": parent.reduceMotion
            ]
            if let introduction = parent.introduction {
                input["introductionStage"] = introduction.stage
                input["rangeValue"] = introduction.rangeValue
            }
            webView.callAsyncJavaScript("window.WangGanIPv4.update(config)", arguments: ["config": input],
                                        in: nil, in: .page) { [weak self, weak webView] result in
                guard let self, self.webView === webView else { return }
                if case .failure = result { self.parent.onFailure() }
            }
        }

        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            guard message.webView === webView, message.frameInfo.isMainFrame,
                  let body = message.body as? [String: Any], let type = body["type"] as? String else { return }
            switch type {
            case "ready":
                ready = true
                sendStateIfReady()
            case "select":
                let canSelect = parent.introduction.map { $0.stage == 0 }
                    ?? (parent.example.mode == .practice && !parent.solved)
                guard canSelect,
                      let selected = body["value"] as? Int, (1...4).contains(selected) else { return }
                parent.onSelect(selected)
            case "height":
                guard let number = body["value"] as? NSNumber else { return }
                parent.onHeight(CGFloat(min(max(number.doubleValue, 250), 1800)))
            case "error":
                parent.onFailure()
            default: break
            }
        }

        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction,
                     decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            decisionHandler(navigationAction.request.url == fileURL ? .allow : .cancel)
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            parent.onFailure()
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            parent.onFailure()
        }

        func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
            parent.onFailure()
        }
    }
}
