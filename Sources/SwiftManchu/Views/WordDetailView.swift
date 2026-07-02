import SwiftManchuCore
import SwiftUI

struct WordDetailView: View {
    let word: Word
    let sentences: [Sentence]
    let wordsByManchu: [String: Word]
    let onOpenWord: (Word) -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                HeaderSection(word: word, wordsByManchu: wordsByManchu, onOpenWord: onOpenWord)
                ManchuScriptPanel(romanized: word.manchu)
                PronunciationSection(romanized: word.manchu)
                DefinitionSection(word: word, wordsByManchu: wordsByManchu, onOpenWord: onOpenWord)

                if !sentences.isEmpty {
                    ExampleSection(sentences: sentences, wordsByManchu: wordsByManchu, onOpenWord: onOpenWord)
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
    let wordsByManchu: [String: Word]
    let onOpenWord: (Word) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            GlossedManchuText(text: word.manchu, wordsByManchu: wordsByManchu, font: .system(size: 48, weight: .semibold), onOpenWord: onOpenWord)

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
    let wordsByManchu: [String: Word]
    let onOpenWord: (Word) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            DictionaryRow(title: "Transliteration") {
                GlossedManchuText(text: word.manchu, wordsByManchu: wordsByManchu, font: .body, onOpenWord: onOpenWord)
            }
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
    let wordsByManchu: [String: Word]
    let onOpenWord: (Word) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Divider()

            Text("Examples")
                .font(.title2.weight(.semibold))

            ForEach(sentences) { sentence in
                VStack(alignment: .leading, spacing: 7) {
                    GlossedManchuText(text: sentence.manchu, wordsByManchu: wordsByManchu, font: .headline, onOpenWord: onOpenWord)
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

private struct GlossedManchuText: View {
    let text: String
    let wordsByManchu: [String: Word]
    let font: Font
    let onOpenWord: (Word) -> Void

    var body: some View {
        HStack(spacing: 2) {
            ForEach(Array(text.split(separator: " ").enumerated()), id: \.offset) { _, token in
                let value = String(token)
                let word = lookup(value)
                GlossedToken(value: value, word: word, font: font, tooltip: word.map(tooltip(for:)), onOpenWord: onOpenWord)
            }
        }
    }

    private func lookup(_ token: String) -> Word? {
        let key = token.normalizedManchuKey
        if let word = wordsByManchu[key] {
            return word
        }
        if key.count > 3, key.hasSuffix("i") {
            return wordsByManchu[String(key.dropLast())]
        }
        return nil
    }

    private func tooltip(for word: Word) -> String {
        [word.chinese, word.english].filter { !$0.isEmpty }.joined(separator: "\n")
    }
}

private struct GlossedToken: View {
    let value: String
    let word: Word?
    let font: Font
    let tooltip: String?
    let onOpenWord: (Word) -> Void
    @State private var isHovering = false

    var body: some View {
        if let word, let tooltip {
            Button {
                onOpenWord(word)
            } label: {
                Text(value)
                    .font(font)
                    .textSelection(.enabled)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 1)
            .padding(.vertical, 1)
            .background(isHovering ? Color.accentColor.opacity(0.14) : Color.clear, in: RoundedRectangle(cornerRadius: 3))
            .overlay(alignment: .topLeading) {
                if isHovering {
                    GlossTooltip(word: word, tooltip: tooltip)
                        .offset(y: -58)
                        .zIndex(10)
                }
            }
            .onHover { isHovering = $0 }
            .help(tooltip)
        } else {
            Text(value)
                .font(font)
                .textSelection(.enabled)
        }
    }
}

private struct GlossTooltip: View {
    let word: Word?
    let tooltip: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let word {
                Text(word.manchu)
                    .font(.headline)
            }
            Text(tooltip)
                .font(.callout)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(width: 260, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
        .shadow(radius: 8, y: 3)
    }
}

private struct DictionaryField: View {
    let title: String
    let value: String

    var body: some View {
        DictionaryRow(title: title) {
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
    }
}

private struct DictionaryRow<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(title)
                .font(.callout.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(width: 118, alignment: .leading)

            content

            Spacer(minLength: 0)
        }
    }
}

private extension String {
    var normalizedManchuKey: String {
        trimmingCharacters(in: .whitespacesAndNewlines.union(.punctuationCharacters)).lowercased()
    }
}
