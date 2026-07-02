import Foundation
import Observation
import SwiftManchuCore

@MainActor
@Observable
final class DictionaryModel {
    struct WordSearchResult: Identifiable {
        let word: Word
        let sentenceMatch: Sentence?

        var id: Word.ID { word.id }
    }

    enum ListFilter: String, CaseIterable, Identifiable {
        case all = "All"
        case favorites = "Favorites"
        case recent = "Recent"

        var id: String { rawValue }
    }

    private(set) var words: [Word] = []
    private(set) var sentences: [Int: [Sentence]] = [:]
    private(set) var errorMessage: String?

    private var store: DictionaryStore?
    private var allSentences: [Sentence] = []
    private let favoritesKey = "favoriteWordIDs"
    private let recentKey = "recentWordIDs"

    var selectedWordID: Word.ID?
    var searchText = ""
    var listFilter: ListFilter = .all
    private(set) var favoriteWordIDs: Set<Word.ID>
    private(set) var recentWordIDs: [Word.ID]
    private var detailBackStack: [Word.ID] = []

    init() {
        favoriteWordIDs = Set(UserDefaults.standard.array(forKey: favoritesKey) as? [Int] ?? [])
        recentWordIDs = UserDefaults.standard.array(forKey: recentKey) as? [Int] ?? []
    }

    var filteredResults: [WordSearchResult] {
        let candidates = filteredCandidates
        let wordMatches = DictionarySearch.rankedWords(candidates, query: searchText)
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            return wordMatches.map { WordSearchResult(word: $0, sentenceMatch: nil) }
        }

        let sentenceMatches = DictionarySearch.matchingSentences(allSentences, query: query)
        var firstSentenceByWordID: [Word.ID: Sentence] = [:]
        for sentence in sentenceMatches where firstSentenceByWordID[sentence.wordID] == nil {
            firstSentenceByWordID[sentence.wordID] = sentence
        }

        let matchedIDs = Set(firstSentenceByWordID.keys)
        let wordMatchIDs = Set(wordMatches.map(\.id))
        let sentenceOnlyMatches = candidates.filter {
            matchedIDs.contains($0.id) && !wordMatchIDs.contains($0.id)
        }
        return (wordMatches + sentenceOnlyMatches).map {
            WordSearchResult(word: $0, sentenceMatch: firstSentenceByWordID[$0.id])
        }
    }

    var selectedWord: Word? {
        words.first { $0.id == selectedWordID } ?? words.first
    }

    var wordsByManchu: [String: Word] {
        var result: [String: Word] = [:]
        for word in words where result[word.manchu.normalizedManchuKey] == nil {
            result[word.manchu.normalizedManchuKey] = word
        }
        return result
    }

    func load() async {
        guard let url = DictionaryResource.databaseURL else {
            errorMessage = "Bundled dictionary database is missing."
            return
        }

        do {
            let store = try DictionaryStore(databaseURL: url)
            let loadedWords = try store.words()
            let loadedSentences = try store.allSentences()
            self.store = store
            words = loadedWords
            allSentences = loadedSentences
            selectedWordID = selectedWordID ?? loadedWords.first?.id
            errorMessage = nil
            if let selectedWordID {
                try loadSentences(for: selectedWordID)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func select(_ word: Word) {
        select(word, recordsBackNavigation: false)
    }

    func openGloss(_ word: Word) {
        select(word, recordsBackNavigation: true)
    }

    var canGoBack: Bool {
        !detailBackStack.isEmpty
    }

    func goBack() {
        guard let id = detailBackStack.popLast(), let word = words.first(where: { $0.id == id }) else { return }
        select(word, recordsBackNavigation: false)
    }

    private func select(_ word: Word, recordsBackNavigation: Bool) {
        if recordsBackNavigation, let selectedWordID, selectedWordID != word.id {
            detailBackStack.append(selectedWordID)
        }
        selectedWordID = word.id
        recordRecent(word)
        do {
            try loadSentences(for: word.id)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func clearError() {
        errorMessage = nil
    }

    func isFavorite(_ word: Word) -> Bool {
        favoriteWordIDs.contains(word.id)
    }

    func toggleFavorite(_ word: Word) {
        if favoriteWordIDs.contains(word.id) {
            favoriteWordIDs.remove(word.id)
        } else {
            favoriteWordIDs.insert(word.id)
        }
        UserDefaults.standard.set(Array(favoriteWordIDs).sorted(), forKey: favoritesKey)
    }

    private func recordRecent(_ word: Word) {
        recentWordIDs.removeAll { $0 == word.id }
        recentWordIDs.insert(word.id, at: 0)
        recentWordIDs = Array(recentWordIDs.prefix(20))
        UserDefaults.standard.set(recentWordIDs, forKey: recentKey)
    }

    private var filteredCandidates: [Word] {
        switch listFilter {
        case .all:
            words
        case .favorites:
            words.filter { favoriteWordIDs.contains($0.id) }
        case .recent:
            recentWordIDs.compactMap { id in words.first { $0.id == id } }
        }
    }

    private func loadSentences(for wordID: Int) throws {
        guard sentences[wordID] == nil else { return }
        sentences[wordID] = try store?.sentences(for: wordID) ?? []
    }
}

private extension String {
    var normalizedManchuKey: String {
        trimmingCharacters(in: .whitespacesAndNewlines.union(.punctuationCharacters)).lowercased()
    }
}
