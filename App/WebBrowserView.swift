//
//  WebBrowserView.swift
//  Conduit
//
//  Created by Vishrut Jha on 6/16/26.
//

import SwiftUI
import WebKit

struct WebBrowserView: View {
  let url: URL
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    NavigationStack {
      WebView(url: url)
        .ignoresSafeArea(edges: .bottom)
        .navigationTitle(url.host() ?? "Sign In")
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
