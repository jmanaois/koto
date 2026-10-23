import Foundation

/// Who you're chatting with. Each mode is its own conversation with its own register.
nonisolated enum ChatMode: String, CaseIterable, Identifiable {
    case friend
    case senpai
    case group
    case online
    case drill

    var id: String { rawValue }

    /// Shown in the mode menu.
    var title: String {
        switch self {
        case .friend: "友達 · Close friend"
        case .senpai: "先輩 · Senpai at work"
        case .group: "グループ · Group chat"
        case .online: "ネット · Discord / X"
        case .drill: "ドリル · Genki → real life"
        }
    }

    var systemImage: String {
        switch self {
        case .friend: "person"
        case .senpai: "person.badge.shield.checkmark"
        case .group: "person.3"
        case .online: "number"
        case .drill: "pencil.and.list.clipboard"
        }
    }

    /// The chat's name in the navigation bar.
    var chatTitle: String {
        switch self {
        case .friend: "こと"
        case .senpai: "こと先輩"
        case .group: "大学の友達 (4)"
        case .online: "こと @ Discord"
        case .drill: "ドリル"
        }
    }

    /// The group chat's members; other modes have one speaker.
    static let groupSpeakers = ["ゆい", "たくみ", "はるか"]

    /// How a bot message is labeled: its speaker in a group chat, otherwise こと.
    func persona(for speaker: String?) -> Persona {
        switch (self, speaker) {
        case (.group, "ゆい"): Persona(name: "ゆい", initial: "ゆ", color: 0xF08FAE)
        case (.group, "たくみ"): Persona(name: "たくみ", initial: "た", color: 0x5B8DEF)
        case (.group, "はるか"): Persona(name: "はるか", initial: "は", color: 0xA77BDB)
        case (.senpai, _): Persona(name: "こと先輩", initial: "こ", color: 0xE9963E)
        case (.online, _): Persona(name: "koto_", initial: "こ", color: 0x6C63FF)
        case (.drill, _): Persona(name: "こと先生", initial: "先", color: 0xE5484D)
        default: Persona(name: "こと", initial: "こ", color: 0x2BB673)
        }
    }

    /// The first messages in an empty chat.
    var welcome: [(speaker: String?, text: String)] {
        switch self {
        case .friend:
            [(nil, "やっほー！ことだよ👋\n日本語でなんでも話しかけてね。変なところがあったら直すよ！")]
        case .senpai:
            [(nil, "お疲れ〜！バイトの先輩のことだよ。\n先輩には丁寧語で話してみてね。変なところがあったら教えるよ！")]
        case .group:
            [
                ("ゆい", "やっほー！新しく入った子だよね？よろしく〜🙌"),
                ("たくみ", "よろしく。なんて呼べばいい？"),
                ("はるか", "グループへようこそ〜！気軽に話してね☺️"),
            ]
        case .online:
            [(nil, "おつ〜！ことです✌️\nここはネットのノリで話そ。草とかwとか使ってOKだよw")]
        case .drill:
            [(nil, """
            ドリルの時間だよ！✏️
            Rewrite each textbook sentence the way you'd actually text a friend. I'll check it and give you the next one.

            次：昨日、友達と映画を見に行きました。
            """)]
        }
    }
}

/// Name, avatar letter and avatar color for a bot speaker.
nonisolated struct Persona: Hashable {
    let name: String
    let initial: String
    let color: UInt32
}
