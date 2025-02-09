/*
 Copyright 2025 macoonshine
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

import Foundation

let _NON_SPECIALS = CharacterSet(charactersIn: "-_0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ")
let _ESCAPES = Set("\"\\".map { $0 })
let _STRING_SPECIALS = CharacterSet(charactersIn: "\\\"")

/// represents media types according to [RFC2045 Section 5.1](https://www.rfc-editor.org/rfc/rfc2045#section-5.1).
public struct MediaType: Sendable, Hashable, Codable, Comparable, CustomStringConvertible {
    /// represents the type of a media type. Standard types according to
    /// [IANA media types, Feb. 4, 2025](https://www.iana.org/assignments/media-types/media-types.xhtml).
    public enum MainType: Sendable, Hashable, Codable, Comparable, CustomStringConvertible, ExpressibleByStringLiteral {
        case application
        case audio
        case example
        case font
        case haptics
        case image
        case message
        case model
        case multipart
        case text
        case video
        case ietf(String)
        case `extension`(String)
        
        private static let _standardTypes: [Self] = [
            .application,
            .audio,
            .example,
            .font,
            .haptics,
            .image,
            .message,
            .model,
            .multipart,
            .text,
            .video
        ]
        /// contains all simple, parameter-less cases
        public static let standardTypes = Set(_standardTypes)

        public init(_ rawValue: String) {
            let literal = rawValue.lowercased()
            
            switch literal {
            case "application":
                self = .application
            case "audio":
                self = .audio
            case "example":
                self = .example
            case "font":
                self = .font
            case "haptics":
                self = .haptics
            case "image":
                self = .image
            case "message":
                self = .message
            case "model":
                self = .model
            case "multipart":
                self = .multipart
            case "text":
                self = .text
            case "video":
                self = .video
            default:
                self = literal.hasPrefix("x-") ? .extension(rawValue) : .ietf(rawValue)
            }
        }
        
        public init(stringLiteral: String) {
            self.init(stringLiteral)
        }
        
        public static func == (lhs: Self, rhs: Self) -> Bool {
            switch (lhs, rhs) {
            case (.application, .application), (.audio, .audio),
                (.example, .example), (.font, .font), (.haptics, .haptics),
                (.image, .image), (.message, .message), (.model, .model),
                (.multipart, .multipart), (.text, .text), (.video, .video):
                return true
            case (.ietf(let left), .ietf(let right)),
                (.extension(let left), .extension(let right)):
                return left.caseInsensitiveCompare(right) == .orderedSame
            default:
                return false
            }
        }

        public static func < (lhs: Self, rhs: Self) -> Bool {
            guard lhs != rhs else { return false }
            let leftIndex = _standardTypes.firstIndex(of: lhs) ?? _standardTypes.count
            let rightIndex = _standardTypes.firstIndex(of: rhs) ?? _standardTypes.count
            
            if leftIndex < rightIndex {
                return true
            }
            else if leftIndex > rightIndex {
                return false
            }
            else {
                switch (lhs, rhs) {
                case (.ietf(_), .extension(_)):
                    return true
                case (.ietf(let left), .ietf(let right)):
                    return left.caseInsensitiveCompare(right) == .orderedAscending
                case (.extension(let left), .extension(let right)):
                    return left.caseInsensitiveCompare(right) == .orderedAscending
                default:
                    return false
                }
            }
        }
        

        public func hash(into hasher: inout Hasher) {
            hasher.combine(description.lowercased())
        }
        
        public var description: String {
            switch self {
            case .application:
                return "application"
            case .audio:
                return "audio"
            case .example:
                return "example"
            case .font:
                return "font"
            case .haptics:
                return "haptics"
            case .image:
                return "image"
            case .message:
                return "message"
            case .model:
                return "model"
            case .multipart:
                return "multipart"
            case .text:
                return "text"
            case .video:
                return "video"
            case .ietf(let string):
                return string
            case .extension(let string):
                return string
            }
        }
    }
    /// a parameter of a media type.
    public struct Parameter: Sendable, Hashable, CustomStringConvertible {
        /// name of parameter
        public var name: String {
            didSet {
                didUpdate()
            }
        }
        /// value of parameter
        public var value: String {
            didSet {
                didUpdate()
            }
        }
        private(set) public var description: String
        
        /// initializes a parameter by name and value.
        /// - Parameters:
        ///   - name: name of parameter
        ///   - value: value of parameter
        public init(name: String, value: String) {
            self.name = name
            self.value = value
            self.description = ""
            didUpdate()
        }
        
        public static func charset(_ encoding: String.Encoding) -> Self! {
            if let name = encoding.ianaCharsetName {
                return .init(name: "charset", value: name)
            }
            else {
                return nil
            }
        }
        
        public func hash(into hasher: inout Hasher) {
            hasher.combine(name.lowercased())
            hasher.combine(value.lowercased())
        }
        
        public static func == (lhs: Self, rhs: Self) -> Bool {
            return lhs.name.caseInsensitiveCompare(rhs.name) == .orderedSame &&
            lhs.value.caseInsensitiveCompare(rhs.value) == .orderedSame
        }
        
        /// checks if parameter has given name.
        /// - Parameter name: name to be checked
        /// - Returns: true if parameter has given name
        public func has(name: String) -> Bool {
            return name.caseInsensitiveCompare(self.name) == .orderedSame
        }
        
        private mutating func didUpdate() {
            func quoted() -> String {
                var needsQuotes: Bool = false

                let result = value.map {
                    if let character = $0.unicodeScalars.first,
                        _NON_SPECIALS.contains(character) {
                        return String($0)
                    }
                    else {
                        needsQuotes = true
                        if _ESCAPES.contains($0) {
                            return "\\\($0)"
                        }
                        else if let ascii = $0.asciiValue {
                            return  ascii >= 32 && ascii < 127 ? String($0) : String(format: "\\x%02x", ascii)
                        }
                        else {
                            return String($0)
                        }
                    }
                }
                return needsQuotes ? "\"\(result.joined())\"" : result.joined()
            }
            
            description = "\(name)=\(quoted())"
        }
        
        static func parse(scanner: Scanner) -> Self? {
            let ignoredCharacters = scanner.charactersToBeSkipped
            
            scanner.charactersToBeSkipped = nil
            defer { scanner.charactersToBeSkipped = ignoredCharacters }
            
            _ = scanner.scanCharacters(from: .whitespaces)
            guard let name = scanner.scanCharacters(from: _NON_SPECIALS),
                  scanner.scanString("=") != nil else { return nil }
            if scanner.scanString("\"") == nil {
                let value = scanner.scanCharacters(from: _NON_SPECIALS) ?? ""
                
                return .init(name: name, value: value)
            }
            else {
                var value = ""
                
                while scanner.scanString("\"") == nil {
                    let part = scanner.scanUpToCharacters(from: _STRING_SPECIALS) ?? ""

                    value += part
                    if scanner.scanString("\\") != nil {
                        let c = scanner.scanCharacter()
                        
                        switch c {
                        case "n":
                            value += "\n"
                        case "r":
                            value += "\r"
                        case "t":
                            value += "\t"
                        case "u":
                            if let ordinal = scanner.scanUInt64(length: 4, radix: 16),
                               let scalar = UnicodeScalar(Int(ordinal)) {
                                value += String(Character(scalar))
                            }
                            else {
                                return nil
                            }
                        case "x":
                            if let ordinal = scanner.scanUInt64(length: 2, radix: 16),
                               let scalar = UnicodeScalar(Int(ordinal)) {
                                value += String(Character(scalar))
                            }
                            else {
                                return nil
                            }
                        case .none:
                            return nil
                        default:
                            value += String(c!)
                        }
                    }
                }
                return .init(name: name, value: value)
            }
        }
    }
    
    /// type of media type.
    public var type: MainType {
        didSet {
            didUpdate()
        }
    }
    /// subtype of media type.
    public var subtype: String {
        didSet {
            didUpdate()
        }
    }
    /// parameters of media type
    private(set) public var parameters: [Parameter]
    private(set) public var description: String
    
    public init(type: MainType, subtype: String, parameters: [Parameter]) {
        self.type = type
        self.subtype = subtype
        self.parameters = parameters
        self.description = ""
        didUpdate()
    }
    
    public init(type: MainType, subtype: String, parameters: Parameter...) {
        self.init(type: type, subtype: subtype, parameters: parameters)
    }
    
    public init?(_ rawValue: String) {
        let scanner = Scanner(string: rawValue)

        self.parameters = []
        guard let type = scanner.scanCharacters(from: _NON_SPECIALS),
              scanner.scanString("/") != nil else { return nil }
        self.type = .init(type)
        self.description = ""
        guard let subtype = scanner.scanUpToString(";") else { return nil }
        self.subtype = subtype
        scanner.charactersToBeSkipped = .whitespaces
        while !scanner.isAtEnd {
            guard scanner.scanString(";") != nil else { return nil }
            guard let parameter = Parameter.parse(scanner: scanner) else { return nil }
            
            setParameter(value: parameter.value, for: parameter.name)
        }
        self.description = rawValue
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        
        self.init(rawValue)!
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        try container.encode(description)
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(type)
        hasher.combine(subtype.lowercased())
        hasher.combine(parameters)
    }
 
    public static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.type == rhs.type &&
        lhs.subtype.caseInsensitiveCompare(lhs.subtype) == .orderedSame &&
        lhs.parameters == rhs.parameters
    }
    
    public static func < (lhs: Self, rhs: Self) -> Bool {
        if lhs.type < rhs.type {
            return true
        }
        else if lhs.type > rhs.type {
            return false
        }
        else {
            return lhs.description.caseInsensitiveCompare(rhs.description) == .orderedAscending
        }
    }
    
    private mutating func didUpdate() {
        var description = basicType
        
        if parameters.count > 0 {
            description += "; \(parameters.map(\.description).joined(separator: "; "))"
        }
        self.description = description
    }
    
    /// sets or adds a parameter with given name and value to this media type.
    /// - Parameters:
    ///   - value: value of parameter
    ///   - name: name of parameter
    public mutating func setParameter(value: String, for name: String) {
        if let index = parameters.firstIndex(where: { $0.has(name: name) }) {
            parameters[index] = .init(name: name, value: value)
        }
        else {
            parameters.append(.init(name: name, value: value))
        }
        didUpdate()
    }
  
    /// removes the parameter with given name and value to this media type.
    /// - Parameters: name: name of parameter
    public mutating func removeParameter(for name: String) {
        parameters.removeAll(where: { $0.has(name: name) })
        didUpdate()
    }

    /// returns the value for the parameter with given name.
    /// - Parameter name: name of desired parameter
    /// - Returns: value of parameter with given name or nil otherwise
    public func parameterValue(for name: String) -> String? {
        return parameters.first(where: { $0.has(name: name) })?.value
    }
    
    /// returns a string representation of the media type without parameters.
    public var basicType: String {
        return "\(type)/\(subtype)"
    }
    
    /// returns the `String.Encoding` for the `charset` parameter.
    /// - Returns: the `String.Encoding` or `nil`, if not `charset` parameter is found or its value is no valid character set name.
    public var charset: String.Encoding? {
        if let charsetName = parameterValue(for: "charset") {
            return String.Encoding(ianaCharsetName: charsetName)
        }
        else {
            return nil
        }
    }
}

public extension MediaType {
    private static var magic: Magic {
        return .init(flags: .mime, definitions: .default, .system, .builtin)!
    }
    
    /// creates the media type for the file at the given path.
    /// - Parameter path: a path to a file
    init?(path: String) {
        if let mimeType = Self.magic.file(path: path) {
            self.init(mimeType)
        }
        else {
            return nil
        }
    }
    
    /// creates the media type for the given data..
    /// - Parameter data: a data object
    init?(data: Data) {
        if let mimeType = Self.magic.file(data: data) {
            self.init(mimeType)
        }
        else {
            return nil
        }
    }
}

extension Scanner {
    func lookahead(length: Int) -> String? {
        let startIndex = currentIndex
        let endIndex = string.index(startIndex, offsetBy: length)
        
        return endIndex > string.endIndex ? nil : String(string[startIndex..<endIndex])
    }
    
    func scanUInt64(length: Int, radix: Int) -> UInt64? {
        if let prefix = lookahead(length: length), let value = UInt64(prefix, radix: radix) {
            _ = scanString(prefix)
            return value
        }
        else {
            return nil
        }
    }
    
    func scanHexadecimalCharacter(length: Int) -> Character? {
        var value = ""
        
        for _ in 0..<length {
            if let digit = scanCharacter() {
                switch digit {
                case "0", "1", "2", "3", "4", "5", "6", "7", "8", "9",
                    "a", "b", "c", "d", "e", "f", "A", "B", "C", "D", "E", "F":
                    value += String(digit)
                default:
                    return nil
                }
            }
        }
        if let value = Int(value, radix: 16), let scalar = UnicodeScalar(value) {
            return Character(scalar)
        }
        else {
            return nil
        }
    }
}
