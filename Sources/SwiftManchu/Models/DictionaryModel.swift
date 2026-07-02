import Foundation
import Observation
import SwiftManchuCore

@MainActor
@Observable
final class DictionaryModel {
    private(set) var words: [Word] = []
    private(set) var sentences: [Int: [Sentence]] = [:]
    private(set) var errorMessage: String?

    private var store: DictionaryStore?
    private var allSentences: [Sentence] = []
    private let favoritesKey = "favoriteWordIDs"

    var selectedWordID: Word.ID?
    var searchText = ""
    var showFavoritesOnly = false
    private(set) var favoriteWordIDs: Set<Word.ID>

    init() {
        favoriteWordIDs = Set(UserDefaults.standard.array(forKey: favoritesKey) as? [Int] ?? [])
    }

    var filteredWords: [Word] {
        let candidates = showFavoritesOnly ? words.filter { favoriteWordIDs.contains($0.id) } : words
        let wordMatches = DictionarySearch.rankedWords(candidates, query: searchText)
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return wordMatches }

        let matchedIDs = Set(sentenceMatches.map(\.wordID))
        let wordMatchIDs = Set(wordMatches.map(\.id))
        let sentenceOnlyMatches = candidates.filter {
            matchedIDs.contains($0.id) && !wordMatchIDs.contains($0.id)
        }
        return wordMatches + sentenceOnlyMatches
    }

    var sentenceMatches: [Sentence] {
        DictionarySearch.matchingSentences(allSentences, query: searchText)
    }

    var selectedWord: Word? {
        words.first { $0.id == selectedWordID } ?? words.first
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
        selectedWordID = word.id
        do {
            try loadSentences(for: word.id)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func clearError() {
        errorMessage = nil
    }

    func sentenceMatch(for word: Word) -> Sentence? {
        sentenceMatches.first { $0.wordID == word.id }
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

    private func loadSentences(for wordID: Int) throws {
        guard sentences[wordID] == nil else { return }
        sentences[wordID] = try store?.sentences(for: wordID) ?? []
    }
}
