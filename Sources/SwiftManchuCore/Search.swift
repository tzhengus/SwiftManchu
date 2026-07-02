import Foundation

public enum DictionarySearch {
    public static func rankedWords(_ words: [Word], query: String) -> [Word] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return words }

        return words
            .compactMap { word -> (Word, Int)? in
                guard let rank = rank(word, query: trimmed) else { return nil }
                return (word, rank)
            }
            .sorted {
                if $0.1 != $1.1 { return $0.1 > $1.1 }
                return $0.0.id < $1.0.id
            }
            .map(\.0)
    }

    public static func matchingSentences(_ sentences: [Sentence], query: String) -> [Sentence] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }

        return sentences.filter {
            $0.manchu.localizedCaseInsensitiveContains(trimmed)
                || $0.chinese.localizedCaseInsensitiveContains(trimmed)
                || $0.english.localizedCaseInsensitiveContains(trimmed)
        }
    }

    private static func rank(_ word: Word, query: String) -> Int? {
        if word.manchu.localizedCaseInsensitiveCompare(query) == .orderedSame { return 100 }
        if word.chinese.localizedCaseInsensitiveCompare(query) == .orderedSame { return 90 }
        if word.english.localizedCaseInsensitiveCompare(query) == .orderedSame { return 80 }
        if word.manchu.localizedCaseInsensitiveContains(query) {
            return word.manchu.localizedCaseInsensitiveHasPrefix(query) ? 70 : 60
        }
        if word.chinese.localizedCaseInsensitiveContains(query) { return 50 }
        if word.english.localizedCaseInsensitiveContains(query) { return 40 }
        return nil
    }
}

private extension String {
    func localizedCaseInsensitiveHasPrefix(_ prefix: String) -> Bool {
        range(of: prefix, options: [.caseInsensitive, .anchored]) != nil
    }
}
