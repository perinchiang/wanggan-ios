import SwiftUI
import UIKit

struct QuestionConversation: View {
    let question: Question
    let lesson: Lesson
    let step: Int
    let challenge: Bool

    private var prefix: String { challenge ? "challenge" : "question" }
    private var ready: Bool { step >= question.scene.count }
    private var visibleMessages: [SceneMessage] { Array(question.scene.prefix(min(step + 1, question.scene.count))) }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            ForEach(visibleMessages) { message in
                VStack(alignment: .leading, spacing: 16) {
                    ConversationBubble(text: message.text, role: message.speaker)
                        .accessibilityIdentifier("\(prefix)-scene-\(message.id)")
                    if message.visual == "network" {
                        NetworkDiagram(kind: lesson.diagram)
                    } else if message.visual == "devices", !ready, let devices = question.devices {
                        AddressComparison(devices: devices, identifier: "\(prefix)-intro-addresses")
                    }
                }
                .id("\(prefix)-scene-\(message.id)")
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
            if ready {
                VStack(alignment: .leading, spacing: 18) {
                    ConversationBubble(text: question.prompt, isQuestion: true)
                        .accessibilityIdentifier("\(prefix)-prompt")
                    if let devices = question.devices {
                        AddressComparison(devices: devices, identifier: "\(prefix)-answer-addresses")
                    }
                }
                .id("\(prefix)-prompt")
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
    }
}

struct ConversationBubble: View {
    let text: String
    var isQuestion = false
    var role: String? = nil
    var highlightedTerms: [String] = []

    private var isUser: Bool { role == "user" }

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            if isUser { Spacer(minLength: 42) }

            if !isUser {
                if role == "technician" {
                    Image(systemName: "wrench.and.screwdriver.fill")
                        .font(.system(size: 17, weight: .semibold))
                        .frame(width: 34, height: 34)
                        .background(Theme.surface, in: .circle)
                        .padding(.top, 10)
                        .accessibilityHidden(true)
                } else if role == "friend" {
                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 32))
                        .padding(.top, 10)
                        .accessibilityHidden(true)
                } else {
                    PacketMascot(size: 34).padding(.top, 10)
                }
            }

            VStack(alignment: .leading, spacing: 9) {
                if role == "friend" {
                    Text("朋友").font(.caption.weight(.semibold)).foregroundStyle(Theme.muted)
                }
                if highlightedTerms.isEmpty {
                    Text(text)
                        .font(.system(size: isQuestion ? 22 : 20, weight: isQuestion ? .bold : .medium))
                        .lineSpacing(6)
                        .multilineTextAlignment(.leading)
                } else {
                    HighlightedConversationText(text: text, terms: highlightedTerms)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, isUser || isQuestion ? 10 : 20)
            .padding(.vertical, 20)
            .background(isUser || isQuestion ? Theme.lime.opacity(0.24) : Theme.surface,
                        in: .rect(topLeadingRadius: isUser ? 22 : 6,
                                  bottomLeadingRadius: 22,
                                  bottomTrailingRadius: 22,
                                  topTrailingRadius: isUser ? 6 : 22))

            if isUser {
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(Theme.ink)
                    .padding(.top, 10)
                    .accessibilityHidden(true)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

/// Inline marker backgrounds keep the paragraph's natural wrapping on iOS 17.
/// UILabel renders attributed background colors without a separate keyword row.
private struct HighlightedConversationText: UIViewRepresentable {
    let text: String
    let terms: [String]

    func makeUIView(context: Context) -> UILabel {
        let label = UILabel()
        label.numberOfLines = 0
        label.backgroundColor = .clear
        label.lineBreakMode = .byWordWrapping
        label.isAccessibilityElement = true
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        return label
    }

    func updateUIView(_ label: UILabel, context: Context) {
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineSpacing = 6
        paragraph.alignment = .left
        paragraph.lineBreakMode = .byWordWrapping
        let attributed = NSMutableAttributedString(string: text, attributes: [
            .font: UIFont.systemFont(ofSize: 20, weight: .medium),
            .foregroundColor: UIColor(Theme.ink),
            .paragraphStyle: paragraph
        ])
        let source = text as NSString
        for term in Set(terms) where !term.isEmpty {
            var remaining = NSRange(location: 0, length: source.length)
            while remaining.length > 0 {
                let range = source.range(of: term, options: [], range: remaining)
                guard range.location != NSNotFound else { break }
                attributed.addAttribute(.backgroundColor, value: UIColor(Theme.lime.opacity(0.5)), range: range)
                let end = NSMaxRange(range)
                remaining = NSRange(location: end, length: source.length - end)
            }
        }
        label.attributedText = attributed
        label.accessibilityLabel = text
    }

    func sizeThatFits(_ proposal: ProposedViewSize, uiView: UILabel, context: Context) -> CGSize? {
        guard let width = proposal.width, width.isFinite, width > 0 else { return nil }
        let measured = uiView.sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude))
        return CGSize(width: width, height: ceil(measured.height))
    }
}

struct AddressComparison: View {
    let devices: [SceneDevice]
    let identifier: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ForEach(devices) { device in
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Image(systemName: "laptopcomputer").font(.title3)
                        Text(device.name).font(.subheadline.weight(.semibold))
                    }
                    Text(device.address)
                        .font(.system(size: 18, weight: .bold, design: .monospaced))
                        .lineLimit(1).minimumScaleFactor(0.75)
                    Text(device.prefix)
                        .font(.system(size: 26, weight: .black, design: .monospaced))
                        .padding(.horizontal, 10).padding(.vertical, 4)
                        .background(Theme.lime, in: .rect(cornerRadius: 9))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(Theme.surface, in: .rect(cornerRadius: 20))
                .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(Theme.ink.opacity(0.18), lineWidth: 1))
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(device.name)，\(device.address)，掩码 \(device.prefix)")
                .accessibilityIdentifier("\(identifier)-\(device.id)")
            }
        }
    }
}
