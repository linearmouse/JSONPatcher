public class JSONCScanner {
    private let scanner: Scanner

    private(set) var token: Token?
    private var startIndex: String.Index

    init(jsoncString: String) {
        scanner = .init(string: jsoncString)
        startIndex = jsoncString.startIndex
    }

    func scanToken() throws -> Token {
        try nextToken()
        assert(token != nil)
        return token!
    }

    private func nextToken() throws {
        try skipWhitespace()

        guard !scanner.eof else {
            emitToken(kind: .eof)
            return
        }

        let character = try scanner.peekCharacter()
        switch character {
        case "{":
            try scanner.advance(by: 1)
            emitToken(kind: .leftBrace)
        case "}":
            try scanner.advance(by: 1)
            emitToken(kind: .rightBrace)
        case "[":
            try scanner.advance(by: 1)
            emitToken(kind: .leftBracket)
        case "]":
            try scanner.advance(by: 1)
            emitToken(kind: .rightBracket)
        case ":":
            try scanner.advance(by: 1)
            emitToken(kind: .colon)
        case ",":
            try scanner.advance(by: 1)
            emitToken(kind: .comma)
        case "n":
            try scanner.expect(expected: "null")
            emitToken(kind: .null)
        case "t":
            try scanner.expect(expected: "true")
            emitToken(kind: .true)
        case "f":
            try scanner.expect(expected: "false")
            emitToken(kind: .false)
        case "\"":
            try nextString()
        case "/":
            try nextComment()
        case "-", "0"..."9":
            try nextNumber()
        case let character:
            let loc = scanner.currentIndex ..< scanner.string.index(after: scanner.currentIndex)
            throw ParsingError.invalidCharacter(loc: loc, character: character)
        }

        try skipWhitespace()
    }

    private func skipWhitespace() throws {
    loop: while !scanner.eof {
        let character = try scanner.peekCharacter()
        switch character {
        case " ", "\n", "\r", "\t":
            try scanner.advance(by: 1)
            continue
        default:
            break loop
        }
    }

        startIndex = scanner.currentIndex
    }

    private func nextString() throws {
        assertTokenStart()
        try scanner.expect(expected: "\"")

        while !scanner.eof {
            switch try scanner.nextCharacter() {
            case "\"":
                emitToken(kind: .string)
                return
            case "\\":
                switch try scanner.nextCharacter() {
                case "\"", "\\", "/", "b", "f", "n", "r", "t":
                    break
                case "u":
                    try scanner.advance(by: 4)
                case let character:
                    let loc = scanner.string.index(before: scanner.currentIndex) ..< scanner.currentIndex
                    throw ParsingError.invalidEscapeCharacter(loc: loc, character: character)
                }
            case "\n", "\r":
                let loc = scanner.string.index(before: scanner.currentIndex) ..< scanner.currentIndex
                throw ParsingError.unexpectedEndOfString(loc: loc)
            case let character where ("\u{0}"..."\u{1f}").contains(character):
                let loc = scanner.string.index(before: scanner.currentIndex) ..< scanner.currentIndex
                throw ParsingError.invalidCharacter(loc: loc, character: character)
            default:
                break
            }
        }

        throw ParsingError.unexpectedEOF(loc: scanner.string.endIndex..<scanner.string.endIndex)
    }

    private func nextComment() throws {
        assertTokenStart()
        try scanner.expect(expected: "/")

        switch try scanner.nextCharacter() {
        case "/":
            while !scanner.eof, try scanner.peekCharacter() != "\n" {
                try scanner.advance(by: 1)
            }
            emitToken(kind: .lineComment)
        case "*":
            while true {
                while !scanner.eof, try scanner.nextCharacter() != "*" {}
                if try scanner.peekCharacter() == "/" {
                    try scanner.expect(expected: "/")
                    emitToken(kind: .blockComment)
                    break
                }
            }
        case let character:
            let loc = scanner.string.index(before: scanner.currentIndex) ..< scanner.currentIndex
            throw ParsingError.invalidCommentStart(loc: loc, character: character)
        }
    }

    private func nextNumber() throws {
        assertTokenStart()

        func consumeDigits() throws {
            switch try scanner.nextCharacter() {
            case "0":
                return
            case "1"..."9":
                while !scanner.eof, ("0"..."9").contains(try scanner.peekCharacter()) {
                    try scanner.advance(by: 1)
                }
            case let character:
                let loc = scanner.string.index(before: scanner.currentIndex) ..< scanner.currentIndex
                throw ParsingError.invalidNumberDigit(loc: loc, character: character)
            }
        }

    integer: do {
        if try scanner.peekCharacter() == "-" {
            try scanner.advance(by: 1)
        }
        try consumeDigits()
    }

    fraction: do {
        guard !scanner.eof, try scanner.peekCharacter() == "." else {
            break fraction
        }
        try scanner.advance(by: 1)
        try consumeDigits()
    }

    exponent: do {
        guard !scanner.eof else {
            break exponent
        }
        let e = try scanner.peekCharacter()
        guard e == "E" || e == "e" else {
            break exponent
        }
        try scanner.advance(by: 1)

        switch try scanner.peekCharacter() {
        case "+", "-":
            try scanner.advance(by: 1)
        default:
            break
        }
        try consumeDigits()
    }

        emitToken(kind: .numeric)
    }

    private func assertTokenStart() {
        assert(startIndex == scanner.currentIndex)
    }

    private func emitToken(kind: Token.Kind) {
        let loc = startIndex ..< scanner.currentIndex
        token = .init(kind: kind, value: scanner.string[loc], loc: loc)
    }
}

public extension JSONCScanner {
    struct Token {
        let kind: Kind
        let value: Substring
        let loc: Range<String.Index>
    }
}

public extension JSONCScanner.Token {
    enum Kind {
        case leftBrace, rightBrace
        case leftBracket, rightBracket
        case comma
        case colon
        case null
        case `true`, `false`
        case string
        case numeric
        case lineComment, blockComment
        case eof
    }
}
