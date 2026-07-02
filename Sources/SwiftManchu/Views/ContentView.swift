import SwiftManchuCore
import SwiftUI

struct ContentView: View {
    @Bindable var model: DictionaryModel

    var body: some View {
        NavigationSplitView {
            List(model.filteredWords, selection: $model.selectedWordID) { word in
                WordRow(word: word, sentenceMatch: model.sentenceMatch(for: word))
                    .tag(word.id)
                    .onTapGesture {
                        model.select(word)
                    }
            }
            .navigationTitle("SwiftManchu")
            .searchable(text: $model.searchText, prompt: "Search words or examples")
            .overlay {
                if model.words.isEmpty && model.errorMessage == nil {
                    ProgressView()
                }
            }
        } detail: {
            if let word = model.selectedWord {
                WordDetailView(word: word, sentences: model.sentences[word.id] ?? [])
                    .task(id: word.id) {
                        model.select(word)
                    }
            } else {
                ContentUnavailableView("No Entry", systemImage: "book.closed")
            }
        }
        .alert("Dictionary Error", isPresented: errorBinding) {
            Button("OK") {
                model.clearError()
            }
        } message: {
            Text(model.errorMessage ?? "")
        }
    }

    private var errorBinding: Binding<Bool> {
        Binding(
            get: { model.errorMessage != nil },
            set: { if !$0 { model.clearError() } }
        )
    }
}

private struct WordRow: View {
    let word: Word
    let sentenceMatch: Sentence?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(word.manchu)
                .font(.headline)
            Text(word.chinese)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            if let sentenceMatch {
                Text(sentenceMatch.english)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 3)
    }
}
