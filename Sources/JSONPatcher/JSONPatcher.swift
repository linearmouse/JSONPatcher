public class JSONPatcher {
    private let parser: JSONCParser
    private let original: String
    private let originalValue: JSONCParser.Value

    public init(original: String) throws {
        self.parser = JSONCParser(jsoncString: original)
        self.original = original
        originalValue = try parser.parse()
    }

    /**
     Strips comments and returns valid JSON.
     */
    public func json() -> String {
        var stripped = original
        for token in parser.comments.reversed() {
            stripped.removeSubrange(token.loc)
        }
        return stripped
    }
}
