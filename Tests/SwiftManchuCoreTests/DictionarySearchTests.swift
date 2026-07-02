import Testing

@testable import SwiftManchuCore

@Test func wordSearchMatchesAllLanguages() {
    let words = [
        Word(id: 1, manchu: "a", chinese: "啊，哦", english: "ah, huh", attribute: "int."),
        Word(id: 2, manchu: "a uju", chinese: "字母表", english: "alphabet", attribute: "n."),
    ]

    #expect(words.contains { $0.manchu.localizedCaseInsensitiveContains("uju") })
    #expect(words.contains { $0.chinese.localizedCaseInsensitiveContains("字母") })
    #expect(words.contains { $0.english.localizedCaseInsensitiveContains("ALPHA") })
}

@Test func rankedSearchPrefersExactAndManchuPrefixMatches() {
    let words = [
        Word(id: 1, manchu: "foo a", chinese: "别的", english: "other", attribute: "n."),
        Word(id: 2, manchu: "a uju", chinese: "字母表", english: "alphabet", attribute: "n."),
        Word(id: 3, manchu: "a", chinese: "啊，哦", english: "ah", attribute: "int."),
    ]

    #expect(DictionarySearch.rankedWords(words, query: "a").map(\.id) == [3, 2, 1])
}

@Test func sentenceSearchMatchesExampleText() {
    let sentences = [
        Sentence(id: 1, manchu: "mini", chinese: "小", english: "small", wordID: 1),
        Sentence(id: 2, manchu: "amba", chinese: "大", english: "large", wordID: 2),
    ]

    #expect(DictionarySearch.matchingSentences(sentences, query: "LARGE").map(\.wordID) == [2])
}
