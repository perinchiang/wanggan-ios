import SwiftUI

struct ReviewView: View {
    @Environment(LearningStore.self) private var store
    let openLesson: (Lesson) -> Void
    let openShortReview: (Lesson) -> Void
    private var completed: [Lesson] {
        store.activeLessons.filter { store.ledger.lessons[$0.id] != nil }.sorted {
            let left = store.ledger.lessons[$0.id]!
            let right = store.ledger.lessons[$1.id]!
            if (left.lastMistakes > 0) != (right.lastMistakes > 0) { return left.lastMistakes > 0 }
            if left.nextReviewAt != right.nextReviewAt { return left.nextReviewAt < right.nextReviewAt }
            return store.orderedLessonIDs.firstIndex(of: $0.id)! < store.orderedLessonIDs.firstIndex(of: $1.id)!
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("把懂了，变成记住。").font(.title.bold())
                    Text("换个时间再判断一次，看看机制还在不在脑子里。")
                        .font(.subheadline).foregroundStyle(Theme.muted).lineSpacing(5)
                    if completed.isEmpty {
                        EmptyLearningState(title: "先去想通一个问题", detail: "完成第一节后，这里会为你安排复习。")
                    } else {
                        Surface {
                            HStack {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(store.dueLessons.isEmpty ? "今天没有到期复习" : "\(store.dueLessons.count) 节，到了回看的时候")
                                        .font(.headline)
                                    Text("首轮完成后的次日开始复习")
                                        .font(.caption).foregroundStyle(Theme.muted)
                                }
                                Spacer(); PacketMascot(size: 44)
                            }
                        }
                        ForEach(completed) { lesson in
                            if let item = store.reviewItems.first(where: { $0.lessonID == lesson.id }) {
                                Surface {
                                    VStack(alignment: .leading, spacing: 10) {
                                        Text(lesson.title).font(.headline)
                                        Text(store.ledger.evidenceStatus(for: item.knowledgePointID).rawValue)
                                            .font(.subheadline).foregroundStyle(Theme.muted)
                                        Text("约 1 分钟 · 一题判断 · 与整课共用每日 +5 XP 资格")
                                            .font(.caption).foregroundStyle(Theme.muted)
                                        PrimaryButton(title: store.ledger.shortReviewDrafts?[lesson.id] == nil ? "做一题短复习" : "继续短复习",
                                                      identifier: "short-review-\(lesson.id)") { openShortReview(lesson) }
                                    }
                                }
                            }
                            Button { openLesson(lesson) } label: {
                                Surface {
                                    HStack(spacing: 14) {
                                        Image(systemName: store.ledger.isDue(lesson.id) ? "arrow.counterclockwise.circle.fill" : "checkmark.circle")
                                            .font(.title2)
                                        VStack(alignment: .leading, spacing: 7) {
                                            Text(store.ledger.reviewDrafts?[lesson.id] == nil ? "重学整课 · \(lesson.title)" : "继续整课复习 · \(lesson.title)").font(.headline)
                                            if let progress = store.ledger.lessons[lesson.id] {
                                                Text(store.ledger.isDue(lesson.id) ? "现在复习 · 每日首次 +5 XP" : "下次复习：\(progress.nextReviewAt.formatted(date: .abbreviated, time: .omitted))")
                                                    .font(.caption).foregroundStyle(Theme.muted)
                                            }
                                        }
                                        Spacer(minLength: 0)
                                        Image(systemName: "chevron.right").font(.caption)
                                    }
                                }
                            }.buttonStyle(PressStyle()).accessibilityIdentifier("review-\(lesson.id)")
                        }
                    }
                }.padding(22)
            }.background(Theme.paper).navigationTitle("复习").navigationBarTitleDisplayMode(.inline)
        }
    }
}
