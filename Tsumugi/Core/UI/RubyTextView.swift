import SwiftUI
import UIKit

/// Component that renders Japanese text with native CoreText Ruby (furigana) annotations directly above Kanji characters.
public struct RubyTextView: UIViewRepresentable {
    public let text: String
    public let font: UIFont
    public let textColor: UIColor
    public let rubyFont: UIFont
    public let rubyColor: UIColor
    public let lineSpacing: CGFloat

    public init(
        text: String,
        font: UIFont = .systemFont(ofSize: 17, weight: .medium),
        textColor: UIColor = UIColor(Color.tsumugiTextPrimary),
        rubyFont: UIFont = .systemFont(ofSize: 10, weight: .regular),
        rubyColor: UIColor = .secondaryLabel,
        lineSpacing: CGFloat = 6
    ) {
        self.text = text
        self.font = font
        self.textColor = textColor
        self.rubyFont = rubyFont
        self.rubyColor = rubyColor
        self.lineSpacing = lineSpacing
    }

    public func makeUIView(context: Context) -> RubyContainerView {
        let view = RubyContainerView()
        view.backgroundColor = .clear
        view.isOpaque = false
        view.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        view.setContentHuggingPriority(.defaultLow, for: .horizontal)
        view.setContentCompressionResistancePriority(.required, for: .vertical)
        return view
    }

    public func updateUIView(_ uiView: RubyContainerView, context: Context) {
        uiView.update(
            text: text,
            font: font,
            textColor: textColor,
            rubyFont: rubyFont,
            rubyColor: rubyColor,
            lineSpacing: lineSpacing
        )
    }

    public func sizeThatFits(_ proposal: ProposedViewSize, uiView: RubyContainerView, context: Context) -> CGSize? {
        let targetWidth = proposal.width ?? UIScreen.main.bounds.width
        let calculatedHeight = uiView.heightForWidth(targetWidth)
        return CGSize(width: targetWidth, height: calculatedHeight)
    }
}

// MARK: - Native CoreText Ruby Rendering Container

public final class RubyContainerView: UIView {
    private var attributedString: NSAttributedString?
    private var cachedWidth: CGFloat = 0
    private var cachedHeight: CGFloat = 0

    override public init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isOpaque = false
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        backgroundColor = .clear
        isOpaque = false
    }

    public func update(
        text: String,
        font: UIFont,
        textColor: UIColor,
        rubyFont: UIFont,
        rubyColor: UIColor,
        lineSpacing: CGFloat
    ) {
        self.attributedString = Self.buildRubyAttributedString(
            from: text,
            font: font,
            textColor: textColor,
            rubyFont: rubyFont,
            rubyColor: rubyColor,
            lineSpacing: lineSpacing
        )
        cachedWidth = 0
        cachedHeight = 0
        invalidateIntrinsicContentSize()
        setNeedsDisplay()
    }

    public func heightForWidth(_ width: CGFloat) -> CGFloat {
        guard let attrStr = attributedString, width > 0 else { return 0 }
        if abs(cachedWidth - width) < 0.5 && cachedHeight > 0 {
            return cachedHeight
        }

        let framesetter = CTFramesetterCreateWithAttributedString(attrStr as CFAttributedString)
        let suggestedSize = CTFramesetterSuggestFrameSizeWithConstraints(
            framesetter,
            CFRangeMake(0, attrStr.length),
            nil,
            CGSize(width: width, height: CGFloat.greatestFiniteMagnitude),
            nil
        )

        let finalHeight = ceil(suggestedSize.height) + 6
        cachedWidth = width
        cachedHeight = finalHeight
        return finalHeight
    }

    override public var intrinsicContentSize: CGSize {
        let w = bounds.width > 0 ? bounds.width : UIScreen.main.bounds.width - 64
        return CGSize(width: w, height: heightForWidth(w))
    }

    override public func layoutSubviews() {
        super.layoutSubviews()
        setNeedsDisplay()
    }

    override public func draw(_ rect: CGRect) {
        guard let attrStr = attributedString, let context = UIGraphicsGetCurrentContext() else {
            return
        }

        context.saveGState()

        // Flip coordinates for CoreText (CoreText origin is bottom-left)
        context.textMatrix = .identity
        context.translateBy(x: 0, y: rect.height)
        context.scaleBy(x: 1.0, y: -1.0)

        let path = CGMutablePath()
        path.addRect(rect)

        let framesetter = CTFramesetterCreateWithAttributedString(attrStr as CFAttributedString)
        let frame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, attrStr.length), path, nil)

        CTFrameDraw(frame, context)
        context.restoreGState()
    }

    // MARK: - CoreText Ruby Builder

    public static func buildRubyAttributedString(
        from input: String,
        font: UIFont,
        textColor: UIColor,
        rubyFont: UIFont,
        rubyColor: UIColor,
        lineSpacing: CGFloat
    ) -> NSAttributedString {
        let result = NSMutableAttributedString()

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = lineSpacing
        paragraphStyle.lineBreakMode = .byWordWrapping
        paragraphStyle.lineHeightMultiple = 1.35

        let baseAttributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: textColor,
            .paragraphStyle: paragraphStyle
        ]

        // Match patterns like "日本語(にほんご)" or "行(い)"
        // Captures (Kanji)(Kana)
        let pattern = #"([一-龯々〆ヵヶ]+)\(([ぁ-んァ-ンー]+)\)"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return NSAttributedString(string: input, attributes: baseAttributes)
        }

        let nsInput = input as NSString
        var lastLocation = 0
        let matches = regex.matches(in: input, options: [], range: NSRange(location: 0, length: nsInput.length))

        for match in matches {
            // Append preceding text without ruby
            if match.range.location > lastLocation {
                let precedingRange = NSRange(location: lastLocation, length: match.range.location - lastLocation)
                let precedingText = nsInput.substring(with: precedingRange)
                result.append(NSAttributedString(string: precedingText, attributes: baseAttributes))
            }

            // Extract Kanji and Ruby reading
            let kanji = nsInput.substring(with: match.range(at: 1))
            let ruby = nsInput.substring(with: match.range(at: 2))

            // Create CTRubyAnnotation using Unmanaged<CFString> array
            var unmanagedRuby: [Unmanaged<CFString>?] = [
                .passRetained(ruby as CFString),
                nil,
                nil,
                nil
            ]

            let rubyAnnotation: CTRubyAnnotation = CTRubyAnnotationCreate(
                .auto,
                .auto,
                0.5,
                &unmanagedRuby
            )

            var kanjiAttributes = baseAttributes
            kanjiAttributes[kCTRubyAnnotationAttributeName as NSAttributedString.Key] = rubyAnnotation

            result.append(NSAttributedString(string: kanji, attributes: kanjiAttributes))

            lastLocation = match.range.location + match.range.length
        }

        // Append remaining text
        if lastLocation < nsInput.length {
            let remainingText = nsInput.substring(from: lastLocation)
            result.append(NSAttributedString(string: remainingText, attributes: baseAttributes))
        }

        return result
    }
}

#Preview {
    VStack(spacing: 24) {
        RubyTextView(
            text: "こんにちは！私(わたし)は日本語(にほんご)を勉強(べんきょう)しています。学校(がっこう)へ行(い)きます。",
            font: .systemFont(ofSize: 18, weight: .semibold),
            lineSpacing: 8
        )
        .frame(height: 90)
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    .padding()
}
