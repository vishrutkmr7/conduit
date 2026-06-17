# Design

## Visual Theme

Conduit uses Apple-native product UI. Screens are composed from `NavigationSplitView`, `List`, `Form`, `Section`, `ContentUnavailableView`, `LabeledContent`, `Label`, `Button`, `Picker`, `GroupBox`, system sheets, system toolbars, and system materials. Liquid Glass should come from those system containers rather than custom background effects.

## Color

Use semantic SwiftUI styles only for app chrome: `.primary`, `.secondary`, `.tertiary`, `.background`, `.fill`, `.separator`, `.tint`, and standard semantic state colors where the state itself is the content. Provider logos and favicons may retain their original colors, but server color is not a decorative theme.

## Typography

Use Dynamic Type text styles only: `.largeTitle`, `.title`, `.headline`, `.subheadline`, `.body`, `.callout`, `.footnote`, and `.caption`. Avoid `.caption2` for meaningful status. Use weights sparingly, with `.bold()` only where the system context calls for it.

## Components

- Server rows use `Label`/`LabeledContent` patterns, SF Symbols, provider logos when available, and health status text plus symbol.
- Tool rows show name, summary, and risk metadata with native list rows.
- Empty states use `ContentUnavailableView` with a direct recovery action.
- Forms use `Form`, `Section`, `SecureField`, `TextField`, and native validation affordances.
- Confirmation for MCP tool execution uses App Intents confirmation or native confirmation dialogs, not custom modal styling.

## Layout

Use split navigation on iPad and adaptive stack behavior on iPhone. Avoid custom card grids as the default. Prefer list sections and forms for repeat-use workflows. Keep all controls at or above 44x44 hit size.

## Motion

Use system transitions and control feedback. Do not add decorative page-load animation. Long-running work uses native progress indicators and state text; cancellation and failure states are visible.
