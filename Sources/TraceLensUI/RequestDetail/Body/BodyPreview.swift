import Foundation
import SwiftUI

struct BodyPreview: View {
  private static let characterLimit = 10_000
  let text: String
  @State private var isExpanded = false

  private var isTruncated: Bool { text.count > Self.characterLimit }
  private var displayedText: String {
    isExpanded || !isTruncated ? text : String(text.prefix(Self.characterLimit))
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text(displayedText)
        .font(.system(.body, design: .monospaced))
        .textSelection(.enabled)

      if isTruncated {
        Button(isExpanded ? "Mostrar menos" : "Mostrar body completo") {
          isExpanded.toggle()
        }
        .buttonStyle(.bordered)
      }
    }
  }
}

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
