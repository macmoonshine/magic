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

import libmagic
import UniformTypeIdentifiers

/// a Swift wrapper for libmagic.
public class Magic {
    /// constants describing the location of the mime type definitions.
    public enum Definition: ExpressibleByStringLiteral {
        /// the definition contained in this bundle.
        case builtin
        /// the default path used by libmagic.
        case `default`
        /// definition location is provided by the environment variable `MAGIC`.
        case environment
        /// explicit specification of a path
        case path(String)
        /// definition used by system (file command)
        case system
        
        /// create a `.path` by a string literal.
        /// - Parameter value: a path to a definition file
        public init(stringLiteral path: String) {
            self = .path(path)
        }
        
        /// returns the path in the file system if existing, and nil otherwise.
        public var filesystemPath: String? {
            func existingFile(_ path: String?) -> String? {
                if let path = path,
                   FileManager.default.isReadableFile(atPath: path) {
                    return path
                }
                else {
                    return nil
                }
            }
            
            switch self {
            case .builtin:
                let bundle = Bundle(for: Magic.self)

                return bundle.path(forResource: "magic", ofType: "mgc")
            case .environment:
                let path = ProcessInfo.processInfo.environment["MAGIC"]
                
                return existingFile(path)
            case .default:
                let path = String(utf8String: magic_getpath(nil, 0))
                
                return existingFile(path)
            case .path(let path):
                return path
            case .system:
                return existingFile(Magic.systemMagicFile)
            }
        }
    }
    
    /// Flags influence the way the results are calculated.
    public struct Flags: OptionSet, Sendable {
        public let rawValue: Int32
        
        public init(rawValue: Int32) {
            self.rawValue = rawValue
        }
        
        /// no flags
        public static let none = Self([])
        /// Turn on debugging
        public static let debug = Flags(rawValue: 0x0000001)
        /// Follow symlinks
        public static let symlink = Flags(rawValue: 0x0000002)
        /// Check inside compressed files
        public static let compress = Flags(rawValue: 0x0000004)
        /// Look at the contents of devices
        public static let devices = Flags(rawValue: 0x0000008)
        /// Return the MIME type
        public static let mimeType = Flags(rawValue: 0x0000010)
        /// Return all matches
        public static let allMatches = Flags(rawValue: 0x0000020)
        /// Print warnings to stderr
        public static let check = Flags(rawValue: 0x0000040)
        /// Restore access time on exit
        public static let preserveATime = Flags(rawValue: 0x0000080)
        /// Don't convert unprintable chars
        public static let raw = Flags(rawValue: 0x0000100)
        /// Handle ENOENT etc as real errors
        public static let error = Flags(rawValue: 0x0000200)
        /// Return the MIME encoding
        public static let mimeEncoding = Flags(rawValue: 0x0000400)
        /// .mimeType + .mimeEncoding
        public static let mime: Self = [.mimeType, .mimeEncoding]
        /// Return the Apple creator/type
        public static let apple = Flags(rawValue: 0x0000800)
        /// Return a /-separated list of extensions
        public static let extensions = Flags(rawValue: 0x1000000)
        /// Check inside compressed files but not report compression
        public static let compreeTransp = Flags(rawValue: 0x2000000)
        /// Don't allow decompression that needs to fork
        public static let noCompressFork = Flags(rawValue: 0x4000000)
        /// .extensions + .mime + .apple
        public static let nodesc: Self = [.extensions, .mime, .apple]
        
        /// Don't check for tar files
        public static let noCheckTAR = Flags(rawValue: 0x0002000)
        /// Don't check magic entries
        public static let noCheckSoft = Flags(rawValue: 0x0004000)
        /// Don't check application type
        public static let noCheckApptype = Flags(rawValue: 0x0008000)
        /// Don't check for elf details
        public static let noCheckELF = Flags(rawValue: 0x0010000)
        /// Don't check for text files
        public static let noCheckText = Flags(rawValue: 0x0020000)
        /// Don't check for cdf files
        public static let noCheckCDF = Flags(rawValue: 0x0040000)
        /// Don't check for csv files
        public static let noCheckCSV = Flags(rawValue: 0x0080000)
        /// Don't check tokens
        public static let noCheckTokens = Flags(rawValue: 0x0100000)
        /// Don't check text encodings
        public static let noCheckEncoding = Flags(rawValue: 0x0200000)
        /// Don't check for JSON files
        public static let noCheckJSON = Flags(rawValue: 0x0400000)
        /// Don't check for SIMH tape files
        public static let noCheckSIMH = Flags(rawValue: 0x0800000)
    }
    
    private static let systemMagicFile = "/usr/share/file/magic.mgc"
    private let magic: magic_t
    
    /// version of libmagic as Int.
    public var version: Int {
        Int(magic_version())
    }
    
    /// a new Magic for the given parameters. Only returns an object if a definition could be loaded. Only
    /// the first available definition is loaded.
    /// - Parameters:
    ///   - flags: flags for result calculation
    ///   - definitions: file paths to the definitions. Only the first available definition is loaded.
    init?(flags: Flags = .mimeType, definitions: Definition...) {
        if let magic = magic_open(flags.rawValue) {
            for d in definitions {
                if let path = d.filesystemPath,
                    magic_load(magic, path) == 0 {
                    self.magic = magic
                    return
                }
            }
            magic_close(magic)
            return nil
        }
        else {
            return nil
        }
    }
    
    deinit {
        magic_close(magic)
    }
    
    /// resolves mime type for a file at the given path by the file content.
    /// - Parameter path: a path to a file
    /// - Returns: mime type of the file
    public func file(path: String) -> String? {
        if let result = magic_file(self.magic, path) {
            return String(cString: result)
        }
        else {
            return nil
        }
    }
    
    /// resolves mime type for given data.
    /// - Parameter data: a data object
    /// - Returns: mime type of the data object
    public func file(data: Data) -> String? {
        data.withUnsafeBytes {
            if let pointer = $0.baseAddress,
               let result = magic_buffer(self.magic, pointer, data.count) {
                return String(cString: result)
            }
            else {
                return nil
            }
        }
    }
}
