import Foundation

enum DictionaryResource {
    static var databaseURL: URL? {
        #if SWIFT_PACKAGE
        Bundle.module.url(forResource: "ManchuDict", withExtension: "SQLite")
        #else
        Bundle.main.url(forResource: "ManchuDict", withExtension: "SQLite")
        #endif
    }
}
