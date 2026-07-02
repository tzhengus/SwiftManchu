import Foundation

public enum ManchuTransliterator {
    public static func script(from romanized: String) -> String {
        var result = ""
        let scalars = Array(romanized.lowercased().unicodeScalars)
        var index = 0

        while index < scalars.count {
            let scalar = scalars[index]

            if scalar == "n", scalars[safe: index + 1] == "g" {
                result.unicodeScalars.append("\u{1829}")
                index += 2
                continue
            }

            if scalar == "k" || scalar == "g" || scalar == "h" {
                result.unicodeScalars.append(velarOrUvular(scalar, next: nextLetter(after: index, in: scalars)))
                index += 1
                continue
            }

            if let mapped = directMap[scalar] {
                result.unicodeScalars.append(mapped)
            } else {
                result.unicodeScalars.append(scalar)
            }
            index += 1
        }

        return result
    }

    private static func nextLetter(after index: Int, in scalars: [UnicodeScalar]) -> UnicodeScalar? {
        for scalar in scalars.dropFirst(index + 1) where CharacterSet.letters.contains(scalar) {
            return scalar
        }
        return nil
    }

    private static func velarOrUvular(_ scalar: UnicodeScalar, next: UnicodeScalar?) -> UnicodeScalar {
        let frontVowels: Set<UnicodeScalar> = ["e", "i", "u"]
        let front = next.map { frontVowels.contains($0) } ?? false

        return switch (scalar, front) {
        case ("k", true): "\u{183A}"
        case ("k", false): "\u{182C}"
        case ("g", _): "\u{182D}"
        case ("h", true): "\u{183B}"
        default: "\u{183E}"
        }
    }

    private static let directMap: [UnicodeScalar: UnicodeScalar] = [
        "a": "\u{1820}",
        "e": "\u{1821}",
        "i": "\u{1873}",
        "o": "\u{1823}",
        "u": "\u{1824}",
        "ū": "\u{1826}",
        "n": "\u{1828}",
        "b": "\u{182A}",
        "p": "\u{182B}",
        "s": "\u{1830}",
        "š": "\u{1831}",
        "t": "\u{1832}",
        "d": "\u{1833}",
        "l": "\u{182F}",
        "m": "\u{182E}",
        "c": "\u{1834}",
        "j": "\u{1835}",
        "y": "\u{1836}",
        "r": "\u{1837}",
        "w": "\u{1838}",
        "f": "\u{1839}",
        "z": "\u{183D}",
        "ž": "\u{183F}",
    ]
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
