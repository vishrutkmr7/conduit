import SwiftUI

/// Shows a provider's remote logo, falling back to the tinted SF Symbol tile
/// while loading or if the logo can't be fetched.
struct ServerLogo: View {
  var logoURLString: String?
  var symbol: String
  var tint: String
  var size: CGFloat
  var cornerRadius: CGFloat

  var body: some View {
    if let logoURLString, let url = URL(string: logoURLString) {
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
          fallback
        default:
          fallback.redacted(reason: .placeholder)
        }
      }
    } else {
      fallback
    }
  }

  private var fallback: some View {
    Image(systemName: symbol)
      .font(.system(size: size * 0.42))
      .foregroundStyle(.white)
      .frame(width: size, height: size)
      .background(ServerTint.color(tint).gradient, in: .rect(cornerRadius: cornerRadius))
  }
}
