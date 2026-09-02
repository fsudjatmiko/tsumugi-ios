import Foundation

/// Static registry containing all 80 Japanese Elementary Grade 1 (Kyōiku / JLPT N5) Kanji datasets.
public struct KanjiGrade1Dataset: Sendable {
    public struct RawKanjiItem: Sendable {
        public let id: String
        public let character: String
        public let meaning: String
        public let onyomi: [String]
        public let kunyomi: [String]
        public let strokeCount: Int
        public let category: String
        public let gradeLevel: Int
        public let jlptLevel: String
        public let radicals: [String]
        public let isUnlocked: Bool
        public let examples: [KanjiExample]
    }

    public static let all80: [RawKanjiItem] = [
        // MARK: - 1. Numbers & Counters (10) - Default Unlocked
        RawKanjiItem(
            id: "kanji_ichi",
            character: "一",
            meaning: "One",
            onyomi: ["イチ", "イツ"],
            kunyomi: ["ひと", "ひとつ"],
            strokeCount: 1,
            category: "Numbers & Counters",
            gradeLevel: 1,
            jlptLevel: "N5",
            radicals: ["一"],
            isUnlocked: true,
            examples: [
                KanjiExample(text: "一つ", kana: "ひとつ", english: "one thing"),
                KanjiExample(text: "一人", kana: "ひとり", english: "one person / alone")
            ]
        ),
        RawKanjiItem(
            id: "kanji_ni",
            character: "二",
            meaning: "Two",
            onyomi: ["ニ", "ジ"],
            kunyomi: ["ふた", "ふたつ"],
            strokeCount: 2,
            category: "Numbers & Counters",
            gradeLevel: 1,
            jlptLevel: "N5",
            radicals: ["二"],
            isUnlocked: true,
            examples: [
                KanjiExample(text: "二つ", kana: "ふたつ", english: "two things"),
                KanjiExample(text: "二人", kana: "ふたり", english: "two people")
            ]
        ),
        RawKanjiItem(
            id: "kanji_san",
            character: "三",
            meaning: "Three",
            onyomi: ["サン"],
            kunyomi: ["み", "みっつ"],
            strokeCount: 3,
            category: "Numbers & Counters",
            gradeLevel: 1,
            jlptLevel: "N5",
            radicals: ["一"],
            isUnlocked: true,
            examples: [
                KanjiExample(text: "三つ", kana: "みっつ", english: "three things"),
                KanjiExample(text: "三日", kana: "みっか", english: "3rd day / three days")
            ]
        ),
        RawKanjiItem(
            id: "kanji_shi_yon",
            character: "四",
            meaning: "Four",
            onyomi: ["シ"],
            kunyomi: ["よ", "よっつ", "よん"],
            strokeCount: 5,
            category: "Numbers & Counters",
            gradeLevel: 1,
            jlptLevel: "N5",
            radicals: ["囗"],
            isUnlocked: true,
            examples: [
                KanjiExample(text: "四つ", kana: "よっつ", english: "four things"),
                KanjiExample(text: "四月", kana: "しがつ", english: "April")
            ]
        ),
        RawKanjiItem(
            id: "kanji_go",
            character: "五",
            meaning: "Five",
            onyomi: ["ゴ"],
            kunyomi: ["いつ", "いつつ"],
            strokeCount: 4,
            category: "Numbers & Counters",
            gradeLevel: 1,
            jlptLevel: "N5",
            radicals: ["二"],
            isUnlocked: true,
            examples: [
                KanjiExample(text: "五つ", kana: "いつつ", english: "five things"),
                KanjiExample(text: "五日", kana: "いつか", english: "5th day / five days")
            ]
        ),
        RawKanjiItem(
            id: "kanji_roku",
            character: "六",
            meaning: "Six",
            onyomi: ["ロク"],
            kunyomi: ["む", "むっつ"],
            strokeCount: 4,
            category: "Numbers & Counters",
            gradeLevel: 1,
            jlptLevel: "N5",
            radicals: ["八"],
            isUnlocked: true,
            examples: [
                KanjiExample(text: "六つ", kana: "むっつ", english: "six things"),
                KanjiExample(text: "六月", kana: "ろくがつ", english: "June")
            ]
        ),
        RawKanjiItem(
            id: "kanji_shichi_nana",
            character: "七",
            meaning: "Seven",
            onyomi: ["シチ"],
            kunyomi: ["なな", "ななつ"],
            strokeCount: 2,
            category: "Numbers & Counters",
            gradeLevel: 1,
            jlptLevel: "N5",
            radicals: ["一"],
            isUnlocked: true,
            examples: [
                KanjiExample(text: "七つ", kana: "ななつ", english: "seven things"),
                KanjiExample(text: "七月", kana: "しちがつ", english: "July")
            ]
        ),
        RawKanjiItem(
            id: "kanji_hachi",
            character: "八",
            meaning: "Eight",
            onyomi: ["ハチ"],
            kunyomi: ["や", "やっつ"],
            strokeCount: 2,
            category: "Numbers & Counters",
            gradeLevel: 1,
            jlptLevel: "N5",
            radicals: ["八"],
            isUnlocked: true,
            examples: [
                KanjiExample(text: "八つ", kana: "やっつ", english: "eight things"),
                KanjiExample(text: "八日", kana: "ようか", english: "8th day / eight days")
            ]
        ),
        RawKanjiItem(
            id: "kanji_kyuu_ku",
            character: "九",
            meaning: "Nine",
            onyomi: ["キュウ", "ク"],
            kunyomi: ["ここの", "ここのつ"],
            strokeCount: 2,
            category: "Numbers & Counters",
            gradeLevel: 1,
            jlptLevel: "N5",
            radicals: ["乙"],
            isUnlocked: true,
            examples: [
                KanjiExample(text: "九つ", kana: "ここのつ", english: "nine things"),
                KanjiExample(text: "九月", kana: "くがつ", english: "September")
            ]
        ),
        RawKanjiItem(
            id: "kanji_juu",
            character: "十",
            meaning: "Ten",
            onyomi: ["ジュウ", "ジッ"],
            kunyomi: ["とお", "と"],
            strokeCount: 2,
            category: "Numbers & Counters",
            gradeLevel: 1,
            jlptLevel: "N5",
            radicals: ["十"],
            isUnlocked: true,
            examples: [
                KanjiExample(text: "十", kana: "とお", english: "ten things"),
                KanjiExample(text: "十月", kana: "じゅうがつ", english: "October")
            ]
        ),

        // MARK: - 2. Quantity, Scale & Position (11)
        RawKanjiItem(
            id: "kanji_hyaku",
            character: "百",
            meaning: "Hundred",
            onyomi: ["ヒャク"],
            kunyomi: ["もも"],
            strokeCount: 6,
            category: "Quantity, Scale & Position",
            gradeLevel: 1,
            jlptLevel: "N5",
            radicals: ["白", "一"],
            isUnlocked: false,
            examples: [
                KanjiExample(text: "百", kana: "ひゃく", english: "hundred"),
                KanjiExample(text: "三百", kana: "さんびゃく", english: "three hundred")
            ]
        ),
        RawKanjiItem(
            id: "kanji_sen",
            character: "千",
            meaning: "Thousand",
            onyomi: ["セン"],
            kunyomi: ["ち"],
            strokeCount: 3,
            category: "Quantity, Scale & Position",
            gradeLevel: 1,
            jlptLevel: "N5",
            radicals: ["十", "丿"],
            isUnlocked: false,
            examples: [
                KanjiExample(text: "千", kana: "せん", english: "thousand"),
                KanjiExample(text: "千円", kana: "せんえん", english: "one thousand yen")
            ]
        ),
        RawKanjiItem(
            id: "kanji_man",
            character: "万",
            meaning: "Ten Thousand",
            onyomi: ["マン", "バン"],
            kunyomi: ["よろず"],
            strokeCount: 3,
            category: "Quantity, Scale & Position",
            gradeLevel: 1,
            jlptLevel: "N5",
            radicals: ["一"],
            isUnlocked: false,
            examples: [
                KanjiExample(text: "一万", kana: "いちまん", english: "ten thousand"),
                KanjiExample(text: "万国", kana: "ばんこく", english: "all nations / global")
            ]
        ),
        RawKanjiItem(
            id: "kanji_dai_oo",
            character: "大",
            meaning: "Big, Large",
            onyomi: ["ダイ", "タイ"],
            kunyomi: ["おお", "おおきい"],
            strokeCount: 3,
            category: "Quantity, Scale & Position",
            gradeLevel: 1,
            jlptLevel: "N5",
            radicals: ["大"],
            isUnlocked: false,
            examples: [
                KanjiExample(text: "大きい", kana: "おおきい", english: "big / large"),
                KanjiExample(text: "大学", kana: "だいがく", english: "university")
            ]
        ),
        RawKanjiItem(
            id: "kanji_chuu_naka",
            character: "中",
            meaning: "Inside, Middle",
            onyomi: ["チュウ"],
            kunyomi: ["なか"],
            strokeCount: 4,
            category: "Quantity, Scale & Position",
            gradeLevel: 1,
            jlptLevel: "N5",
            radicals: ["丨", "口"],
            isUnlocked: false,
            examples: [
                KanjiExample(text: "中", kana: "なか", english: "inside / middle"),
                KanjiExample(text: "一日中", kana: "いちにちじゅう", english: "all day long")
            ]
        ),
        RawKanjiItem(
            id: "kanji_shou_chii",
            character: "小",
            meaning: "Small, Little",
            onyomi: ["ショウ"],
            kunyomi: ["ちい", "ちいさい", "こ"],
            strokeCount: 3,
            category: "Quantity, Scale & Position",
            gradeLevel: 1,
            jlptLevel: "N5",
            radicals: ["小"],
            isUnlocked: false,
            examples: [
                KanjiExample(text: "小さい", kana: "ちいさい", english: "small / tiny"),
                KanjiExample(text: "小学校", kana: "しょうがっこう", english: "elementary school")
            ]
        ),
        RawKanjiItem(
            id: "kanji_jou_ue",
            character: "上",
            meaning: "Above, Up",
            onyomi: ["ジョウ", "ショウ"],
            kunyomi: ["うえ", "あがる", "のぼる"],
            strokeCount: 3,
            category: "Quantity, Scale & Position",
            gradeLevel: 1,
            jlptLevel: "N5",
            radicals: ["一"],
            isUnlocked: false,
            examples: [
                KanjiExample(text: "上", kana: "うえ", english: "above / on top"),
                KanjiExample(text: "上手", kana: "じょうず", english: "skillful / good at")
            ]
        ),
        RawKanjiItem(
            id: "kanji_ge_shita",
            character: "下",
            meaning: "Below, Down",
            onyomi: ["カ", "ゲ"],
            kunyomi: ["した", "さがる", "くだる"],
            strokeCount: 3,
            category: "Quantity, Scale & Position",
            gradeLevel: 1,
            jlptLevel: "N5",
            radicals: ["一"],
            isUnlocked: false,
            examples: [
                KanjiExample(text: "下", kana: "した", english: "below / under"),
                KanjiExample(text: "下手", kana: "へた", english: "unskillful / poor at")
            ]
        ),
        RawKanjiItem(
            id: "kanji_sa_hidari",
            character: "左",
            meaning: "Left",
            onyomi: ["サ"],
            kunyomi: ["ひだり"],
            strokeCount: 5,
            category: "Quantity, Scale & Position",
            gradeLevel: 1,
            jlptLevel: "N5",
            radicals: ["工", "𠂇"],
            isUnlocked: false,
            examples: [
                KanjiExample(text: "左", kana: "ひだり", english: "left direction"),
                KanjiExample(text: "左手", kana: "ひだりて", english: "left hand")
            ]
        ),
        RawKanjiItem(
            id: "kanji_uu_migi",
            character: "右",
            meaning: "Right",
            onyomi: ["ウ", "ユウ"],
            kunyomi: ["みぎ"],
            strokeCount: 5,
            category: "Quantity, Scale & Position",
            gradeLevel: 1,
            jlptLevel: "N5",
            radicals: ["口", "𠂇"],
            isUnlocked: false,
            examples: [
                KanjiExample(text: "右", kana: "みぎ", english: "right direction"),
                KanjiExample(text: "右手", kana: "みぎて", english: "right hand")
            ]
        ),
        RawKanjiItem(
            id: "kanji_gan_maru",
            character: "丸",
            meaning: "Circle, Round",
            onyomi: ["ガン"],
            kunyomi: ["まる", "まるい"],
            strokeCount: 3,
            category: "Quantity, Scale & Position",
            gradeLevel: 1,
            jlptLevel: "N5",
            radicals: ["丶", "九"],
            isUnlocked: false,
            examples: [
                KanjiExample(text: "丸い", kana: "まるい", english: "round / circular"),
                KanjiExample(text: "丸", kana: "まる", english: "circle / correct mark")
            ]
        ),

        // MARK: - 3. Nature, Elements & Time (16)
        RawKanjiItem(
            id: "kanji_nichi_hi",
            character: "日",
            meaning: "Sun, Day",
            onyomi: ["ニチ", "ジツ"],
            kunyomi: ["ひ", "か"],
            strokeCount: 4,
            category: "Nature, Elements & Time",
            gradeLevel: 1,
            jlptLevel: "N5",
            radicals: ["日"],
            isUnlocked: false,
            examples: [
                KanjiExample(text: "日曜日", kana: "にちようび", english: "Sunday"),
                KanjiExample(text: "今日", kana: "きょう", english: "today")
            ]
        ),
        RawKanjiItem(
            id: "kanji_getsu_tsuki",
            character: "月",
            meaning: "Moon, Month",
            onyomi: ["ゲツ", "ガツ"],
            kunyomi: ["つき"],
            strokeCount: 4,
            category: "Nature, Elements & Time",
            gradeLevel: 1,
            jlptLevel: "N5",
            radicals: ["月"],
            isUnlocked: false,
            examples: [
                KanjiExample(text: "月曜日", kana: "げつようび", english: "Monday"),
                KanjiExample(text: "今月", kana: "こんげつ", english: "this month")
            ]
        ),
        RawKanjiItem(
            id: "kanji_ka_hi",
            character: "火",
            meaning: "Fire",
            onyomi: ["カ"],
            kunyomi: ["ひ", "ほ"],
            strokeCount: 4,
            category: "Nature, Elements & Time",
            gradeLevel: 1,
            jlptLevel: "N5",
            radicals: ["火"],
            isUnlocked: false,
            examples: [
                KanjiExample(text: "火曜日", kana: "かようび", english: "Tuesday"),
                KanjiExample(text: "花火", kana: "はなび", english: "fireworks")
            ]
        ),
        RawKanjiItem(
            id: "kanji_sui_mizu",
            character: "水",
            meaning: "Water",
            onyomi: ["スイ"],
            kunyomi: ["みず"],
            strokeCount: 4,
            category: "Nature, Elements & Time",
            gradeLevel: 1,
            jlptLevel: "N5",
            radicals: ["水"],
            isUnlocked: false,
            examples: [
                KanjiExample(text: "水曜日", kana: "すいようび", english: "Wednesday"),
                KanjiExample(text: "水", kana: "みず", english: "cold water")
            ]
        ),
        RawKanjiItem(
            id: "kanji_moku_ki",
            character: "木",
            meaning: "Tree, Wood",
            onyomi: ["モク", "ボク"],
            kunyomi: ["き", "こ"],
            strokeCount: 4,
            category: "Nature, Elements & Time",
            gradeLevel: 1,
            jlptLevel: "N5",
            radicals: ["木"],
            isUnlocked: false,
            examples: [
                KanjiExample(text: "木曜日", kana: "もくようび", english: "Thursday"),
                KanjiExample(text: "木", kana: "き", english: "tree / wood")
            ]
        ),
        RawKanjiItem(
            id: "kanji_kin_kane",
            character: "金",
            meaning: "Gold, Money",
            onyomi: ["キン", "コン"],
            kunyomi: ["かね", "かな"],
            strokeCount: 8,
            category: "Nature, Elements & Time",
            gradeLevel: 1,
            jlptLevel: "N5",
            radicals: ["金"],
            isUnlocked: false,
            examples: [
                KanjiExample(text: "金曜日", kana: "きんようび", english: "Friday"),
                KanjiExample(text: "お金", kana: "おかね", english: "money")
            ]
        ),
        RawKanjiItem(
            id: "kanji_do_tsuchi",
            character: "土",
            meaning: "Soil, Earth",
            onyomi: ["ド", "ト"],
            kunyomi: ["つち"],
            strokeCount: 3,
            category: "Nature, Elements & Time",
            gradeLevel: 1,
            jlptLevel: "N5",
            radicals: ["土"],
            isUnlocked: false,
            examples: [
                KanjiExample(text: "土曜日", kana: "どようび", english: "Saturday"),
                KanjiExample(text: "土地", kana: "とち", english: "land / plot")
            ]
        ),
        RawKanjiItem(
            id: "kanji_ten_ama",
            character: "天",
            meaning: "Heaven, Sky",
            onyomi: ["テン"],
            kunyomi: ["あま", "あめ"],
            strokeCount: 4,
            category: "Nature, Elements & Time",
            gradeLevel: 1,
            jlptLevel: "N5",
            radicals: ["大", "一"],
            isUnlocked: false,
            examples: [
                KanjiExample(text: "天気", kana: "てんき", english: "weather"),
                KanjiExample(text: "天国", kana: "てんごく", english: "heaven / paradise")
            ]
        ),
        RawKanjiItem(
            id: "kanji_ki",
            character: "気",
            meaning: "Spirit, Energy",
            onyomi: ["キ", "ケ"],
            kunyomi: ["いき"],
            strokeCount: 6,
            category: "Nature, Elements & Time",
            gradeLevel: 1,
            jlptLevel: "N5",
            radicals: ["气"],
            isUnlocked: false,
            examples: [
                KanjiExample(text: "元気", kana: "げんき", english: "healthy / lively"),
                KanjiExample(text: "気持ち", kana: "きもち", english: "feeling / mood")
            ]
        ),
        RawKanjiItem(
            id: "kanji_u_ame",
            character: "雨",
            meaning: "Rain",
            onyomi: ["ウ"],
            kunyomi: ["あめ", "あま"],
            strokeCount: 8,
            category: "Nature, Elements & Time",
            gradeLevel: 1,
            jlptLevel: "N5",
            radicals: ["雨"],
            isUnlocked: false,
            examples: [
                KanjiExample(text: "雨", kana: "あめ", english: "rain"),
                KanjiExample(text: "大雨", kana: "おおあめ", english: "heavy rain")
            ]
        ),
        RawKanjiItem(
            id: "kanji_san_yama",
            character: "山",
            meaning: "Mountain",
            onyomi: ["サン", "セン"],
            kunyomi: ["やま"],
            strokeCount: 3,
            category: "Nature, Elements & Time",
            gradeLevel: 1,
            jlptLevel: "N5",
            radicals: ["山"],
            isUnlocked: false,
            examples: [
                KanjiExample(text: "山", kana: "やま", english: "mountain"),
                KanjiExample(text: "富士山", kana: "ふじさん", english: "Mount Fuji")
            ]
        ),
        RawKanjiItem(
            id: "kanji_sen_kawa",
            character: "川",
            meaning: "River",
            onyomi: ["セン"],
            kunyomi: ["かわ"],
            strokeCount: 3,
            category: "Nature, Elements & Time",
            gradeLevel: 1,
            jlptLevel: "N5",
            radicals: ["川", "巛"],
            isUnlocked: false,
            examples: [
                KanjiExample(text: "川", kana: "かわ", english: "river / stream"),
                KanjiExample(text: "小川", kana: "おがわ", english: "brook / creek")
            ]
        ),
        RawKanjiItem(
            id: "kanji_den_ta",
            character: "田",
            meaning: "Rice Field",
            onyomi: ["デン"],
            kunyomi: ["た"],
            strokeCount: 5,
            category: "Nature, Elements & Time",
            gradeLevel: 1,
            jlptLevel: "N5",
            radicals: ["田"],
            isUnlocked: false,
            examples: [
                KanjiExample(text: "田んぼ", kana: "たんぼ", english: "paddy field"),
                KanjiExample(text: "水田", kana: "すいでん", english: "flooded rice field")
            ]
        ),
        RawKanjiItem(
            id: "kanji_seki_ishi",
            character: "石",
            meaning: "Stone",
            onyomi: ["セキ", "シャク"],
            kunyomi: ["いし"],
            strokeCount: 5,
            category: "Nature, Elements & Time",
            gradeLevel: 1,
            jlptLevel: "N5",
            radicals: ["石"],
            isUnlocked: false,
            examples: [
                KanjiExample(text: "石", kana: "いし", english: "stone / rock"),
                KanjiExample(text: "小石", kana: "こいし", english: "pebble")
            ]
        ),
        RawKanjiItem(
            id: "kanji_ka_hana",
            character: "花",
            meaning: "Flower",
            onyomi: ["カ", "ケ"],
            kunyomi: ["はな"],
            strokeCount: 7,
            category: "Nature, Elements & Time",
            gradeLevel: 1,
            jlptLevel: "N5",
            radicals: ["艹"],
            isUnlocked: false,
            examples: [
                KanjiExample(text: "花", kana: "はな", english: "flower / blossom"),
                KanjiExample(text: "花見", kana: "はなみ", english: "cherry blossom viewing")
            ]
        ),
        RawKanjiItem(
            id: "kanji_sou_kusa",
            character: "草",
            meaning: "Grass, Herb",
            onyomi: ["ソウ"],
            kunyomi: ["くさ"],
            strokeCount: 9,
            category: "Nature, Elements & Time",
            gradeLevel: 1,
            jlptLevel: "N5",
            radicals: ["艹"],
            isUnlocked: false,
            examples: [
                KanjiExample(text: "草", kana: "くさ", english: "grass / weed"),
                KanjiExample(text: "草花", kana: "くさばな", english: "flowering grass")
            ]
        ),

        // MARK: - 4. People, Body & Society (15)
        RawKanjiItem(
            id: "kanji_jin_hito",
            character: "人",
            meaning: "Person, Human",
            onyomi: ["ジン", "ニン"],
            kunyomi: ["ひと"],
            strokeCount: 2,
            category: "People, Body & Society",
            gradeLevel: 1,
            jlptLevel: "N5",
            radicals: ["人", "亻"],
            isUnlocked: false,
            examples: [
                KanjiExample(text: "日本人", kana: "にほんじん", english: "Japanese person"),
                KanjiExample(text: "大人", kana: "おとな", english: "adult")
            ]
        ),
        RawKanjiItem(
            id: "kanji_shi_ko",
            character: "子",
            meaning: "Child",
            onyomi: ["シ", "ス"],
            kunyomi: ["こ"],
            strokeCount: 3,
            category: "People, Body & Society",
            gradeLevel: 1,
            jlptLevel: "N5",
            radicals: ["子"],
            isUnlocked: false,
            examples: [
                KanjiExample(text: "子供", kana: "こども", english: "child / children"),
                KanjiExample(text: "女の子", kana: "おんなのこ", english: "girl")
            ]
        ),
        RawKanjiItem(
            id: "kanji_jo_onna",
            character: "女",
            meaning: "Woman, Female",
            onyomi: ["ジョ", "ニョ"],
            kunyomi: ["おんな", "め"],
            strokeCount: 3,
            category: "People, Body & Society",
            gradeLevel: 1,
            jlptLevel: "N5",
            radicals: ["女"],
            isUnlocked: false,
            examples: [
                KanjiExample(text: "女性", kana: "じょせい", english: "female / woman"),
                KanjiExample(text: "女の人", kana: "おんなのひと", english: "woman")
            ]
        ),
        RawKanjiItem(
            id: "kanji_dan_otoko",
            character: "男",
            meaning: "Man, Male",
            onyomi: ["ダン", "ナン"],
            kunyomi: ["おとこ"],
            strokeCount: 7,
            category: "People, Body & Society",
            gradeLevel: 1,
            jlptLevel: "N5",
            radicals: ["田", "力"],
            isUnlocked: false,
            examples: [
                KanjiExample(text: "男性", kana: "だんせい", english: "male / man"),
                KanjiExample(text: "男の子", kana: "おとこのこ", english: "boy")
            ]
        ),
        RawKanjiItem(
            id: "kanji_moku_me",
            character: "目",
            meaning: "Eye",
            onyomi: ["モク", "ボク"],
            kunyomi: ["め", "ま"],
            strokeCount: 5,
            category: "People, Body & Society",
            gradeLevel: 1,
            jlptLevel: "N5",
            radicals: ["目"],
            isUnlocked: false,
            examples: [
                KanjiExample(text: "目", kana: "め", english: "eye"),
                KanjiExample(text: "目次", kana: "もくじ", english: "table of contents")
            ]
        ),
        RawKanjiItem(
            id: "kanji_ji_mimi",
            character: "耳",
            meaning: "Ear",
            onyomi: ["ジ"],
            kunyomi: ["みみ"],
            strokeCount: 6,
            category: "People, Body & Society",
            gradeLevel: 1,
            jlptLevel: "N5",
            radicals: ["耳"],
            isUnlocked: false,
            examples: [
                KanjiExample(text: "耳", kana: "みみ", english: "ear"),
                KanjiExample(text: "初耳", kana: "はつみみ", english: "hearing something for first time")
            ]
        ),
        RawKanjiItem(
            id: "kanji_kou_kuchi",
            character: "口",
            meaning: "Mouth",
            onyomi: ["コウ", "ク"],
            kunyomi: ["くち"],
            strokeCount: 3,
            category: "People, Body & Society",
            gradeLevel: 1,
            jlptLevel: "N5",
            radicals: ["口"],
            isUnlocked: false,
            examples: [
                KanjiExample(text: "口", kana: "くち", english: "mouth / opening"),
                KanjiExample(text: "入口", kana: "いりぐち", english: "entrance")
            ]
        ),
        RawKanjiItem(
            id: "kanji_shu_te",
            character: "手",
            meaning: "Hand",
            onyomi: ["シュ"],
            kunyomi: ["て", "た"],
            strokeCount: 4,
            category: "People, Body & Society",
            gradeLevel: 1,
            jlptLevel: "N5",
            radicals: ["手", "扌"],
            isUnlocked: false,
            examples: [
                KanjiExample(text: "手紙", kana: "てがみ", english: "letter"),
                KanjiExample(text: "切手", kana: "きって", english: "postage stamp")
            ]
        ),
        RawKanjiItem(
            id: "kanji_soku_ashi",
            character: "足",
            meaning: "Foot, Leg",
            onyomi: ["ソク"],
            kunyomi: ["あし", "たりる"],
            strokeCount: 7,
            category: "People, Body & Society",
            gradeLevel: 1,
            jlptLevel: "N5",
            radicals: ["足"],
            isUnlocked: false,
            examples: [
                KanjiExample(text: "足", kana: "あし", english: "foot / leg"),
                KanjiExample(text: "足りる", kana: "たりる", english: "to be sufficient")
            ]
        ),
        RawKanjiItem(
            id: "kanji_sen_saki",
            character: "先",
            meaning: "Ahead, Previous",
            onyomi: ["セン"],
            kunyomi: ["さき", "まず"],
            strokeCount: 6,
            category: "People, Body & Society",
            gradeLevel: 1,
            jlptLevel: "N5",
            radicals: ["儿"],
            isUnlocked: false,
            examples: [
                KanjiExample(text: "先生", kana: "せんせい", english: "teacher / doctor"),
                KanjiExample(text: "先月", kana: "せんげつ", english: "last month")
            ]
        ),
        RawKanjiItem(
            id: "kanji_sei_nama",
            character: "生",
            meaning: "Life, Birth",
            onyomi: ["セイ", "ショウ"],
            kunyomi: ["い・きる", "う・まれる", "なま"],
            strokeCount: 5,
            category: "People, Body & Society",
            gradeLevel: 1,
            jlptLevel: "N5",
            radicals: ["生"],
            isUnlocked: false,
            examples: [
                KanjiExample(text: "学生", kana: "がくせい", english: "student"),
                KanjiExample(text: "生まれる", kana: "うまれる", english: "to be born")
            ]
        ),
        RawKanjiItem(
            id: "kanji_gaku_mana",
            character: "学",
            meaning: "Study, Learn",
            onyomi: ["ガク"],
            kunyomi: ["まな・ぶ"],
            strokeCount: 8,
            category: "People, Body & Society",
            gradeLevel: 1,
            jlptLevel: "N5",
            radicals: ["子"],
            isUnlocked: false,
            examples: [
                KanjiExample(text: "学校", kana: "がっこう", english: "school"),
                KanjiExample(text: "学ぶ", kana: "まなぶ", english: "to learn / study")
            ]
        ),
        RawKanjiItem(
            id: "kanji_kou",
            character: "校",
            meaning: "School",
            onyomi: ["コウ"],
            kunyomi: [],
            strokeCount: 10,
            category: "People, Body & Society",
            gradeLevel: 1,
            jlptLevel: "N5",
            radicals: ["木", "交"],
            isUnlocked: false,
            examples: [
                KanjiExample(text: "高校", kana: "こうこう", english: "high school"),
                KanjiExample(text: "校長", kana: "こうちょう", english: "school principal")
            ]
        ),
        RawKanjiItem(
            id: "kanji_mei_na",
            character: "名",
            meaning: "Name, Fame",
            onyomi: ["メイ", "ミョウ"],
            kunyomi: ["な"],
            strokeCount: 6,
            category: "People, Body & Society",
            gradeLevel: 1,
            jlptLevel: "N5",
            radicals: ["口", "夕"],
            isUnlocked: false,
            examples: [
                KanjiExample(text: "名前", kana: "なまえ", english: "name"),
                KanjiExample(text: "有名", kana: "ゆうめい", english: "famous")
            ]
        ),
        RawKanjiItem(
            id: "kanji_hon_moto",
            character: "本",
            meaning: "Book, Origin",
            onyomi: ["ホン"],
            kunyomi: ["もと"],
            strokeCount: 5,
            category: "People, Body & Society",
            gradeLevel: 1,
            jlptLevel: "N5",
            radicals: ["木", "一"],
            isUnlocked: false,
            examples: [
                KanjiExample(text: "日本", kana: "にほん", english: "Japan"),
                KanjiExample(text: "本屋", kana: "ほんや", english: "bookstore")
            ]
        ),

        // MARK: - 5. Animals & Living Things (5)
        RawKanjiItem(
            id: "kanji_ken_inu",
            character: "犬",
            meaning: "Dog",
            onyomi: ["ケン"],
            kunyomi: ["いぬ"],
            strokeCount: 4,
            category: "Animals & Living Things",
            gradeLevel: 1,
            jlptLevel: "N5",
            radicals: ["犬", "犭"],
            isUnlocked: false,
            examples: [
                KanjiExample(text: "子犬", kana: "こいぬ", english: "puppy"),
                KanjiExample(text: "番犬", kana: "ばんけん", english: "watchdog")
            ]
        ),
        RawKanjiItem(
            id: "kanji_chuu_mushi",
            character: "虫",
            meaning: "Insect, Bug",
            onyomi: ["チュウ"],
            kunyomi: ["むし"],
            strokeCount: 6,
            category: "Animals & Living Things",
            gradeLevel: 1,
            jlptLevel: "N5",
            radicals: ["虫"],
            isUnlocked: false,
            examples: [
                KanjiExample(text: "昆虫", kana: "こんちゅう", english: "insect"),
                KanjiExample(text: "虫歯", kana: "むしば", english: "decayed tooth / cavity")
            ]
        ),
        RawKanjiItem(
            id: "kanji_bai_kai",
            character: "貝",
            meaning: "Shellfish, Shell",
            onyomi: ["バイ"],
            kunyomi: ["かい"],
            strokeCount: 7,
            category: "Animals & Living Things",
            gradeLevel: 1,
            jlptLevel: "N5",
            radicals: ["貝"],
            isUnlocked: false,
            examples: [
                KanjiExample(text: "貝殻", kana: "かいがら", english: "seashell"),
                KanjiExample(text: "貝", kana: "かい", english: "shellfish / clam")
            ]
        ),
        RawKanjiItem(
            id: "kanji_gyo_sakana",
            character: "魚",
            meaning: "Fish",
            onyomi: ["ギョ"],
            kunyomi: ["さかな", "うお"],
            strokeCount: 11,
            category: "Animals & Living Things",
            gradeLevel: 1,
            jlptLevel: "N5",
            radicals: ["魚"],
            isUnlocked: false,
            examples: [
                KanjiExample(text: "魚屋", kana: "さかなや", english: "fish market"),
                KanjiExample(text: "金魚", kana: "きんぎょ", english: "goldfish")
            ]
        ),
        RawKanjiItem(
            id: "kanji_chou_tori",
            character: "鳥",
            meaning: "Bird",
            onyomi: ["チョウ"],
            kunyomi: ["とり"],
            strokeCount: 11,
            category: "Animals & Living Things",
            gradeLevel: 1,
            jlptLevel: "N5",
            radicals: ["鳥"],
            isUnlocked: false,
            examples: [
                KanjiExample(text: "小鳥", kana: "ことり", english: "small bird"),
                KanjiExample(text: "焼き鳥", kana: "やきとり", english: "grilled chicken skewers")
            ]
        ),

        // MARK: - 6. Directions & Space (4)
        RawKanjiItem(
            id: "kanji_tou_higashi",
            character: "東",
            meaning: "East",
            onyomi: ["トウ"],
            kunyomi: ["ひがし"],
            strokeCount: 8,
            category: "Directions & Space",
            gradeLevel: 1,
            jlptLevel: "N5",
            radicals: ["木", "日"],
            isUnlocked: false,
            examples: [
                KanjiExample(text: "東京", kana: "とうきょう", english: "Tokyo"),
                KanjiExample(text: "東口", kana: "ひがしぐち", english: "east exit")
            ]
        ),
        RawKanjiItem(
            id: "kanji_sei_nishi",
            character: "西",
            meaning: "West",
            onyomi: ["セイ", "サイ"],
            kunyomi: ["にし"],
            strokeCount: 6,
            category: "Directions & Space",
            gradeLevel: 1,
            jlptLevel: "N5",
            radicals: ["西", "襾"],
            isUnlocked: false,
            examples: [
                KanjiExample(text: "東西", kana: "とうざい", english: "east and west"),
                KanjiExample(text: "西口", kana: "にしぐち", english: "west exit")
            ]
        ),
        RawKanjiItem(
            id: "kanji_nan_minami",
            character: "南",
            meaning: "South",
            onyomi: ["ナン"],
            kunyomi: ["みなみ"],
            strokeCount: 9,
            category: "Directions & Space",
            gradeLevel: 1,
            jlptLevel: "N5",
            radicals: ["十"],
            isUnlocked: false,
            examples: [
                KanjiExample(text: "南口", kana: "みなみぐち", english: "south exit"),
                KanjiExample(text: "南東", kana: "なんとう", english: "southeast")
            ]
        ),
        RawKanjiItem(
            id: "kanji_hoku_kita",
            character: "北",
            meaning: "North",
            onyomi: ["ホク"],
            kunyomi: ["きた"],
            strokeCount: 5,
            category: "Directions & Space",
            gradeLevel: 1,
            jlptLevel: "N5",
            radicals: ["匕"],
            isUnlocked: false,
            examples: [
                KanjiExample(text: "北海道", kana: "ほっかいどう", english: "Hokkaido"),
                KanjiExample(text: "北口", kana: "きたぐち", english: "north exit")
            ]
        ),

        // MARK: - 7. Actions, States & Quality (19)
        RawKanjiItem(
            id: "kanji_ken_mi",
            character: "見",
            meaning: "See, Look",
            onyomi: ["ケン"],
            kunyomi: ["み・る", "み・える", "み・せる"],
            strokeCount: 7,
            category: "Actions, States & Quality",
            gradeLevel: 1,
            jlptLevel: "N5",
            radicals: ["目", "儿"],
            isUnlocked: false,
            examples: [
                KanjiExample(text: "見る", kana: "みる", english: "to see / to look"),
                KanjiExample(text: "意見", kana: "いけん", english: "opinion")
            ]
        ),
        RawKanjiItem(
            id: "kanji_on_oto",
            character: "音",
            meaning: "Sound",
            onyomi: ["オン", "イン"],
            kunyomi: ["おと", "ね"],
            strokeCount: 9,
            category: "Actions, States & Quality",
            gradeLevel: 1,
            jlptLevel: "N5",
            radicals: ["音"],
            isUnlocked: false,
            examples: [
                KanjiExample(text: "音楽", kana: "おんがく", english: "music"),
                KanjiExample(text: "足音", kana: "あしおと", english: "footsteps")
            ]
        ),
        RawKanjiItem(
            id: "kanji_ryoku_chikara",
            character: "力",
            meaning: "Power, Strength",
            onyomi: ["リョク", "リキ"],
            kunyomi: ["ちから"],
            strokeCount: 2,
            category: "Actions, States & Quality",
            gradeLevel: 1,
            jlptLevel: "N5",
            radicals: ["力"],
            isUnlocked: false,
            examples: [
                KanjiExample(text: "力", kana: "ちから", english: "power / force"),
                KanjiExample(text: "水力", kana: "すいりょく", english: "water power")
            ]
        ),
        RawKanjiItem(
            id: "kanji_en_maru",
            character: "円",
            meaning: "Yen, Circle",
            onyomi: ["エン"],
            kunyomi: ["まる・い"],
            strokeCount: 4,
            category: "Actions, States & Quality",
            gradeLevel: 1,
            jlptLevel: "N5",
            radicals: ["冂"],
            isUnlocked: false,
            examples: [
                KanjiExample(text: "百円", kana: "ひゃくえん", english: "100 yen"),
                KanjiExample(text: "円高", kana: "えんだか", english: "strong yen")
            ]
        ),
        RawKanjiItem(
            id: "kanji_nen_toshi",
            character: "年",
            meaning: "Year",
            onyomi: ["ネン"],
            kunyomi: ["とし"],
            strokeCount: 6,
            category: "Actions, States & Quality",
            gradeLevel: 1,
            jlptLevel: "N5",
            radicals: ["干"],
            isUnlocked: false,
            examples: [
                KanjiExample(text: "今年", kana: "ことし", english: "this year"),
                KanjiExample(text: "来年", kana: "らいねん", english: "next year")
            ]
        ),
        RawKanjiItem(
            id: "kanji_sou_haya",
            character: "早",
            meaning: "Early, Fast",
            onyomi: ["ソウ", "サッ"],
            kunyomi: ["はや・い"],
            strokeCount: 6,
            category: "Actions, States & Quality",
            gradeLevel: 1,
            jlptLevel: "N5",
            radicals: ["日", "十"],
            isUnlocked: false,
            examples: [
                KanjiExample(text: "早い", kana: "はやい", english: "early / fast"),
                KanjiExample(text: "早口", kana: "はやくち", english: "fast talking")
            ]
        ),
        RawKanjiItem(
            id: "kanji_haku_shiro",
            character: "白",
            meaning: "White",
            onyomi: ["ハク", "ビャク"],
            kunyomi: ["しろ", "しろ・い"],
            strokeCount: 5,
            category: "Actions, States & Quality",
            gradeLevel: 1,
            jlptLevel: "N5",
            radicals: ["白"],
            isUnlocked: false,
            examples: [
                KanjiExample(text: "白い", kana: "しろい", english: "white"),
                KanjiExample(text: "白人", kana: "はくじん", english: "Caucasian person")
            ]
        ),
        RawKanjiItem(
            id: "kanji_seki_aka",
            character: "赤",
            meaning: "Red",
            onyomi: ["セキ", "シャク"],
            kunyomi: ["あか", "あか・い"],
            strokeCount: 7,
            category: "Actions, States & Quality",
            gradeLevel: 1,
            jlptLevel: "N5",
            radicals: ["赤"],
            isUnlocked: false,
            examples: [
                KanjiExample(text: "赤い", kana: "あかい", english: "red"),
                KanjiExample(text: "赤ちゃん", kana: "あかちゃん", english: "baby")
            ]
        ),
        RawKanjiItem(
            id: "kanji_sei_ao",
            character: "青",
            meaning: "Blue, Green",
            onyomi: ["セイ", "ショウ"],
            kunyomi: ["あお", "あお・い"],
            strokeCount: 8,
            category: "Actions, States & Quality",
            gradeLevel: 1,
            jlptLevel: "N5",
            radicals: ["青"],
            isUnlocked: false,
            examples: [
                KanjiExample(text: "青い", kana: "あおい", english: "blue / green"),
                KanjiExample(text: "青年", kana: "せいねん", english: "youth / young man")
            ]
        ),
        RawKanjiItem(
            id: "kanji_kuu_sora",
            character: "空",
            meaning: "Sky, Empty",
            onyomi: ["クウ"],
            kunyomi: ["そら", "あ・く", "から"],
            strokeCount: 8,
            category: "Actions, States & Quality",
            gradeLevel: 1,
            jlptLevel: "N5",
            radicals: ["穴"],
            isUnlocked: false,
            examples: [
                KanjiExample(text: "青空", kana: "あおぞら", english: "blue sky"),
                KanjiExample(text: "空港", kana: "くうこう", english: "airport")
            ]
        ),
        RawKanjiItem(
            id: "kanji_ritsu_ta",
            character: "立",
            meaning: "Stand, Establish",
            onyomi: ["リツ", "リュウ"],
            kunyomi: ["た・つ", "た・てる"],
            strokeCount: 5,
            category: "Actions, States & Quality",
            gradeLevel: 1,
            jlptLevel: "N5",
            radicals: ["立"],
            isUnlocked: false,
            examples: [
                KanjiExample(text: "立つ", kana: "たつ", english: "to stand"),
                KanjiExample(text: "国立", kana: "こくりつ", english: "national")
            ]
        ),
        RawKanjiItem(
            id: "kanji_kyuu_yasu",
            character: "休",
            meaning: "Rest, Day Off",
            onyomi: ["キュウ"],
            kunyomi: ["やす・む", "やす・まる"],
            strokeCount: 6,
            category: "Actions, States & Quality",
            gradeLevel: 1,
            jlptLevel: "N5",
            radicals: ["亻", "木"],
            isUnlocked: false,
            examples: [
                KanjiExample(text: "休み", kana: "やすみ", english: "rest / holiday"),
                KanjiExample(text: "休日", kana: "きゅうじつ", english: "day off")
            ]
        ),
        RawKanjiItem(
            id: "kanji_shutsu_de",
            character: "出",
            meaning: "Exit, Leave",
            onyomi: ["シュツ", "スイ"],
            kunyomi: ["で・る", "だ・す"],
            strokeCount: 5,
            category: "Actions, States & Quality",
            gradeLevel: 1,
            jlptLevel: "N5",
            radicals: ["凵"],
            isUnlocked: false,
            examples: [
                KanjiExample(text: "出口", kana: "でぐち", english: "exit"),
                KanjiExample(text: "出す", kana: "だす", english: "to take out / submit")
            ]
        ),
        RawKanjiItem(
            id: "kanji_nyuu_hai",
            character: "入",
            meaning: "Enter, Insert",
            onyomi: ["ニュウ"],
            kunyomi: ["はい・る", "い・れる"],
            strokeCount: 2,
            category: "Actions, States & Quality",
            gradeLevel: 1,
            jlptLevel: "N5",
            radicals: ["入"],
            isUnlocked: false,
            examples: [
                KanjiExample(text: "入口", kana: "いりぐち", english: "entrance"),
                KanjiExample(text: "入学", kana: "にゅうがく", english: "school admission")
            ]
        ),
        RawKanjiItem(
            id: "kanji_shou_tada",
            character: "正",
            meaning: "Correct, Right",
            onyomi: ["セイ", "ショウ"],
            kunyomi: ["ただ・しい", "まさ"],
            strokeCount: 5,
            category: "Actions, States & Quality",
            gradeLevel: 1,
            jlptLevel: "N5",
            radicals: ["止", "一"],
            isUnlocked: false,
            examples: [
                KanjiExample(text: "正しい", kana: "ただしい", english: "correct / right"),
                KanjiExample(text: "正月", kana: "しょうがつ", english: "New Year")
            ]
        ),
        RawKanjiItem(
            id: "kanji_bun_fumi",
            character: "文",
            meaning: "Sentence, Literature",
            onyomi: ["ブン", "モン"],
            kunyomi: ["ふみ"],
            strokeCount: 4,
            category: "Actions, States & Quality",
            gradeLevel: 1,
            jlptLevel: "N5",
            radicals: ["文"],
            isUnlocked: false,
            examples: [
                KanjiExample(text: "作文", kana: "さくぶん", english: "composition / essay"),
                KanjiExample(text: "文字", kana: "もじ", english: "letter / character")
            ]
        ),
        RawKanjiItem(
            id: "kanji_chou_machi",
            character: "町",
            meaning: "Town",
            onyomi: ["チョウ"],
            kunyomi: ["まち"],
            strokeCount: 7,
            category: "Actions, States & Quality",
            gradeLevel: 1,
            jlptLevel: "N5",
            radicals: ["田", "丁"],
            isUnlocked: false,
            examples: [
                KanjiExample(text: "町", kana: "まち", english: "town / neighborhood"),
                KanjiExample(text: "町長", kana: "ちょうちょう", english: "town mayor")
            ]
        ),
        RawKanjiItem(
            id: "kanji_son_mura",
            character: "村",
            meaning: "Village",
            onyomi: ["ソン"],
            kunyomi: ["むら"],
            strokeCount: 7,
            category: "Actions, States & Quality",
            gradeLevel: 1,
            jlptLevel: "N5",
            radicals: ["木", "寸"],
            isUnlocked: false,
            examples: [
                KanjiExample(text: "村", kana: "むら", english: "village"),
                KanjiExample(text: "農村", kana: "のうそん", english: "farming village")
            ]
        ),
        RawKanjiItem(
            id: "kanji_sha_kuruma",
            character: "車",
            meaning: "Car, Vehicle",
            onyomi: ["シャ"],
            kunyomi: ["くるま"],
            strokeCount: 7,
            category: "Actions, States & Quality",
            gradeLevel: 1,
            jlptLevel: "N5",
            radicals: ["車"],
            isUnlocked: false,
            examples: [
                KanjiExample(text: "電車", kana: "でんしゃ", english: "electric train"),
                KanjiExample(text: "車", kana: "くるま", english: "car / vehicle")
            ]
        )
    ]
}
