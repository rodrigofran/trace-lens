import Foundation
import SwiftUI

#if os(iOS) || os(tvOS) || os(visionOS)
  import UIKit
#elseif os(macOS)
  import AppKit
#endif

struct BodyPreview: View {
  // MARK: - Properties

  private static let characterLimit = 10_000

  let text: String

  @State private var isExpanded = false
  @State private var didCopy = false

  private var isTruncated: Bool {
    text.count > Self.characterLimit
  }

  private var displayedText: String {
    isExpanded || !isTruncated ? text : String(text.prefix(Self.characterLimit))
  }

  // MARK: - View

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      CodeTextView(attributedText: BodySyntaxHighlighter.highlight(displayedText))
      .frame(height: 480)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

      HStack(spacing: 12) {
        Button {
          copyToPasteboard(text)
          didCopy = true
        } label: {
          Label(didCopy ? "Body copiado" : "Copiar body", systemImage: didCopy ? "checkmark" : "doc.on.doc")
        }
        .buttonStyle(.bordered)

        if isTruncated {
          Button(isExpanded ? "Mostrar menos" : "Mostrar body completo") {
            isExpanded.toggle()
          }
          .buttonStyle(.bordered)
        }
      }
    }
  }

  // MARK: - Private Methods

  private func copyToPasteboard(_ value: String) {
    #if os(iOS) || os(tvOS) || os(visionOS)
      UIPasteboard.general.string = value
    #elseif os(macOS)
      NSPasteboard.general.clearContents()
      NSPasteboard.general.setString(value, forType: .string)
    #endif
  }
}

// MARK: - Code Text View

#if os(iOS) || os(tvOS) || os(visionOS)
  private struct CodeTextView: UIViewRepresentable {
    let attributedText: NSAttributedString

    func makeUIView(context: Context) -> UITextView {
      let textView = UITextView()
      textView.backgroundColor = .secondarySystemBackground
      textView.isEditable = false
      textView.isSelectable = true
      textView.alwaysBounceVertical = true
      textView.alwaysBounceHorizontal = true
      textView.showsHorizontalScrollIndicator = true
      textView.showsVerticalScrollIndicator = true
      textView.textContainerInset = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
      textView.textContainer.lineBreakMode = .byClipping
      textView.textContainer.widthTracksTextView = false
      textView.textContainer.size = CGSize(width: 10_000, height: CGFloat.greatestFiniteMagnitude)
      textView.accessibilityLabel = "Conteúdo do body"

      return textView
    }

    func updateUIView(_ textView: UITextView, context: Context) {
      textView.attributedText = attributedText
    }
  }
#elseif os(macOS)
  private struct CodeTextView: NSViewRepresentable {
    let attributedText: NSAttributedString

    func makeNSView(context: Context) -> NSScrollView {
      let textView = NSTextView()
      textView.backgroundColor = .controlBackgroundColor
      textView.isEditable = false
      textView.isSelectable = true
      textView.isHorizontallyResizable = true
      textView.isVerticallyResizable = true
      textView.textContainer?.widthTracksTextView = false
      textView.textContainer?.lineBreakMode = .byClipping
      textView.textContainerInset = NSSize(width: 16, height: 16)

      let scrollView = NSScrollView()
      scrollView.documentView = textView
      scrollView.hasVerticalScroller = true
      scrollView.hasHorizontalScroller = true
      scrollView.autohidesScrollers = true

      return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
      (scrollView.documentView as? NSTextView)?.textStorage?.setAttributedString(attributedText)
    }
  }
#endif

// MARK: - Body Syntax Highlighter

private enum BodySyntaxHighlighter {
  static func highlight(_ text: String) -> NSAttributedString {
    let result = NSMutableAttributedString(
      string: text,
      attributes: baseAttributes
    )

    applyJSONColors(to: result, text: text)
    applyMarkupColors(to: result, text: text)

    return result
  }

  // MARK: - Private Properties

  private static var baseAttributes: [NSAttributedString.Key: Any] {
    let paragraphStyle = NSMutableParagraphStyle()
    paragraphStyle.lineSpacing = 3

    return [
      .font: nativeFont,
      .foregroundColor: codeForeground,
      .paragraphStyle: paragraphStyle,
    ]
  }

  private static var nativeFont: NativeFont {
    #if os(iOS) || os(tvOS) || os(visionOS)
      .monospacedSystemFont(ofSize: 13, weight: .regular)
    #elseif os(macOS)
      .monospacedSystemFont(ofSize: 13, weight: .regular)
    #endif
  }

  // MARK: - Private Methods

  private static func applyJSONColors(to result: NSMutableAttributedString, text: String) {
    apply(pattern: #""(?:\\.|[^"\\])*""#, color: stringColor, to: result, text: text)
    apply(pattern: #""(?:\\.|[^"\\])*"(?=\s*:)"#, color: keyColor, to: result, text: text)
    apply(pattern: #"\b(?:true|false|null)\b"#, color: literalColor, to: result, text: text)
    apply(pattern: #"(?<![\w."])-?\b\d+(?:\.\d+)?(?:[eE][+-]?\d+)?\b"#, color: numberColor, to: result, text: text)
  }

  private static func applyMarkupColors(to result: NSMutableAttributedString, text: String) {
    apply(pattern: #"</?[^>]+>"#, color: markupColor, to: result, text: text)
  }

  private static func apply(
    pattern: String,
    color: NativeColor,
    to result: NSMutableAttributedString,
    text: String
  ) {
    guard let expression = try? NSRegularExpression(pattern: pattern) else {
      return
    }

    let fullRange = NSRange(text.startIndex..., in: text)

    expression.enumerateMatches(in: text, range: fullRange) { match, _, _ in
      guard let match else {
        return
      }

      result.addAttribute(.foregroundColor, value: color, range: match.range)
    }
  }

  // MARK: - Colors

  private static var codeForeground: NativeColor {
    #if os(iOS) || os(tvOS) || os(visionOS)
      .label
    #elseif os(macOS)
      .labelColor
    #endif
  }

  private static var keyColor: NativeColor {
    #if os(iOS) || os(tvOS) || os(visionOS)
      .systemBlue
    #elseif os(macOS)
      .systemBlue
    #endif
  }

  private static var stringColor: NativeColor {
    #if os(iOS) || os(tvOS) || os(visionOS)
      .label
    #elseif os(macOS)
      .labelColor
    #endif
  }

  private static var numberColor: NativeColor {
    #if os(iOS) || os(tvOS) || os(visionOS)
      .systemOrange
    #elseif os(macOS)
      .systemOrange
    #endif
  }

  private static var literalColor: NativeColor {
    #if os(iOS) || os(tvOS) || os(visionOS)
      .systemPurple
    #elseif os(macOS)
      .systemPurple
    #endif
  }

  private static var markupColor: NativeColor {
    #if os(iOS) || os(tvOS) || os(visionOS)
      .systemTeal
    #elseif os(macOS)
      .systemTeal
    #endif
  }
}

#if os(iOS) || os(tvOS) || os(visionOS)
  private typealias NativeColor = UIColor
  private typealias NativeFont = UIFont
#elseif os(macOS)
  private typealias NativeColor = NSColor
  private typealias NativeFont = NSFont
#endif

// MARK: - Body Formatter

enum BodyFormatter {
  static func format(data: Data, fallback: String, contentType: String?) -> String {
    if isJSON(contentType),
      let object = try? JSONSerialization.jsonObject(with: data),
      let formatted = try? JSONSerialization.data(
        withJSONObject: object,
        options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
      ),
      let text = String(data: formatted, encoding: .utf8)
    {
      return text
    }

    if isMarkup(contentType) || fallback.trimmingCharacters(in: .whitespacesAndNewlines).hasPrefix("<") {
      return prettyMarkup(fallback)
    }

    return fallback
  }

  // MARK: - Private Methods

  private static func isJSON(_ contentType: String?) -> Bool {
    guard let contentType = contentType?.lowercased() else {
      return true
    }

    return contentType.contains("json") || contentType.hasSuffix("+json")
  }

  private static func isMarkup(_ contentType: String?) -> Bool {
    guard let contentType = contentType?.lowercased() else {
      return false
    }

    return contentType.contains("xml") || contentType.contains("html")
  }

  private static func prettyMarkup(_ source: String) -> String {
    let voidElements: Set<String> = [
      "area", "base", "br", "col", "embed", "hr", "img", "input", "link", "meta", "param", "source",
      "track", "wbr",
    ]
    var result: [String] = []
    var remaining = source.trimmingCharacters(in: .whitespacesAndNewlines)[...]
    var indentation = 0

    while let opening = remaining.firstIndex(of: "<") {
      let text = remaining[..<opening].trimmingCharacters(in: .whitespacesAndNewlines)

      if !text.isEmpty {
        result.append(String(repeating: "  ", count: indentation) + text)
      }

      guard let closing = remaining[opening...].firstIndex(of: ">") else {
        result.append(String(repeating: "  ", count: indentation) + remaining[opening...])
        remaining = ""
        break
      }

      let tag = String(remaining[opening...closing])
      let normalized = tag.lowercased()
      let tagName = normalized
        .drop(while: { $0 == "<" || $0 == "/" || $0 == "!" || $0 == "?" })
        .prefix { !$0.isWhitespace && $0 != ">" && $0 != "/" }
      let isClosing = normalized.hasPrefix("</")
      let isSelfClosing = normalized.hasSuffix("/>") || voidElements.contains(String(tagName))
      let isDeclaration = normalized.hasPrefix("<?") || normalized.hasPrefix("<!")

      if isClosing {
        indentation = max(0, indentation - 1)
      }

      result.append(String(repeating: "  ", count: indentation) + tag)

      if !isClosing && !isSelfClosing && !isDeclaration {
        indentation += 1
      }

      remaining = remaining[remaining.index(after: closing)...]
    }

    let trailing = remaining.trimmingCharacters(in: .whitespacesAndNewlines)

    if !trailing.isEmpty {
      result.append(String(repeating: "  ", count: indentation) + trailing)
    }

    return result.isEmpty ? source : result.joined(separator: "\n")
  }
}
