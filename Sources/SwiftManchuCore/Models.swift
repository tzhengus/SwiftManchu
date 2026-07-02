import Foundation

public struct Word: Identifiable, Hashable, Sendable {
    public let id: Int
    public let manchu: String
    public let chinese: String
    public let english: String
    public let attribute: String

    public init(id: Int, manchu: String, chinese: String, english: String, attribute: String) {
        self.id = id
        self.manchu = manchu
        self.chinese = chinese
        self.english = english
        self.attribute = attribute
    }
}

public struct Sentence: Identifiable, Hashable, Sendable {
    public let id: Int
    public let manchu: String
    public let chinese: String
    public let english: String
    public let wordID: Int

    public init(id: Int, manchu: String, chinese: String, english: String, wordID: Int) {
        self.id = id
        self.manchu = manchu
        self.chinese = chinese
        self.english = english
        self.wordID = wordID
    }
}
