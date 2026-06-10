import SwiftUI
import WebKit

/// A minimal in-app browser used to sign in to a server's provider.
struct WebBrowserView: View {
  let url: URL
  @Environment(\.dismiss) private var dismiss
  @State private var title: String = "Sign In"

  var body: some View {
    NavigationStack {
      WebView(url: url, title: $title)
        .ignoresSafeArea(edges: .bottom)
        .navigationTitle(title)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
          ToolbarItem(placement: .confirmationAction) {
            Button("Done") { dismiss() }
          }
        }
    }
  }
}

#if os(iOS)
private struct WebView: UIViewRepresentable {
  let url: URL
  @Binding var title: String

  func makeUIView(context: Context) -> WKWebView {
    let webView = WKWebView()
    webView.navigationDelegate = context.coordinator
    webView.load(URLRequest(url: url))
    return webView
  }

  func updateUIView(_ webView: WKWebView, context: Context) {}

  func makeCoordinator() -> Coordinator { Coordinator(self) }

  final class Coordinator: NSObject, WKNavigationDelegate {
    let parent: WebView
    init(_ parent: WebView) { self.parent = parent }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
      if let host = webView.url?.host() { parent.title = host }
    }
  }
}
#elseif os(macOS)
private struct WebView: NSViewRepresentable {
  let url: URL
  @Binding var title: String

  func makeNSView(context: Context) -> WKWebView {
    let webView = WKWebView()
    webView.navigationDelegate = context.coordinator
    webView.load(URLRequest(url: url))
    return webView
  }

  func updateNSView(_ webView: WKWebView, context: Context) {}

  func makeCoordinator() -> Coordinator { Coordinator(self) }

  final class Coordinator: NSObject, WKNavigationDelegate {
    let parent: WebView
    init(_ parent: WebView) { self.parent = parent }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
      if let host = webView.url?.host() { parent.title = host }
    }
  }
}
#endif
