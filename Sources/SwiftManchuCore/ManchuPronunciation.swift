import Foundation

public enum ManchuPronunciation {
    public static func syllableBreakdown(_ romanized: String) -> String {
        romanized
            .split(whereSeparator: \.isWhitespace)
            .map { syllables(in: String($0)).joined(separator: "-") }
            .joined(separator: " ")
    }

    public static func approximateIPA(_ romanized: String) -> String {
        let words = romanized
            .split(whereSeparator: \.isWhitespace)
            .map { word in
                syllables(in: String(word))
                    .map(ipaSyllable)
                    .joined(separator: ".")
            }
            .joined(separator: " ")

        return "/\(words)/"
    }

    private static func syllables(in word: String) -> [String] {
        let tokens = tokenize(word)
        guard tokens.contains(where: isVowel) else { return [word] }

        var result: [[String]] = []
        var current: [String] = []
        var index = 0

        while index < tokens.count {
            current.append(tokens[index])
            guard isVowel(tokens[index]) else {
                index += 1
                continue
            }

            while tokens[safe: index + 1].map(isVowel) == true {
                index += 1
                current.append(tokens[index])
            }

            let consonantStart = index + 1
            var nextVowel = consonantStart
            while nextVowel < tokens.count, !isVowel(tokens[nextVowel]) {
                nextVowel += 1
            }

            let clusterCount = nextVowel - consonantStart
            if nextVowel == tokens.count {
                if consonantStart < tokens.count {
                    current.append(contentsOf: tokens[consonantStart...])
                }
                result.append(current)
                return result.map { $0.joined() }
            }

            if clusterCount > 1 {
                current.append(tokens[consonantStart])
                index = consonantStart
            } else {
                index = consonantStart - 1
            }

            result.append(current)
            current = []
            index += 1
        }

        if !current.isEmpty {
            result.append(current)
        }
        return result.map { $0.joined() }
    }

    private static func ipaSyllable(_ syllable: String) -> String {
        tokenize(syllable).enumerated().map { offset, token in
            ipa(token, next: tokenize(syllable)[safe: offset + 1])
        }
        .joined()
    }

    private static func ipa(_ token: String, next: String?) -> String {
        return switch token {
        case "a": "a"
        case "e": "ə"
        case "i": "i"
        case "o": "ɔ"
        case "u": "u"
        case "ū": "ʊ"
        case "n": "n"
        case "ng": "ŋ"
        case "b": "p"
        case "p": "pʰ"
        case "s": "s"
        case "š": "ʃ"
        case "t": "tʰ"
        case "d": "t"
        case "l": "l"
        case "m": "m"
        case "c": "tʃʰ"
        case "j": "tʃ"
        case "y": "j"
        case "r": "r"
        case "f": "f"
        case "w": "w"
        case "k": isBack(next) ? "qʰ" : "kʰ"
        case "g": isBack(next) ? "q" : "k"
        case "h": isBack(next) ? "χ" : "x"
        default: token
        }
    }

    private static func tokenize(_ text: String) -> [String] {
        let scalars = Array(text.lowercased().unicodeScalars)
        var result: [String] = []
        var index = 0

        while index < scalars.count {
            if scalars[index] == "n", scalars[safe: index + 1] == "g" {
                result.append("ng")
                index += 2
            } else {
                result.append(String(scalars[index]))
                index += 1
            }
        }

        return result
    }

    private static func isVowel(_ token: String) -> Bool {
        ["a", "e", "i", "o", "u", "ū"].contains(token)
    }

    private static func isBack(_ token: String?) -> Bool {
        guard let token else { return false }
        return ["a", "o", "ū"].contains(token)
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
