import SwiftUI

/// One consistent first appearance for a term, protocol or networking concept.
struct TermIntroductionCard: View {
    let term: TermIntroduction
    @ScaledMetric(relativeTo: .largeTitle) private var nameSize: CGFloat = 48

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(term.name).font(.system(size: nameSize, weight: .black))
                .padding(.horizontal, 10).padding(.vertical, 4)
                .background(Theme.lime, in: .rect(cornerRadius: 8))
            Text("(\(term.englishName))").font(.title3.weight(.medium)).foregroundStyle(Theme.muted)
            Text(term.chineseName).font(.title2.weight(.bold))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(24)
        .background(Theme.surface, in: .rect(cornerRadius: 22))
        .overlay(RoundedRectangle(cornerRadius: 22).strokeBorder(Theme.ink.opacity(0.15), lineWidth: 1))
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("term-introduction-card")
    }
}
