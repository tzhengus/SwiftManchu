import SwiftManchuCore
import SwiftUI

struct WordDetailView: View {
    let word: Word
    let sentences: [Sentence]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(word.manchu)
                        .font(.largeTitle.weight(.semibold))
                    Text(word.attribute)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }

                DictionaryField(title: "Manchu", value: word.manchu)
                DictionaryField(title: "中文", value: word.chinese)
                DictionaryField(title: "English", value: word.english)

                if !sentences.isEmpty {
                    Divider()
                    Text("Examples")
                        .font(.title2.weight(.semibold))

                    ForEach(sentences) { sentence in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(sentence.manchu)
                                .font(.headline)
                            Text(sentence.chinese)
                            Text(sentence.english)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .padding(28)
            .frame(maxWidth: 760, alignment: .leading)
        }
        .navigationTitle(word.manchu)
    }
}

private struct DictionaryField: View {
    let title: String
    let value: String

    var body: some View {
        LabeledContent {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(value)
                    .textSelection(.enabled)
                Button {
                    Clipboard.copy(value)
                } label: {
                    Image(systemName: "doc.on.doc")
                }
                .buttonStyle(.borderless)
                .help("Copy")
            }
        } label: {
            Text(title)
        }
    }
}
