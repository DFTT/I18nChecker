//
//  LSFile.swift
//  I18nChecker
//
//  Created by dadadongl on 2024/8/9.
//

import Foundation

enum TargetFileType {
    case m
    case swift

    init?(_ ss: String) {
        switch ss {
        case "swift":
            self = .swift
        case "m":
            self = .m
        default:
            return nil
        }
    }

    /// Swift: "".i8n
    /// OC :   @"".i18n
    var regixParten: String {
        switch self {
        case .m:
            return #"@"([^"\\]|\\.{1})+?"\.i18n\b"#
        case .swift:
            return #""([^"\\]|\\.{1})+?"\.i18n\b"#
            // 如果结果中 存在\()插值  应该给与警告
        }
    }

    func targetString(from matchedString: String) -> String {
        guard let begin = matchedString.firstIndex(of: "\""),
              let end = matchedString.lastIndex(of: "\"")
        else {
            return ""
        }
        let begin_new = matchedString.index(begin, offsetBy: 1)
        return String(matchedString[begin_new ..< end])
    }
}

class LSFile {
    let url: URL
    let type: TargetFileType

    init(url: URL, type: TargetFileType) {
        self.url = url
        self.type = type
    }

    //
    private(set) var matchedStrings: Set<String> = .init()

    /// 错误的部分
    /// 比如 Swift字符串中 不能有插值
    private(set) var errorStrings: Set<String> = .init()

    func saveMatchedStrings(_ strs: [String]) {
        matchedStrings = Set(strs)

        if case .swift = type {
            // 如果结果中 存在\()插值  应该给与警告
            ///  #""发现新\(200)版本".i18n"#
            let errs = strs.filter { ele in
                ele.range(of: #"\\\(.*\)"#, options: .regularExpression) != nil
            }
            errorStrings = Set(errs)
        }
    }

    func realStrings(callingErrorStr: Bool) -> [String] {
        if callingErrorStr {
            return matchedStrings.map { type.targetString(from: $0) }
        }
        return matchedStrings.subtracting(errorStrings).map { type.targetString(from: $0) }
    }
}
