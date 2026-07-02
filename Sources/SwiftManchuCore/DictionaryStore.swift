import Foundation
import SQLite3

public final class DictionaryStore: @unchecked Sendable {
    private let database: OpaquePointer?

    public init(databaseURL: URL) throws {
        var handle: OpaquePointer?
        let code = sqlite3_open_v2(databaseURL.path, &handle, SQLITE_OPEN_READONLY, nil)
        guard code == SQLITE_OK else {
            let message = handle.map { String(cString: sqlite3_errmsg($0)) } ?? "unknown sqlite error"
            sqlite3_close(handle)
            throw StoreError.openFailed(message)
        }
        database = handle
    }

    deinit {
        sqlite3_close(database)
    }

    public func words(matching query: String = "") throws -> [Word] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return try fetchWords(sql: "select id, mnc, chn, eng, coalesce(attribute, '') from Word order by id", bindings: [])
        }

        let pattern = "%\(trimmed)%"
        return try fetchWords(
            sql: """
            select id, mnc, chn, eng, coalesce(attribute, '')
            from Word
            where mnc like ? or chn like ? or eng like ?
            order by id
            """,
            bindings: [pattern, pattern, pattern]
        )
    }

    public func sentences(for wordID: Int) throws -> [Sentence] {
        try withStatement(
            sql: """
            select sentid, sentmnc, sentchn, senteng, wordid
            from Sentence
            where wordid = ?
            order by sentid
            """,
            bindings: [String(wordID)]
        ) { statement in
            var result: [Sentence] = []
            while sqlite3_step(statement) == SQLITE_ROW {
                result.append(Sentence(
                    id: Int(sqlite3_column_int(statement, 0)),
                    manchu: text(statement, 1),
                    chinese: text(statement, 2),
                    english: text(statement, 3),
                    wordID: Int(sqlite3_column_int(statement, 4))
                ))
            }
            return result
        }
    }

    private func fetchWords(sql: String, bindings: [String]) throws -> [Word] {
        try withStatement(sql: sql, bindings: bindings) { statement in
            var result: [Word] = []
            while sqlite3_step(statement) == SQLITE_ROW {
                result.append(Word(
                    id: Int(sqlite3_column_int(statement, 0)),
                    manchu: text(statement, 1),
                    chinese: text(statement, 2),
                    english: text(statement, 3),
                    attribute: text(statement, 4)
                ))
            }
            return result
        }
    }

    private func withStatement<T>(sql: String, bindings: [String], body: (OpaquePointer?) throws -> T) throws -> T {
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(database, sql, -1, &statement, nil) == SQLITE_OK else {
            throw StoreError.queryFailed(errorMessage)
        }
        defer { sqlite3_finalize(statement) }

        for (offset, value) in bindings.enumerated() {
            sqlite3_bind_text(statement, Int32(offset + 1), value, -1, SQLITE_TRANSIENT)
        }

        return try body(statement)
    }

    private var errorMessage: String {
        database.map { String(cString: sqlite3_errmsg($0)) } ?? "unknown sqlite error"
    }
}

public enum StoreError: LocalizedError {
    case openFailed(String)
    case queryFailed(String)

    public var errorDescription: String? {
        switch self {
        case .openFailed(let message): "Could not open dictionary: \(message)"
        case .queryFailed(let message): "Dictionary query failed: \(message)"
        }
    }
}

private func text(_ statement: OpaquePointer?, _ column: Int32) -> String {
    guard let raw = sqlite3_column_text(statement, column) else { return "" }
    return String(cString: raw)
}

private let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
