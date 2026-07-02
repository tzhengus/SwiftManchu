import SwiftManchuCore
import SwiftUI

struct WordDetailView: View {
    let word: Word
    let sentences: [Sentence]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                HeaderSection(word: word)
                ManchuScriptPanel(romanized: word.manchu)
                PronunciationSection(romanized: word.manchu)
                DefinitionSection(word: word)

                if !sentences.isEmpty {
                    ExampleSection(sentences: sentences)
                }
            }
            .padding(.horizontal, 40)
            .padding(.vertical, 34)
            .frame(maxWidth: 780, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationTitle(word.manchu)
    }
}

private struct HeaderSection: View {
    let word: Word

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(word.manchu)
                .font(.system(size: 48, weight: .semibold))
                .textSelection(.enabled)

            if !word.attribute.isEmpty {
                Text(word.attribute)
                    .font(.title3.weight(.medium))
                    .foregroundStyle(.secondary)
            }
        }
    }
}

private struct ManchuScriptPanel: View {
    let romanized: String

    private var script: String {
        ManchuTransliterator.script(from: romanized)
    }

    private var columns: [String] {
        romanized
            .split(whereSeparator: \.isWhitespace)
            .map { ManchuTransliterator.script(from: String($0)) }
    }

    private var panelWidth: CGFloat {
        min(CGFloat(max(columns.count, 1)) * 74 + 44, 300)
    }

    var body: some View {
        HStack(alignment: .center, spacing: 24) {
            ZStack(alignment: .center) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(.regularMaterial)
                HStack(alignment: .top, spacing: 18) {
                    ForEach(Array(columns.enumerated()), id: \.offset) { _, column in
                        VerticalManchuColumn(script: column)
                    }
                }
                .padding(.horizontal, 22)
            }
            .frame(width: panelWidth, height: 280)

            VStack(alignment: .leading, spacing: 8) {
                Text("Unicode Manchu")
                    .font(.headline)
                Text(romanized)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
                Button {
                    Clipboard.copy(script)
                } label: {
                    Label("Copy script", systemImage: "doc.on.doc")
                }
                .buttonStyle(.borderless)
            }

            Spacer(minLength: 0)
        }
    }
}

private struct VerticalManchuColumn: View {
    let script: String

    var body: some View {
        Text(script)
            .font(.system(size: 62))
            .lineLimit(1)
            .minimumScaleFactor(0.45)
            .frame(width: 236)
            .rotationEffect(.degrees(90), anchor: .center)
            .frame(width: 56, height: 236)
            .textSelection(.enabled)
    }
}

private struct DefinitionSection: View {
    let word: Word

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            DictionaryField(title: "Transliteration", value: word.manchu)
            DictionaryField(title: "中文", value: word.chinese)
            if !word.english.isEmpty {
                DictionaryField(title: "English", value: word.english)
            }
        }
    }
}

private struct PronunciationSection: View {
    let romanized: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Pronunciation")
                .font(.title3.weight(.semibold))

            DictionaryField(title: "Syllables", value: ManchuPronunciation.syllableBreakdown(romanized))
            DictionaryField(title: "Approx. IPA", value: ManchuPronunciation.approximateIPA(romanized))

            Text("Rule-based approximation from the transliteration; not a recorded native pronunciation.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }
}

private struct ExampleSection: View {
    let sentences: [Sentence]

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Divider()

            Text("Examples")
                .font(.title2.weight(.semibold))

            ForEach(sentences) { sentence in
                VStack(alignment: .leading, spacing: 7) {
                    Text(sentence.manchu)
                        .font(.headline)
                        .textSelection(.enabled)
                    Text(sentence.chinese)
                        .textSelection(.enabled)
                    if !sentence.english.isEmpty {
                        Text(sentence.english)
                            .foregroundStyle(.secondary)
                            .textSelection(.enabled)
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }
}

private struct DictionaryField: View {
    let title: String
    let value: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(title)
                .font(.callout.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(width: 118, alignment: .leading)

            Text(value)
                .textSelection(.enabled)

            Button {
                Clipboard.copy(value)
            } label: {
                Image(systemName: "doc.on.doc")
            }
            .buttonStyle(.borderless)
            .help("Copy")

            Spacer(minLength: 0)
        }
    }
}
