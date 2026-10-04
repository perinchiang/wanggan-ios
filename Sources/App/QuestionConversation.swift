import SwiftUI

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
                    ConversationBubble(text: message.text)
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

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            PacketMascot(size: 34).padding(.top, 10)
            Text(text)
                .font(.system(size: isQuestion ? 22 : 20, weight: isQuestion ? .bold : .medium))
                .lineSpacing(6)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(20)
                .background(isQuestion ? Theme.lime.opacity(0.24) : Theme.surface,
                            in: .rect(topLeadingRadius: 6, bottomLeadingRadius: 22, bottomTrailingRadius: 22, topTrailingRadius: 22))
        }
        .accessibilityElement(children: .combine)
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
