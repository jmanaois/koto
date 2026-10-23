import Foundation

/// The N5 grammar course, in roughly Genki I order. Lesson ids are stored in progress records,
/// so never change one; add new lessons with new ids.
nonisolated enum N5Course {
    static let units: [CourseUnit] = [unit1, unit2, unit3, unit4, unit5]

    // MARK: - Unit 1

    static let unit1 = CourseUnit(id: 1, title: "The basics", summary: "は, です, questions, の, this/that, も", lessons: [
        lesson(
            "n5.1.1", "〜は〜です", "X is Y",
            form: "Topic + は + Noun + です",
            note: "は (said \"wa\") marks the topic: what you're talking about. です ends a polite sentence, like \"is / am / are\". With friends it becomes だ or just drops.",
            examples: [("私は学生です。", "I'm a student."), ("田中さんは先生です。", "Mr. Tanaka is a teacher.")],
            keywords: ["topic particle", "です"],
            pick("私＿＿学生です。", "I'm a student.", "は", "を", "に"),
            pick("メアリーさんはアメリカ人＿＿。", "Mary is American.", "です", "ます", "か"),
            build("Takeshi is a college student.", "たけしさん/t は/t 大学生/v です。/v", extra: "を"),
            build("My major is Japanese.", "私の/d 専攻/t は/t 日本語/v です。/v", extra: "が"),
            say("I'm Japanese.", "私は日本人です", "日本人です", "僕は日本人です")
        ),
        lesson(
            "n5.1.2", "〜か", "Turns a sentence into a question",
            form: "Sentence + か",
            note: "Add か to the end of a polite sentence to ask a question. The word order doesn't change. Question words (なん, だれ, どこ) go where the answer would go. With friends, drop the か and just raise your voice.",
            examples: [("学生ですか。", "Are you a student?"), ("それはなんですか。", "What is that?")],
            keywords: ["question"],
            pick("ロバートさんはイギリス人です＿＿。", "Is Robert British?", "か", "は", "の"),
            pick("専攻は＿＿ですか。", "What's your major?", "なん", "だれ", "どこ"),
            build("Where is the bathroom?", "トイレ/t は/t どこ/v です/v か。/e", extra: "を"),
            build("Who is that person?", "あの/d 人/t は/t だれ/v です/v か。/e"),
            say("Are you a teacher?", "先生ですか", "あなたは先生ですか")
        ),
        lesson(
            "n5.1.3", "〜の", "'s / of: links two nouns",
            form: "Noun + の + Noun",
            note: "A の B means a B that belongs to or is described by A: 私の本 (my book), 日本語の先生 (a Japanese teacher), 大学の学生 (a student at the university). The main noun comes last.",
            examples: [("これは私の傘です。", "This is my umbrella."), ("山下先生は日本語の先生です。", "Professor Yamashita is a Japanese teacher.")],
            keywords: ["particle の", "possessive"],
            pick("これはメアリーさん＿＿本です。", "This is Mary's book.", "の", "は", "を"),
            pick("たけしさんは東京大学＿＿学生です。", "Takeshi is a student at Tokyo University.", "の", "に", "で"),
            build("That is my friend's bag.", "それ/t は/t 友達/d の/d かばん/v です。/v", extra: "を"),
            build("This is a Japanese book.", "これ/t は/t 日本語/d の/d 本/v です。/v"),
            say("It's my umbrella.", "私の傘です", "これは私の傘です", "僕の傘です")
        ),
        lesson(
            "n5.1.4", "これ／この", "this / that / that over there",
            form: "これ・それ・あれ alone, この・その・あの + Noun",
            note: "これ・それ・あれ stand alone (\"this one\"). この・その・あの must come right before a noun (\"this book\"). こ = near me, そ = near you, あ = far from both of us. どれ / どの ask \"which\".",
            examples: [("これはいくらですか。", "How much is this?"), ("その本はだれのですか。", "Whose book is that?")],
            keywords: ["これ", "この", "demonstrative"],
            pick("＿＿本は私のです。", "This book is mine.", "この", "これ", "ここ"),
            pick("＿＿はいくらですか。", "How much is that (near you)?", "それ", "その", "そこ"),
            pick("＿＿人は先生です。", "That person over there is a teacher.", "あの", "あれ", "あそこ"),
            build("How much is this watch?", "この/d 時計/t は/t いくら/v です/v か。/e", extra: "これ"),
            say("What is this?", "これはなんですか", "これは何ですか", "これなんですか")
        ),
        lesson(
            "n5.1.5", "〜も", "too / also",
            form: "Noun + も (instead of は, が or を)",
            note: "も replaces は (or が, を) to say \"also\": 私も学生です (I'm a student too). With a negative it means \"not ... either\".",
            examples: [("私も日本人です。", "I'm Japanese too."), ("たけしさんも二年生です。", "Takeshi is a sophomore too.")],
            keywords: ["particle も"],
            pick("メアリーさんは学生です。ロバートさん＿＿学生です。", "Mary is a student. Robert is a student too.", "も", "は", "の"),
            pick("この傘＿＿五百円です。", "This umbrella is also 500 yen.", "も", "を", "に"),
            build("My friend is also a teacher.", "私の/d 友達/t も/t 先生/v です。/v", extra: "は"),
            build("That is mine too.", "それ/t も/t 私の/v です。/v", extra: "を"),
            say("I'm a student too.", "私も学生です", "僕も学生です")
        ),
        lesson(
            "n5.1.6", "〜じゃないです", "is not",
            form: "Noun + じゃないです",
            note: "The negative of です after a noun. じゃありません is a bit more formal and ではありません is for writing. With friends: じゃない.",
            examples: [("私は先生じゃないです。", "I'm not a teacher."), ("これは私の傘じゃないです。", "This isn't my umbrella.")],
            keywords: ["negative", "じゃない"],
            pick("たけしさんは留学生＿＿。", "Takeshi isn't an international student.", "じゃないです", "です", "くないです"),
            pick("A：日本人ですか。\nB：いいえ、日本人＿＿。", "A: Are you Japanese? B: No, I'm not.", "じゃないです", "です", "ですか"),
            build("That isn't my bag.", "それ/t は/t 私の/d かばん/v じゃないです。/v", extra: "くない"),
            build("I'm not a second-year student.", "私/t は/t 二年生/v じゃないです。/v", extra: "の"),
            say("It's not my umbrella.", "私の傘じゃないです", "私の傘じゃありません", "私の傘ではありません")
        ),
    ])

    // MARK: - Unit 2

    static let unit2 = CourseUnit(id: 2, title: "Verbs and particles", summary: "ます, を, で, に・へ, time に, ませんか", lessons: [
        lesson(
            "n5.2.1", "〜ます／ません", "do, will do / don't, won't (polite)",
            form: "Verb stem + ます / ません",
            note: "The ます form is present and future: 行きます = I go / I'll go. Negative: ません. る-verbs drop る (食べる → 食べます). う-verbs change the last u to i (飲む → 飲みます). Irregular: する → します, 来る → 来ます.",
            examples: [("毎日日本語を勉強します。", "I study Japanese every day."), ("私はお酒を飲みません。", "I don't drink alcohol.")],
            keywords: ["ます form", "masu", "verb conjugation", "polite form"],
            pick("明日、学校に＿＿。", "I'll go to school tomorrow.", "行きます", "行きません", "行きました"),
            pick("私はテレビを＿＿。", "I don't watch TV.", "見ません", "見ます", "見ましょう"),
            pick("食べる → ＿＿", "The ます form of 食べる (eat)", "食べます", "食べります", "食べみます"),
            pick("飲む → ＿＿", "The ます form of 飲む (drink)", "飲みます", "飲むます", "飲めます"),
            build("I'll do homework tonight.", "今晩/tm 宿題/o を/o します。/v", extra: "に"),
            say("I don't eat meat.", "肉を食べません", "私は肉を食べません")
        ),
        lesson(
            "n5.2.2", "〜を", "marks what the action is done to",
            form: "Object + を + Verb",
            note: "を (said \"o\") comes after the direct object: what you eat, drink, watch or read. With friends it's often dropped: コーヒー飲む？",
            examples: [("コーヒーを飲みます。", "I drink coffee."), ("本を読みます。", "I read books.")],
            keywords: ["particle を", "object particle"],
            pick("音楽＿＿聞きます。", "I listen to music.", "を", "に", "で"),
            pick("毎朝、新聞＿＿読みます。", "I read the newspaper every morning.", "を", "へ", "で"),
            build("I watch movies on weekends.", "週末/tm に/tm 映画/o を/o 見ます。/v", extra: "で"),
            build("Takeshi drinks coffee.", "たけしさん/t は/t コーヒー/o を/o 飲みます。/v"),
            say("I eat breakfast.", "朝ご飯を食べます", "朝ごはんを食べます")
        ),
        lesson(
            "n5.2.3", "〜で", "at / in (where you do something), by / with (means)",
            form: "Place + で + Verb, Tool + で + Verb",
            note: "で marks where an action happens (図書館で勉強します) and the tool or means (バスで行きます, 日本語で話します). For where something simply is, use に instead.",
            examples: [("図書館で勉強します。", "I study at the library."), ("バスで学校に行きます。", "I go to school by bus.")],
            keywords: ["particle で", "で vs に", "に vs で"],
            pick("家＿＿テレビを見ます。", "I watch TV at home.", "で", "に", "を"),
            pick("はし＿＿食べます。", "I eat with chopsticks.", "で", "を", "に"),
            build("I eat lunch at the cafeteria.", "食堂/p で/p 昼ご飯/o を/o 食べます。/v", extra: "に"),
            build("I'll study at the library tomorrow.", "明日/tm 図書館/p で/p 勉強します。/v", extra: "に"),
            say("I go by bus.", "バスで行きます")
        ),
        lesson(
            "n5.2.4", "〜に／へ行く", "to (where you go, come or return)",
            form: "Place + に / へ + 行きます・来ます・帰ります",
            note: "With 行く, 来る and 帰る, に or へ marks where you're headed: 学校に行きます. へ is said \"e\". Don't use で here: で is for where you do something.",
            examples: [("日本に行きます。", "I'll go to Japan."), ("家へ帰ります。", "I go back home.")],
            keywords: ["destination", "particle へ", "particle に"],
            pick("明日、京都＿＿行きます。", "I'll go to Kyoto tomorrow.", "に", "で", "を"),
            pick("毎日、大学＿＿来ます。", "I come to the university every day.", "へ", "で", "の"),
            pick("どこ＿＿行きますか。", "Where are you going?", "に", "で", "を"),
            build("Mary goes back to America.", "メアリーさん/t は/t アメリカ/g に/g 帰ります。/v", extra: "で"),
            say("I'll go to the library.", "図書館に行きます", "図書館へ行きます")
        ),
        lesson(
            "n5.2.5", "〜に (time)", "at / on (a specific time or day)",
            form: "Time + に + Verb",
            note: "Use に after clock times, days of the week and dates: 三時に, 日曜日に. No に after relative words like 今日, 明日, 毎日 or 今晩. 週末 works either way.",
            examples: [("七時に起きます。", "I get up at seven."), ("土曜日に映画を見ます。", "I'll see a movie on Saturday.")],
            keywords: ["time particle", "time expression"],
            pick("十一時＿＿寝ます。", "I go to bed at eleven.", "に", "で", "を"),
            pick("明日＿＿テニスをします。", "I'll play tennis tomorrow.", Exercise.nothing, "に", "で"),
            build("I'll go to Tokyo on Sunday.", "日曜日/tm に/tm 東京/g に/g 行きます。/v", extra: "で"),
            build("What time do you get up?", "何時/tm に/tm 起きます/v か。/e", extra: "で"),
            say("I eat dinner at seven.", "七時に晩ご飯を食べます", "七時に晩ごはんを食べます", "7時に晩ご飯を食べます")
        ),
        lesson(
            "n5.2.6", "〜ませんか", "Would you like to...? (invitation)",
            form: "Verb stem + ませんか",
            note: "A polite invitation. Asking in the negative (ませんか) sounds softer than ますか. Say yes with いいですね; say no gently with ちょっと…. With friends: 〜ない？",
            examples: [("一緒に昼ご飯を食べませんか。", "Would you like to have lunch together?"), ("土曜日に映画を見ませんか。", "How about seeing a movie on Saturday?")],
            keywords: ["invitation"],
            pick("一緒にコーヒーを＿＿。", "Would you like to have coffee together?", "飲みませんか", "飲みません", "飲みますか"),
            pick("A：映画を見ませんか。\nB：＿＿。いつ見ますか。", "A: Want to see a movie? B: Sounds good. When?", "いいですね", "ちょっと…", "いいえ、見ません"),
            build("Would you like to play tennis tomorrow?", "明日/tm テニス/o を/o しません/v か。/e", extra: "で"),
            build("Won't you come to my house?", "私の/d 家/g に/g 来ません/v か。/e"),
            say("Would you like to go to Kyoto together?", "一緒に京都に行きませんか", "一緒に京都へ行きませんか")
        ),
    ])

    // MARK: - Unit 3

    static let unit3 = CourseUnit(id: 3, title: "Things and descriptions", summary: "あります／います, positions, adjectives, 好き", lessons: [
        lesson(
            "n5.3.1", "あります／います", "there is / have (things vs. people and animals)",
            form: "Place + に + Noun + が + あります・います",
            note: "あります is for things and plants; います is for people and animals. What exists takes が. あります also means \"have\": テストがあります (I have a test).",
            examples: [("あそこに銀行があります。", "There's a bank over there."), ("公園に子供がいます。", "There are children in the park.")],
            keywords: ["ある", "いる", "existence"],
            pick("あそこに猫が＿＿。", "There's a cat over there.", "います", "あります", "です"),
            pick("明日、テストが＿＿。", "I have a test tomorrow.", "あります", "います", "します"),
            pick("この町に大学＿＿あります。", "There's a university in this town.", "が", "を", "で"),
            build("There's a park in my town.", "私の/d 町/p に/p 公園/s が/s あります。/v", extra: "で"),
            build("I have a little brother.", "私/t は/t 弟/s が/s います。/v", extra: "あります。"),
            say("There's a dog.", "犬がいます")
        ),
        lesson(
            "n5.3.2", "〜の上／中／となり", "on / in / next to (where something is)",
            form: "Noun + の + 上・中・となり… + に",
            note: "Position words are nouns, so they join with の: 机の上 (on the desk), かばんの中 (in the bag). Others: 下 (under), 前 (in front), 後ろ (behind), となり (next to), 近く (near). Then add に + あります/います, or just です.",
            examples: [("本は机の上にあります。", "The book is on the desk."), ("銀行は郵便局のとなりです。", "The bank is next to the post office.")],
            keywords: ["location", "position"],
            pick("傘はドアの＿＿にあります。", "The umbrella is behind the door.", "後ろ", "前", "上"),
            pick("かばんの＿＿に財布があります。", "There's a wallet in the bag.", "中", "上", "下"),
            pick("猫はいすの下＿＿います。", "The cat is under the chair.", "に", "で", "を"),
            build("The library is next to the bank.", "図書館/t は/t 銀行/d の/d となり/v です。/v", extra: "に"),
            build("There's a convenience store near the station.", "駅/d の/d 近く/p に/p コンビニ/s が/s あります。/v", extra: "で"),
            say("My bag is under the desk.", "私のかばんは机の下にあります", "かばんは机の下にあります", "私のかばんは机の下です")
        ),
        lesson(
            "n5.3.3", "い-adjectives", "describing words that end in い",
            form: "高い + Noun, 高いです, 高くないです",
            note: "They end in い and go straight before a noun (高い本) or before です (高いです). Negative: change the い to くない (高くないです). いい is irregular: よくないです.",
            examples: [("この本はおもしろいです。", "This book is interesting."), ("今日は寒くないです。", "It isn't cold today.")],
            keywords: ["i-adjective", "い adjective", "adjective"],
            pick("このカレーは＿＿。", "This curry isn't spicy.", "からくないです", "からいじゃないです", "からいないです"),
            pick("あの映画は＿＿です。", "That movie isn't good.", "よくない", "いくない", "いいじゃない"),
            pick("＿＿かばんですね。", "What a big bag!", "大きい", "大きいな", "大きいの"),
            build("Japanese is not difficult.", "日本語/t は/t 難しく/v ないです。/v", extra: "じゃ"),
            build("It's a very old temple.", "とても/d 古い/d お寺/v です。/v", extra: "な"),
            say("It's not expensive.", "高くないです", "高くありません")
        ),
        lesson(
            "n5.3.4", "な-adjectives", "describing words that take な before a noun",
            form: "静かな + Noun, 静かです, 静かじゃないです",
            note: "They need な before a noun (きれいな部屋) but not before です (きれいです). The negative is じゃないです, like a noun. Watch out: きれい and きらい end in い but are な-adjectives.",
            examples: [("静かな町ですね。", "It's a quiet town, isn't it?"), ("この部屋はきれいじゃないです。", "This room isn't clean.")],
            keywords: ["na-adjective", "な adjective", "adjective"],
            pick("ここは＿＿町です。", "This is a lively town.", "にぎやかな", "にぎやか", "にぎやかい"),
            pick("この部屋は＿＿。", "This room isn't clean.", "きれいじゃないです", "きれくないです", "きれいくないです"),
            pick("メアリーさんは＿＿です。", "Mary is energetic.", "元気", "元気な", "元気い"),
            build("Kyoto is a beautiful city.", "京都/t は/t きれいな/d 町/v です。/v", extra: "きれい"),
            build("I'm not free tomorrow.", "明日/t は/t ひま/v じゃないです。/v", extra: "くない"),
            say("It's a quiet room.", "静かな部屋です")
        ),
        lesson(
            "n5.3.5", "〜が好きです", "like / dislike",
            form: "Noun + が + 好きです・きらいです",
            note: "What you like takes が, not を: 音楽が好きです. 大好き = really like; きらい = dislike. Both are な-adjectives, so: 好きな食べ物 (favorite food), 好きじゃないです (don't like).",
            examples: [("私は日本の映画が好きです。", "I like Japanese movies."), ("魚があまり好きじゃないです。", "I don't really like fish.")],
            keywords: ["好き", "きらい", "suki"],
            pick("私はスポーツ＿＿好きです。", "I like sports.", "が", "を", "に"),
            pick("＿＿食べ物はなんですか。", "What's your favorite food?", "好きな", "好き", "好きの"),
            build("I really love cats.", "私/t は/t 猫/s が/s 大好きです。/v", extra: "を"),
            build("I don't like vegetables much.", "野菜/s が/s あまり/d 好きじゃないです。/v", extra: "を"),
            say("I like music.", "音楽が好きです", "私は音楽が好きです")
        ),
    ])

    // MARK: - Unit 4

    static let unit4 = CourseUnit(id: 4, title: "Past tense and connecting", summary: "ました, adjective past, と, ましょう, から", lessons: [
        lesson(
            "n5.4.1", "〜ました／ませんでした", "did / didn't (polite past)",
            form: "Verb stem + ました / ませんでした",
            note: "The past of ます is ました, and the past negative is ませんでした: 昨日映画を見ました (I saw a movie yesterday).",
            examples: [("昨日、友達に会いました。", "I met a friend yesterday."), ("週末は勉強しませんでした。", "I didn't study over the weekend.")],
            keywords: ["past tense", "ました"],
            pick("昨日、映画を＿＿。", "I watched a movie yesterday.", "見ました", "見ます", "見ませんでした"),
            pick("今朝、朝ご飯を＿＿。", "I didn't eat breakfast this morning.", "食べませんでした", "食べないでした", "食べませんだった"),
            build("I went to Osaka last week.", "先週/tm 大阪/g に/g 行きました。/v", extra: "で"),
            build("What did you do on the weekend?", "週末/tm に/tm 何/o を/o しました/v か。/e", extra: "で"),
            say("I didn't sleep.", "寝ませんでした")
        ),
        lesson(
            "n5.4.2", "〜かったです／でした", "was (adjectives and nouns, polite past)",
            form: "高かったです, 静かでした, 学生でした",
            note: "い-adjectives: 高い → 高かったです, negative 高くなかったです. いい → よかったです. な-adjectives and nouns: 静かでした, negative 静かじゃなかったです. Never 高いでした.",
            examples: [("旅行は楽しかったです。", "The trip was fun."), ("昨日はひまでした。", "I was free yesterday.")],
            keywords: ["adjective past", "past tense of adjective", "かった"],
            pick("テストは＿＿。", "The test was difficult.", "難しかったです", "難しいでした", "難しでした"),
            pick("天気は＿＿。", "The weather was good.", "よかったです", "いかったです", "いいでした"),
            pick("町は＿＿。", "The town was quiet.", "静かでした", "静かかったです", "静かいでした"),
            build("The movie wasn't interesting.", "映画/t は/t おもしろく/v なかったです。/v", extra: "じゃ"),
            say("It was fun.", "楽しかったです")
        ),
        lesson(
            "n5.4.3", "〜と", "and (between nouns) / with (someone)",
            form: "Noun + と + Noun, Person + と + Verb",
            note: "と joins nouns in a full list: パンとコーヒー. After a person it means \"together with\": 友達と行きました. Don't use と to join sentences or adjectives.",
            examples: [("肉と野菜を買いました。", "I bought meat and vegetables."), ("母と電話で話しました。", "I talked with my mom on the phone.")],
            keywords: ["particle と"],
            pick("昨日、友達＿＿映画を見ました。", "I watched a movie with a friend yesterday.", "と", "に", "を"),
            pick("ペン＿＿ノートがあります。", "There's a pen and a notebook.", "と", "も", "の"),
            build("I studied with Takeshi at the library.", "図書館/p で/p たけしさん/g と/g 勉強しました。/v", extra: "に"),
            build("I like dogs and cats.", "犬/s と/s 猫/s が/s 好きです。/v", extra: "を"),
            say("I went with my friend.", "友達と行きました")
        ),
        lesson(
            "n5.4.4", "〜ましょう", "Let's... / Shall we...? / Shall I...?",
            form: "Verb stem + ましょう / ましょうか",
            note: "ましょう suggests doing something together (行きましょう, let's go). ましょうか asks \"shall we?\" or offers help (持ちましょうか, shall I carry it?). With friends: 行こう.",
            examples: [("一緒に勉強しましょう。", "Let's study together."), ("窓を開けましょうか。", "Shall I open the window?")],
            keywords: ["volitional", "let's"],
            pick("じゃあ、駅で＿＿。", "Well then, let's meet at the station.", "会いましょう", "会いました", "会いませんでした"),
            pick("荷物を＿＿。", "Shall I carry your bags?", "持ちましょうか", "持ちますか", "持ちましたか"),
            build("Let's eat lunch at the cafeteria.", "食堂/p で/p 昼ご飯/o を/o 食べましょう。/v", extra: "に"),
            build("What shall we do tomorrow?", "明日/tm 何/o を/o しましょう/v か。/e", extra: "で"),
            say("Let's go.", "行きましょう")
        ),
        lesson(
            "n5.4.5", "〜から", "because / so",
            form: "Reason + から、Result",
            note: "から comes right after the reason: 寒いですから、窓を閉めます (it's cold, so I'll close the window). Reason first, result second. To answer どうして (why), the reason + から alone is enough.",
            examples: [("明日はテストがありますから、勉強します。", "I have a test tomorrow, so I'll study."), ("暑かったですから、海に行きました。", "It was hot, so we went to the beach.")],
            keywords: ["because", "reason"],
            pick("お金がありません＿＿、買いません。", "I don't have money, so I won't buy it.", "から", "が", "と"),
            pick("A：どうして来ませんでしたか。\nB：ちょっと忙しかったです＿＿。", "A: Why didn't you come? B: Because I was a bit busy.", "から", "まで", "の"),
            build("It's cheap, so I'll buy this.", "安いです/v から、/c これ/o を/o 買います。/v", extra: "が"),
            build("I was tired, so I went to bed early.", "疲れました/v から、/c 早く/d 寝ました。/v", extra: "と"),
            say("Because I'm busy.", "忙しいですから", "忙しいから")
        ),
    ])

    // MARK: - Unit 5

    static let unit5 = CourseUnit(id: 5, title: "The て-form", summary: "Making it, ください, もいい, はいけない, ている, linking", lessons: [
        lesson(
            "n5.5.1", "て-form", "the linking form of verbs",
            form: "う・つ・る → って, む・ぶ・ぬ → んで, く → いて, ぐ → いで, す → して",
            note: "る-verbs: drop る and add て (食べて). う-verbs go by their last sound: 買う・待つ・帰る → 買って・待って・帰って; 飲む・遊ぶ → 飲んで・遊んで; 書く → 書いて; 泳ぐ → 泳いで; 話す → 話して. Irregular: する → して, 来る → 来て, and 行く → 行って.",
            examples: [("ちょっと待って。", "Wait a sec."), ("手紙を書いて、送りました。", "I wrote a letter and sent it.")],
            keywords: ["te-form", "て form", "te form"],
            pick("飲む → ＿＿", "The て-form of 飲む (drink)", "飲んで", "飲みて", "飲って"),
            pick("書く → ＿＿", "The て-form of 書く (write)", "書いて", "書って", "書きて"),
            pick("行く → ＿＿", "The て-form of 行く (go)", "行って", "行いて", "行きて"),
            pick("話す → ＿＿", "The て-form of 話す (talk)", "話して", "話って", "話いて"),
            pick("待つ → ＿＿", "The て-form of 待つ (wait)", "待って", "待ちて", "待んで"),
            pick("泳ぐ → ＿＿", "The て-form of 泳ぐ (swim)", "泳いで", "泳いて", "泳って"),
            pick("帰る → ＿＿", "The て-form of 帰る (go home). Careful: it's an う-verb.", "帰って", "帰て", "帰りて"),
            pick("くる → ＿＿", "The て-form of 来る (come)", "きて", "くって", "こて")
        ),
        lesson(
            "n5.5.2", "〜てください", "Please do...",
            form: "て-form + ください",
            note: "A polite request: ここに名前を書いてください. With friends, the て-form alone (書いて) or 〜てくれる？",
            examples: [("もう一度言ってください。", "Please say it one more time."), ("ちょっと待ってください。", "Please wait a moment.")],
            keywords: ["request", "ください"],
            pick("ゆっくり＿＿ください。", "Please speak slowly.", "話して", "話し", "話す"),
            pick("この本を＿＿ください。", "Please read this book.", "読んで", "読みて", "読って"),
            build("Please write your name here.", "ここ/p に/p 名前/o を/o 書いて/v ください。/v", extra: "で"),
            build("Please show me your passport.", "パスポート/o を/o 見せて/v ください。/v", extra: "に"),
            say("Please wait.", "待ってください", "ちょっと待ってください")
        ),
        lesson(
            "n5.5.3", "〜てもいいです", "You may... / It's OK to...",
            form: "て-form + もいいです(か)",
            note: "Gives permission; add か to ask for it: 写真を撮ってもいいですか (may I take a picture?). With friends: 〜てもいい？",
            examples: [("ここで写真を撮ってもいいですか。", "May I take pictures here?"), ("窓を開けてもいいですよ。", "You can open the window.")],
            keywords: ["permission", "てもいい"],
            pick("トイレに＿＿もいいですか。", "May I go to the bathroom?", "行って", "行き", "行く"),
            pick("この辞書を＿＿もいいですか。", "May I use this dictionary?", "使って", "使いて", "使んで"),
            build("May I sit here?", "ここ/p に/p 座って/v も/v いいです/v か。/e", extra: "で"),
            build("You can eat this cake.", "この/d ケーキ/o を/o 食べて/v も/v いいですよ。/v", extra: "は"),
            say("May I go home?", "帰ってもいいですか", "家に帰ってもいいですか")
        ),
        lesson(
            "n5.5.4", "〜てはいけません", "You must not...",
            form: "て-form + はいけません",
            note: "Says something isn't allowed: ここでたばこを吸ってはいけません. With friends: 〜ちゃだめ.",
            examples: [("教室で食べてはいけません。", "You must not eat in the classroom."), ("美術館で写真を撮ってはいけません。", "You must not take pictures in the museum.")],
            keywords: ["prohibition", "てはいけない"],
            pick("ここでたばこを＿＿はいけません。", "You must not smoke here.", "吸って", "吸い", "吸う"),
            pick("A：ここで泳いでもいいですか。\nB：いいえ、泳いで＿＿。", "A: May I swim here? B: No, you must not.", "はいけません", "もいいです", "ください"),
            build("You must not sleep in class.", "授業中/tm に/tm 寝て/v は/v いけません。/v", extra: "も"),
            build("You must not speak English in this class.", "この/d クラス/p で/p 英語/o を/o 話して/v は/v いけません。/v", extra: "に"),
            say("You must not drink alcohol.", "お酒を飲んではいけません")
        ),
        lesson(
            "n5.5.5", "〜ている", "is doing (right now) / is in a state",
            form: "て-form + います",
            note: "て-form + いる is an action in progress: 今、勉強しています. It's also an ongoing state: 東京に住んでいます (live in Tokyo), 結婚しています (am married), 知っています (know). With friends: 〜てる.",
            examples: [("今、雨が降っています。", "It's raining now."), ("姉は東京に住んでいます。", "My older sister lives in Tokyo.")],
            keywords: ["ている", "progressive", "te-iru"],
            pick("今、何を＿＿か。", "What are you doing now?", "しています", "します", "しました"),
            pick("父は銀行で＿＿。", "My father works at a bank.", "働いています", "働いでいます", "働きています"),
            pick("たけしさんを＿＿か。", "Do you know Takeshi?", "知っています", "知ります", "知っていません"),
            build("My sister is reading a book now.", "妹/t は/t 今/tm 本/o を/o 読んでいます。/v", extra: "読みています"),
            say("I'm studying Japanese.", "日本語を勉強しています", "日本語を勉強してます")
        ),
        lesson(
            "n5.5.6", "〜て、〜", "and (then): joins actions and descriptions",
            form: "て-form, next verb (last verb sets the tense)",
            note: "Join actions with the て-form in the order they happen; the last verb decides the tense: 朝ご飯を食べて、学校に行きました. It joins adjectives too: 安くておいしい (cheap and tasty), 静かできれい (quiet and pretty).",
            examples: [("家に帰って、晩ご飯を食べました。", "I went home and ate dinner."), ("この店は安くておいしいです。", "This place is cheap and good.")],
            keywords: ["linking", "sequence", "くて"],
            pick("シャワーを＿＿、寝ました。", "I took a shower and went to bed.", "浴びて", "浴びた", "浴びます"),
            pick("この部屋は＿＿広いです。", "This room is clean and spacious.", "きれいで", "きれいて", "きれくて"),
            pick("このカレーは＿＿おいしいです。", "This curry is cheap and tasty.", "安くて", "安いで", "安いて"),
            build("I went to Kyoto and saw temples.", "京都/g に/g 行って、/v お寺/o を/o 見ました。/v", extra: "見て"),
            say("I got up and ate breakfast.", "起きて、朝ご飯を食べました", "起きて、朝ごはんを食べました")
        ),
    ])
}
