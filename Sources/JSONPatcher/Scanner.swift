public typealias Loc = Range<String.Index>

class Scanner {
    let string: String

    private(set) var currentIndex: String.Index

    init(string: String) {
        self.string = string
        currentIndex = string.startIndex
    }

    var eof: Bool { currentIndex >= string.endIndex }

    func advance(by offsetBy: Int) throws {
        guard let index = string.index(currentIndex, offsetBy: offsetBy, limitedBy: string.endIndex) else {
            throw ParsingError.unexpectedEOF(loc: string.endIndex ..< string.endIndex)
        }
        currentIndex = index
    }

    func peekCharacter() throws -> Character {
        guard currentIndex < string.endIndex else {
            throw ParsingError.unexpectedEOF(loc: string.endIndex ..< string.endIndex)
        }
        return string[currentIndex]
    }

    func nextCharacter() throws -> Character {
        let character = try peekCharacter()
        try advance(by: 1)
        return character
    }

    func peekCharacters(exactCount count: Int) throws -> Substring {
        guard let endIndex = string.index(currentIndex, offsetBy: count, limitedBy: string.endIndex) else {
            throw ParsingError.unexpectedEOF(loc: string.endIndex ..< string.endIndex)
        }
        return string[currentIndex ..< endIndex]
    }

    func nextCharacters(exactCount count: Int) throws -> Substring {
        let characters = try peekCharacters(exactCount: count)
        try advance(by: count)
        return characters
    }

    func expect(expected: String) throws {
        let startIndex = currentIndex
        let actual = try nextCharacters(exactCount: expected.count)
        if actual != expected {
            throw ParsingError.unexpectedInput(loc: startIndex ..< currentIndex, actual: String(actual), expected: expected)
        }
    }
}

enum ParsingError: Error {
    case unexpectedEOF(loc: Loc)
    case unexpectedInput(loc: Loc, actual: String, expected: String)
    case invalidCommentStart(loc: Loc, character: Character)
    case invalidEscapeCharacter(loc: Loc, character: Character)
    case invalidCharacter(loc: Loc, character: Character)
    case unexpectedEndOfString(loc: Loc)
    case invalidNumberDigit(loc: Loc, character: Character)
    case valueExpected(loc: Loc)
    case unexpectedToken(loc: Loc, kind: JSONCScanner.Token.Kind)
    case commaExpected(loc: Loc)
    case memberNameExpected(loc: Loc)
    case colonExpected(loc: Loc)
    case rightBraceExpected(loc: Loc)
    case rightBracketExpected(loc: Loc)
}
