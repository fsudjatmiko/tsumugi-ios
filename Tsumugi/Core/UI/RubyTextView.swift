import SwiftUI
import UIKit

/// Component that renders Japanese text with native CoreText Ruby (furigana) annotations directly above Kanji characters.
/// Can be initialized with a pre-tokenized array of `RubySegment` or with plain Japanese text parsed automatically via `JapaneseLinguisticHelper`.
public struct RubyTextView: UIViewRepresentable {
    public let segments: [RubySegment]
    public let showFurigana: Bool
    public let font: UIFont
    public let textColor: UIColor
    public let rubyFont: UIFont
    public let rubyColor: UIColor
    public let lineSpacing: CGFloat

    public init(
        segments: [RubySegment],
        showFurigana: Bool = true,
        font: UIFont = .systemFont(ofSize: 17, weight: .semibold),
        textColor: UIColor = UIColor(Color.tsumugiTextPrimary),
        rubyFont: UIFont = .systemFont(ofSize: 10, weight: .regular),
        rubyColor: UIColor = .secondaryLabel,
        lineSpacing: CGFloat = 6
    ) {
        self.segments = segments
        self.showFurigana = showFurigana
        self.font = font
        self.textColor = textColor
        self.rubyFont = rubyFont
        self.rubyColor = rubyColor
        self.lineSpacing = lineSpacing
    }

    public init(
        text: String,
        showFurigana: Bool = true,
        font: UIFont = .systemFont(ofSize: 17, weight: .semibold),
        textColor: UIColor = UIColor(Color.tsumugiTextPrimary),
        rubyFont: UIFont = .systemFont(ofSize: 10, weight: .regular),
        rubyColor: UIColor = .secondaryLabel,
        lineSpacing: CGFloat = 6
    ) {
        let clean = text.replacingOccurrences(of: #"\([ぁ-んァ-ンー]+\)"#, with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        self.segments = JapaneseLinguisticHelper.extractRubySegments(from: clean)
        self.showFurigana = showFurigana
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
            segments: segments,
            showFurigana: showFurigana,
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
        segments: [RubySegment],
        showFurigana: Bool,
        font: UIFont,
        textColor: UIColor,
        rubyFont: UIFont,
        rubyColor: UIColor,
        lineSpacing: CGFloat
    ) {
        self.attributedString = Self.buildRubyAttributedString(
            from: segments,
            showFurigana: showFurigana,
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
        from segments: [RubySegment],
        showFurigana: Bool,
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
        paragraphStyle.lineHeightMultiple = showFurigana ? 1.35 : 1.1

        let baseAttributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: textColor,
            .paragraphStyle: paragraphStyle
        ]

        for segment in segments {
            if showFurigana, let ruby = segment.ruby, !ruby.isEmpty {
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
                result.append(NSAttributedString(string: segment.text, attributes: kanjiAttributes))
            } else {
                result.append(NSAttributedString(string: segment.text, attributes: baseAttributes))
            }
        }

        return result
    }
}

#Preview {
    VStack(spacing: 24) {
        RubyTextView(
            text: "友達とカフェで昼ご飯を食べてもいいですか？",
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
