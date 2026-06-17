import SwiftUI

//
//  ServerLogo.swift
//  Conduit
//
//  Created by Vishrut Jha on 6/16/26.
//

/// Shows a provider's logo, falling back through a favicon for its host and then a
/// tinted SF Symbol tile. The tile is also shown (redacted) while images load.
struct ServerLogo: View {
  var logoURLString: String?
  /// Host used to derive a favicon when no logo is set or the logo fails to load.
  var host: String?
  var symbol: String
  var tint: String = "accent"
  var size: CGFloat
  var cornerRadius: CGFloat = 10

  private var faviconURL: URL? {
    guard let host, !host.isEmpty else { return nil }
    return URL(string: "https://www.google.com/s2/favicons?domain=\(host)&sz=128")
  }

  var body: some View {
    if let logoURLString, let url = URL(string: logoURLString) {
      remoteImage(url) { faviconOrSymbol }
    } else {
      faviconOrSymbol
    }
  }

  @ViewBuilder private var faviconOrSymbol: some View {
    if let faviconURL {
      remoteImage(faviconURL) { symbolTile }
    } else {
      symbolTile
    }
  }

  /// Renders a remote image, showing the symbol tile while loading and handing off
  /// to `next` if it fails so the fallback chain can continue.
  @ViewBuilder
  private func remoteImage(_ url: URL, @ViewBuilder next: @escaping () -> some View) -> some View {
    AsyncImage(url: url) { phase in
      switch phase {
      case .success(let image):
        image
          .resizable()
          .scaledToFit()
          .padding(size * 0.16)
          .frame(width: size, height: size)
          .background(.white, in: .rect(cornerRadius: cornerRadius))
      case .failure:
        next()
      default:
        symbolTile.redacted(reason: .placeholder)
      }
    }
  }

  private var symbolTile: some View {
    Image(systemName: symbol)
      .font(.system(size: size * 0.42))
      .foregroundStyle(.secondary)
      .frame(width: size, height: size)
      .background(.fill.tertiary, in: .rect(cornerRadius: cornerRadius))
  }
}
