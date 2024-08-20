//
//  LSPrint.swift
//  I18nChecker
//
//  Created by dadadongl on 2024/8/9.
//

import Foundation

enum LogColor: String {
    case red = "\u{001B}[31m"
    case green = "\u{001B}[32m"
    case yellow = "\u{001B}[33m"
    case blue = "\u{001B}[34m"
    case reset = "\u{001B}[0m" // reset 用来确保在彩色文本之后的所有文本恢复到默认颜色，这在需要混合不同样式的日志输出时非常有用
}

func printColoredLog(_ message: String, color: LogColor) {
    print("\(color.rawValue)\(message)\(LogColor.reset.rawValue)")
}
