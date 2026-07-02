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

    var selectedWordID: Word.ID?
    var searchText = ""

    var filteredWords: [Word] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return words }
        return words.filter {
            $0.manchu.localizedCaseInsensitiveContains(query)
                || $0.chinese.localizedCaseInsensitiveContains(query)
                || $0.english.localizedCaseInsensitiveContains(query)
        }
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
            self.store = store
            words = loadedWords
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

    private func loadSentences(for wordID: Int) throws {
        guard sentences[wordID] == nil else { return }
        sentences[wordID] = try store?.sentences(for: wordID) ?? []
    }
}
