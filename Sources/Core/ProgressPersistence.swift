import Foundation

// Only persistence knows the names of removed v1 fields. No old scheduling,
// evidence or short-session types participate in the current learning model.
extension ProgressLedger {
    private enum CodingKeys: String, CodingKey {
        case schemaVersion, totalXP, lessons, activityDays, settledSessions
        case drafts, mainLessonID
        case draft, earlierDrafts, reviewDrafts
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let version = try values.decode(Int.self, forKey: .schemaVersion)
        guard version == 1 || version == 2 else {
            throw ContentError.invalid("未知进度版本")
        }
        totalXP = try values.decode(Int.self, forKey: .totalXP)
        lessons = try values.decode([String: LessonProgress].self, forKey: .lessons)
        activityDays = try values.decode([Date].self, forKey: .activityDays)
        settledSessions = try values.decode([UUID: Int].self, forKey: .settledSessions)
        if version == 2 {
            drafts = try values.decode([String: LessonSession].self, forKey: .drafts)
            mainLessonID = try values.decodeIfPresent(String.self, forKey: .mainLessonID)
        } else {
            drafts = try values.decodeIfPresent([String: LessonSession].self, forKey: .earlierDrafts) ?? [:]
            if let main = try values.decodeIfPresent(LessonSession.self, forKey: .draft) {
                drafts[main.lessonID] = main
                if lessons[main.lessonID] == nil { mainLessonID = main.lessonID }
            }
            let oldCompletedDrafts = try values.decodeIfPresent([String: LessonSession].self, forKey: .reviewDrafts) ?? [:]
            for (id, session) in oldCompletedDrafts where lessons[id] != nil {
                drafts[id] = session
            }
        }
        schemaVersion = 2
        // Deleted scheduling and short-session fields are deliberately ignored.
        // The App keeps the original v1 bytes before writing this current format.
    }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(schemaVersion, forKey: .schemaVersion)
        try values.encode(totalXP, forKey: .totalXP)
        try values.encode(lessons, forKey: .lessons)
        try values.encode(activityDays, forKey: .activityDays)
        try values.encode(settledSessions, forKey: .settledSessions)
        try values.encode(drafts, forKey: .drafts)
        try values.encodeIfPresent(mainLessonID, forKey: .mainLessonID)
    }
}
