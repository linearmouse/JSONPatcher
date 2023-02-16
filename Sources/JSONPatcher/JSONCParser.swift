class JSONCParser {
    private let scanner: JSONCScanner
    private(set) var comments: [Token] = []

    init(jsoncString: String) {
        scanner = .init(jsoncString: jsoncString)
    }

    func parse() throws -> Value {
        try scanNext()
        let value = try parseValue()
        guard scanner.token.kind == .eof else {
            throw ParsingError.unexpectedToken(loc: scanner.token.loc,
                                               got: scanner.token.kind,
                                               wanted: .eof)
        }
        return value
    }

    @discardableResult
    private func scanNext() throws -> Token {
        while true {
            let token = try scanner.scanToken()
            switch token.kind {
            case .lineComment, .blockComment:
                comments.append(token)
                break
            default:
                return token
            }
        }
    }

    private func parseValue() throws -> Value {
        let token = scanner.token
        switch token.kind {
        case .unknown:
            fatalError()
        case .eof:
            throw ParsingError.valueExpected(loc: token.loc, got: .eof)
        case .leftBrace:
            return try parseObject()
        case .leftBracket:
            return try parseArray()
        case .string:
            try scanNext()
            return .string(token)
        case .numeric:
            try scanNext()
            return .number(token)
        case .true:
            try scanNext()
            return .true(token)
        case .false:
            try scanNext()
            return .false(token)
        case .null:
            try scanNext()
            return .null(token)
        default:
            throw ParsingError.unexpectedToken(loc: token.loc, got: token.kind)
        }
    }

    private func parseObject() throws -> Value {
        var members: [(name: Value, value: Value)] = []

        let leftBrace = scanner.token
        assert(leftBrace.kind == .leftBrace)
        try scanNext() // {

        var needsComma = false
    parseMembers: while true {
        switch scanner.token.kind {
        case .rightBrace, .eof:
            break parseMembers
        case .comma:
            if !needsComma {
                throw ParsingError.valueExpected(loc: scanner.token.loc, got: .comma)
            }
            try scanNext() // ,
        case let kind:
            if needsComma {
                throw ParsingError.unexpectedToken(loc: scanner.token.loc, got: kind, wanted: .comma)
            }
        }

    parseMember: do {
        guard scanner.token.kind == .string else {
            throw ParsingError.memberNameExpected(loc: scanner.token.loc, got: scanner.token.kind)
        }
        let memberName = try parseValue()
        guard scanner.token.kind == .colon else {
            throw ParsingError.unexpectedToken(loc: scanner.token.loc, got: scanner.token.kind, wanted: .colon)
        }
        try scanNext() // :
        let memberValue = try parseValue()
        members.append((name: memberName, value: memberValue))
    }

        needsComma = true
    }

        let rightBrace = scanner.token
        guard rightBrace.kind == .rightBrace else {
            throw ParsingError.unexpectedToken(loc: rightBrace.loc, got: rightBrace.kind, wanted: .rightBrace)
        }
        try scanNext() // }

        return .object(leftBrace: leftBrace, members: members, rightBrace: rightBrace)
    }

    private func parseArray() throws -> Value {
        var elements: [Value] = []

        let leftBracket = scanner.token
        assert(leftBracket.kind == .leftBracket)
        try scanNext() // [

        var needsComma = false
    parseElements: while true {
        switch scanner.token.kind {
        case .rightBracket, .eof:
            break parseElements
        case .comma:
            if !needsComma {
                throw ParsingError.valueExpected(loc: scanner.token.loc, got: .comma)
            }
            try scanNext() // ,
        case let kind:
            if needsComma {
                throw ParsingError.unexpectedToken(loc: scanner.token.loc, got: kind, wanted: .comma)
            }
        }

    parseElement: do {
        let elementValue = try parseValue()
        elements.append(elementValue)
    }

        needsComma = true
    }

        let rightBracket = scanner.token
        guard rightBracket.kind == .rightBracket else {
            throw ParsingError.unexpectedToken(loc: rightBracket.loc, got: rightBracket.kind, wanted: .rightBracket)
        }
        try scanNext() // ]

        return .array(leftBracket: leftBracket, elements: elements, rightBracket: rightBracket)
    }
}

extension JSONCParser {
    typealias Token = JSONCScanner.Token

    enum Value {
        case object(leftBrace: Token, members: [(name: Value, value: Value)], rightBrace: Token)
        case array(leftBracket: Token, elements: [Value], rightBracket: Token)
        case string(Token)
        case number(Token)
        case `true`(Token)
        case `false`(Token)
        case `null`(Token)
    }
}

extension JSONCParser.Value {
    func encode() -> String {
        switch self {
        case .object(leftBrace: _, members: let members, rightBrace: _):
            let membersEncoded = members
                .map { (name, value) in
                    "\(name.encode()):\(value.encode())"
                }
                .joined(separator: ",")
            return "{\(membersEncoded)}"
        case .array(leftBracket: _, elements: let elements, rightBracket: _):
            let elementsEncoded = elements
                .map { $0.encode() }
                .joined(separator: ",")
            return "[\(elementsEncoded)]"
        case .string(let token):
            return String(token.value)
        case .number(let token):
            return String(token.value)
        case .true(_):
            return "true"
        case .false(_):
            return "false"
        case .null(_):
            return "null"
        }
    }
}
