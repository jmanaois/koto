import Foundation

/// Verb conjugation: plain forms, then the N4 forms, each drilled on verbs from every group.
/// Lesson ids are stored in progress records, so never change one.
nonisolated enum ConjugationCourse: CourseWriting {
    static let units: [CourseUnit] = [unit6]

    /// The lesson a drill question on `forms` counts toward, for mistakes and weak spots.
    static func lesson(drilling forms: [VerbForm]) -> CourseLesson {
        let id: String
        if forms.count > 1 {
            id = "conj.10"
        } else {
            switch forms.first ?? .negative {
            case .polite: id = "n5.2.1"
            case .te: id = "n5.5.1"
            case .negative: id = "conj.1"
            case .past, .pastNegative: id = "conj.2"
            case .potential: id = "conj.3"
            case .volitional: id = "conj.4"
            case .conditional: id = "conj.5"
            case .imperative: id = "conj.6"
            case .passive: id = "conj.7"
            case .causative: id = "conj.8"
            case .causativePassive: id = "conj.9"
            }
        }
        return Curriculum.lesson(id: id)!
    }

    // MARK: - Unit 6

    static let unit6 = CourseUnit(id: 6, title: "Verb conjugation", summary: "ない, た, potential, volitional, ば, imperative, passive, causative", lessons: [
        lesson(
            "conj.1", "ない-form", "plain negative: don't, won't",
            form: "る-verb: drop る + ない · う-verb: u → a + ない (う → わ) · しない · こない",
            note: "The casual negative, and the base for なければ, ないで and ないほうがいい. る-verbs drop る: 食べない. う-verbs change the last sound to the あ row: 書く → 書かない, 待つ → 待たない. Verbs ending in う use わ, not あ: 買う → 買わない. Irregular: する → しない, 来る → こない, and ある → ない (never あらない).",
            examples: [("今日は学校に行かない。", "I'm not going to school today."), ("彼はお酒を飲まないよ。", "He doesn't drink.")],
            keywords: ["negative form", "plain negative", "nai form"],
            exercises: drill(.negative, verbs: "食べる", "飲む", "書く", "買う", "待つ", "帰る", "話す", "する", "来る") + [
                pick("明日は早く＿＿から、今夜は遅くまで起きている。", "I'm not getting up early tomorrow, so I'm staying up late tonight.", "起きない", "起かない", "起きらない", "起けない"),
                pick("彼は手紙を全然＿＿。", "He never writes letters.", "書かない", "書けない", "書きない", "書くない"),
                say("My brother doesn't eat vegetables.", "弟は野菜を食べない", "兄は野菜を食べない", "弟は野菜を食べません"),
            ]
        ),
        lesson(
            "conj.2", "た-form", "plain past: did / didn't",
            form: "Same sound changes as the て-form, with た/だ · Negative: ない → なかった",
            note: "Make the て-form, then swap て → た and で → だ: 飲んで → 飲んだ, 書いて → 書いた, 行って → 行った. The past negative changes ない to なかった: 食べなかった, 行かなかった. The た-form is the base for たことがある, たら, たり and たほうがいい, so it's worth getting fast.",
            examples: [("昨日、友達と映画を見た。", "I saw a movie with a friend yesterday."), ("朝ご飯を食べなかった。", "I didn't eat breakfast.")],
            keywords: ["past tense", "plain past", "ta form"],
            exercises: drill(.past, verbs: "書く", "泳ぐ", "話す", "行く", "遊ぶ", "待つ", "見る", "来る")
                + drill(.pastNegative, verbs: "会う", "勉強する", "読む") + [
                pick("先週、初めて富士山に＿＿。", "I climbed Mt. Fuji for the first time last week.", "登った", "登んだ", "登いた", "登りた"),
                pick("駅まで＿＿けど、電車に間に合わなかった。", "I ran to the station, but didn't make the train.", "走った", "走てた", "走んだ", "走りた"),
                say("I didn't go to the party yesterday.", "昨日パーティーに行かなかった", "昨日はパーティーに行かなかった", "昨日、パーティーに行きませんでした"),
            ]
        ),
        lesson(
            "conj.3", "Potential form", "can do",
            form: "る-verb: drop る + られる · う-verb: u → e + る · できる · こられる",
            note: "The potential says what you can do: 漢字が読める. る-verbs add られる (食べられる); う-verbs change the last sound to the え row and add る (話す → 話せる). する becomes できる and 来る becomes こられる. The result is a る-verb, so 読めない, 読めた. What you can do usually takes が instead of を. In speech, る-verbs often drop ら (食べれる); it's common but still marked wrong on tests.",
            examples: [("日本語が少し話せます。", "I can speak a little Japanese."), ("辛い物は食べられない。", "I can't eat spicy food.")],
            keywords: ["potential", "can do", "られる", "ら抜き"],
            exercises: drill(.potential, verbs: "食べる", "泳ぐ", "読む", "話す", "待つ", "する", "来る")
                + [conj("書く", .potential, .negative), conj("起きる", .potential, .pastNegative)] + [
                pick("祖母はスマホが＿＿。", "My grandma can use a smartphone.", "使えます", "使われます", "使えれます", "使いれます"),
                pick("明日のパーティー、仕事で＿＿かもしれない。", "I might not be able to come to tomorrow's party because of work.", "来られない", "来れらない", "来させない", "来ない"),
                say("I couldn't sleep at all last night.", "昨日の夜は全然寝られなかった", "昨夜は全然眠れなかった", "昨日の夜、全然寝られませんでした", "昨日の夜は全然眠れなかった"),
            ]
        ),
        lesson(
            "conj.4", "Volitional form", "let's / I'll (casual)",
            form: "る-verb: drop る + よう · う-verb: u → o + う · しよう · こよう",
            note: "The casual ましょう: 行こう (let's go), 食べよう (let's eat). る-verbs add よう; う-verbs change to the お row and add う (待つ → 待とう). する → しよう, 来る → こよう. With と思う it says what you're planning: 留学しようと思っています. With とする it means trying to or being about to.",
            examples: [("そろそろ帰ろうか。", "Shall we head home soon?"), ("来年、日本に留学しようと思っています。", "I'm thinking of studying in Japan next year.")],
            keywords: ["volitional", "let's", "おう", "よう"],
            exercises: drill(.volitional, verbs: "行く", "食べる", "待つ", "休む", "帰る", "急ぐ", "する", "来る") + [
                pick("週末は家でゆっくり＿＿と思っている。", "I'm thinking of taking it easy at home this weekend.", "休もう", "休みよう", "休むよう", "休みましょう"),
                pick("A：もう十二時だね。\nB：じゃ、そろそろ＿＿か。", "A: It's already twelve. B: Well, shall we go to bed?", "寝よう", "寝ろう", "寝ろ", "寝れよう"),
                say("I'm thinking of quitting my job next year.", "来年仕事を辞めようと思っている", "来年、仕事をやめようと思っています", "来年仕事を辞めようと思っています"),
            ]
        ),
        lesson(
            "conj.5", "ば-form", "if (conditional)",
            form: "る-verb: drop る + れば · う-verb: u → e + ば · すれば · くれば · い-adj: い → ければ",
            note: "る-verbs add れば (食べれば); う-verbs change to the え row and add ば (行けば, 読めば). する → すれば, 来る → くれば. い-adjectives: 安ければ, いい → よければ. Negatives become なければ: 行かなければ. ばよかった means \"I should have\": もっと早く出ればよかった.",
            examples: [("急げば間に合うよ。", "If you hurry, you'll make it."), ("もっと勉強すればよかった。", "I should have studied more.")],
            keywords: ["conditional", "ba form", "ば"],
            exercises: drill(.conditional, verbs: "読む", "行く", "食べる", "急ぐ", "買う", "待つ", "する", "来る")
                + [
                pick("もっと早く家を＿＿よかった。", "I should have left home earlier.", "出れば", "出ば", "出るば", "出たれば"),
                pick("天気が＿＿、明日は海に行こう。", "If the weather's good, let's go to the beach tomorrow.", "よければ", "いければ", "いいれば", "よかれば"),
                say("If you ask the teacher, she'll probably tell you.", "先生に聞けば教えてくれるでしょう", "先生に聞けば教えてくれると思う", "先生に聞けば、教えてくれるよ"),
            ]
        ),
        lesson(
            "conj.6", "Imperative form", "Do it! (blunt command)",
            form: "る-verb: drop る + ろ · う-verb: u → e · しろ · こい · Don't: dictionary form + な",
            note: "The bare command. You'll hear it in sports, emergencies, signs (止まれ), quoted orders (早く寝ろと言われた) and from parents or bosses in anime, but it's rude to say to someone's face. る-verbs add ろ (起きろ); う-verbs change to the え row (急げ, 待て). する → しろ, 来る → こい. The negative command is dictionary form + な: 走るな (don't run).",
            examples: [("早く起きろ！", "Get up already!"), ("母に早く寝ろと言われた。", "My mom told me to go to bed early.")],
            keywords: ["imperative", "command", "命令形"],
            exercises: drill(.imperative, verbs: "走る", "急ぐ", "起きる", "見る", "待つ", "飲む", "する", "来る") + [
                pick("道路の標識に「＿＿」と書いてある。", "The road sign says \"Stop.\"", "止まれ", "止まろ", "止まりろ", "止めれ"),
                pick("コーチに「もっと速く＿＿！」と言われた。", "The coach yelled at me, \"Run faster!\"", "走れ", "走ろ", "走りろ", "走るな"),
                say("My father told me not to come home late.", "父に遅く帰るなと言われた", "父に遅く帰ってくるなと言われた", "父は遅く帰るなと言った"),
            ]
        ),
        lesson(
            "conj.7", "Passive form", "is done (to someone)",
            form: "る-verb: drop る + られる · う-verb: u → a + れる (う → わ) · される · こられる",
            note: "る-verbs add られる, which looks just like the potential: 食べられる. う-verbs change to the あ row and add れる: 読む → 読まれる, 言う → 言われる. する → される, 来る → こられる. The result is a る-verb: 呼ばれた, 言われなかった. Don't confuse 話される (passive) with 話せる (potential).",
            examples: [("先生にほめられた。", "I was praised by the teacher."), ("この本は世界中で読まれています。", "This book is read all over the world.")],
            keywords: ["passive", "受身", "られる"],
            exercises: drill(.passive, verbs: "読む", "言う", "書く", "食べる", "呼ぶ", "見る", "する", "来る")
                + [conj("使う", .passive, .past), conj("送る", .passive, .pastNegative)] + [
                pick("電車の中で足を＿＿。", "Someone stepped on my foot on the train.", "踏まれた", "踏めた", "踏ませた", "踏まられた"),
                pick("このお寺は八百年前に＿＿そうだ。", "I hear this temple was built 800 years ago.", "建てられた", "建たれた", "建てれた", "建てさせた"),
                say("I was scolded by my boss this morning.", "今朝上司に叱られた", "今朝、上司に怒られた", "今朝上司に怒られました", "今朝、部長に叱られた"),
            ]
        ),
        lesson(
            "conj.8", "Causative form", "make / let someone do",
            form: "る-verb: drop る + させる · う-verb: u → a + せる (う → わ) · させる · こさせる",
            note: "The causative means make or let someone do something: 子供に野菜を食べさせる. る-verbs add させる; う-verbs change to the あ row and add せる (待つ → 待たせる, 手伝う → 手伝わせる). する → させる, 来る → こさせる. Context decides make vs. let; with てください or てもらう it's almost always let: 休ませてください.",
            examples: [("お待たせしました。", "Sorry to have kept you waiting."), ("母は私に部屋を掃除させた。", "My mom made me clean my room.")],
            keywords: ["causative", "使役", "させる"],
            exercises: drill(.causative, verbs: "飲む", "行く", "待つ", "食べる", "話す", "手伝う", "する", "来る")
                + [conj("休む", .causative, .te), conj("遊ぶ", .causative, .pastNegative)] + [
                pick("ちょっと考え＿＿ください。", "Please let me think about it a bit.", "させて", "られて", "させられて", "させって"),
                pick("先生は学生に毎日日記を＿＿。", "The teacher has the students write a diary every day.", "書かせる", "書かれる", "書けさせる", "書かさせる"),
                say("My parents let me study abroad in Japan.", "両親は私を日本に留学させてくれた", "両親が日本に留学させてくれた", "親は私を日本に留学させてくれました"),
            ]
        ),
        lesson(
            "conj.9", "Causative-passive form", "be made to do",
            form: "Causative + passive: る-verb + させられる · う-verb: u → a + せられる or される · させられる · こさせられる",
            note: "Being made to do something you didn't want to: 飲まされた (I was made to drink). It's the causative (飲ませる) made passive (飲ませられる). Most う-verbs also have a short form, a + される (飲まされる), which is what you'll usually hear. Verbs ending in す can't shorten: 話させられる only. The person making you do it takes に.",
            examples: [("子供のころ、ピアノを習わされた。", "As a kid, I was made to take piano lessons."), ("部長に一時間も待たされた。", "My manager kept me waiting a whole hour.")],
            keywords: ["causative passive", "使役受身", "させられる"],
            exercises: drill(.causativePassive, verbs: "飲む", "待つ", "食べる", "書く", "話す", "歌う", "する", "来る")
                + [
                pick("飲み会で先輩にお酒を＿＿。", "At the drinking party, my senior made me drink.", "飲まされた", "飲ませた", "飲まれた", "飲めさせた"),
                pick("子供のころ、毎日野菜を＿＿のが嫌だった。", "As a kid, I hated being made to eat vegetables every day.", "食べさせられる", "食べられさせる", "食べさせる", "食べさられる"),
                say("I was made to write the report again by my boss.", "上司にレポートをもう一度書かされた", "上司にレポートをもう一度書かせられた", "上司にレポートを書き直させられた"),
            ]
        ),
        lesson(
            "conj.10", "Conjugation mix", "chained forms: can't, was made to, wasn't...",
            form: "Derived form (a る-verb) → then ない, た, なかった, ます or て",
            note: "Potential, passive, causative and causative-passive all make a new る-verb, so they conjugate again like 食べる: 泳げる → 泳げない, 呼ばれる → 呼ばれなかった, 休ませる → 休ませて. Build the first form, then treat it as a る-verb. This is how real sentences pile up meaning: 行かせてもらえなかった (I wasn't allowed to go).",
            examples: [("昔は全然泳げなかった。", "I couldn't swim at all before."), ("誰にも呼ばれなかった。", "Nobody called me.")],
            keywords: ["conjugation", "verb forms"],
            exercises: [
                conj("泳ぐ", .potential, .negative),
                conj("呼ぶ", .passive, .pastNegative),
                conj("休む", .causative, .te),
                conj("歌う", .causativePassive, .past),
                conj("来る", .potential, .past),
                conj("言う", .passive, .polite),
                conj("遊ぶ", .causative, .pastNegative),
                conj("運転する", .potential, .pastNegative),
                conj("忘れる", .passive, .te),
                pick("子供のころは、夜一人で外に＿＿。", "As a kid, I wasn't allowed to go out alone at night.", "行かせてもらえなかった", "行かされてもらえなかった", "行けさせてもらわなかった", "行かせられてもらえなかった"),
            ]
        ),
    ], level: "N4")
}
