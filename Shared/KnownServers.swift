import Foundation

/// A curated, well-known remote MCP server the user can add with one tap.
struct KnownServer: Identifiable, Hashable, Sendable {
  var id: String { name }
  var name: String
  var summary: String
  var urlString: String
  var symbol: String
  var tint: String
  var authKind: MCPAuthKind
  /// Page to open in the in-app browser to obtain credentials, when applicable.
  var authURLString: String?

  func makeServer() -> MCPServer {
    MCPServer(
      name: name,
      urlString: urlString,
      symbol: symbol,
      tint: tint,
      authKind: authKind,
      isCustom: false
    )
  }
}

enum KnownServers {
  static let all: [KnownServer] = [
    KnownServer(
      name: "GitHub",
      summary: "Repos, issues, and pull requests.",
      urlString: "https://api.githubcopilot.com/mcp/",
      symbol: "chevron.left.forwardslash.chevron.right",
      tint: "purple",
      authKind: .oauth,
      authURLString: "https://github.com/login"
    ),
    KnownServer(
      name: "Linear",
      summary: "Issues, projects, and cycles.",
      urlString: "https://mcp.linear.app/mcp",
      symbol: "checklist",
      tint: "indigo",
      authKind: .oauth,
      authURLString: "https://linear.app/login"
    ),
    KnownServer(
      name: "Notion",
      summary: "Pages, databases, and docs.",
      urlString: "https://mcp.notion.com/mcp",
      symbol: "doc.richtext",
      tint: "gray",
      authKind: .oauth,
      authURLString: "https://www.notion.so/login"
    ),
    KnownServer(
      name: "Sentry",
      summary: "Errors and performance issues.",
      urlString: "https://mcp.sentry.dev/mcp",
      symbol: "ladybug",
      tint: "orange",
      authKind: .oauth,
      authURLString: "https://sentry.io/auth/login/"
    ),
    KnownServer(
      name: "Stripe",
      summary: "Payments, customers, and invoices.",
      urlString: "https://mcp.stripe.com",
      symbol: "creditcard",
      tint: "blue",
      authKind: .bearer
    ),
    KnownServer(
      name: "Hugging Face",
      summary: "Models, datasets, and spaces.",
      urlString: "https://huggingface.co/mcp",
      symbol: "brain",
      tint: "yellow",
      authKind: .bearer
    ),
    KnownServer(
      name: "DeepWiki",
      summary: "Docs for any public GitHub repo.",
      urlString: "https://mcp.deepwiki.com/mcp",
      symbol: "book",
      tint: "green",
      authKind: .none
    ),
    KnownServer(
      name: "Context7",
      summary: "Up-to-date library documentation.",
      urlString: "https://mcp.context7.com/mcp",
      symbol: "books.vertical",
      tint: "mint",
      authKind: .none
    )
  ]
}
