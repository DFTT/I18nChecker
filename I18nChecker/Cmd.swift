//
//  Cmd.swift
//  I18nChecker
//
//  Created by dadadongl on 2024/8/19.
//

import Foundation

var ctx: LSConfig!

func cmdInit(_ dir: URL) {
    // 检测配置文件
    if let _ = try? LSConfig.parseFrom(path: dir) {
        printColoredLog("配置文件已存在", color: .green)
        return
    }

    do {
        try LSConfig.makeConfigFile(toPath: dir)
        printColoredLog("配置文件创建成功~~ ", color: .green)
    } catch let e {
        printColoredLog("创建配置文件失败~~\n\(e.localizedDescription)", color: .red)
    }
}

func cmdUpdate(_ dir: URL, keyMode: KeyFromMode) {
    // 检测配置文件
    let config: LSConfig
    do {
        config = try LSConfig.parseFrom(path: dir)
    } catch let e {
        printColoredLog("\n中断: 配置文件读取失败~~\n\(e.localizedDescription)", color: .red)
        exit(-1)
    }
    
    // 记录配置
    ctx = config
    
    // 深度扫描
    printColoredLog("开始扫描: \(config.rootDirectoryPath)", color: .green)
    let files = LSFileScanner.scan(from: URL(filePath: config.rootDirectoryPath))
    
    // 结果
    let totalMatchCount = files.reduce(0) { $0 + $1.matchedStrings.count }
    printColoredLog("扫描结束: 共找到\(totalMatchCount)个匹配项", color: .green)
    print("\n")
    
    // 检测是否需要警告
    var includeErrorStr = false
    let errorCount = files.reduce(0) { $0 + $1.errorStrings.count }
    if errorCount > 0 {
        printColoredLog("注意: 下列\(errorCount)个匹配项可能不正确(如:swift字符串中包含插值), 建议修改后重新运行本程序", color: .yellow)
        let enumrater = files.filter { $0.errorStrings.isEmpty == false }.enumerated()
        for (idx, f) in enumrater {
            printColoredLog("\(idx + 1). \(f.url.lastPathComponent)", color: .yellow)
            for s in f.errorStrings {
                printColoredLog("\t\(s)", color: .yellow)
            }
        }
    
        // 警告后 询问继续
        print("--------------------------------------")
        while true {
            printColoredLog("如不需处理, 请输入\"n\", 以\"回车键\"继续:", color: .green)
            let input = getchar()
            if input == 110 {
                // Enter key(10) , Space key(32)
                includeErrorStr = true
                break
            } else {
                printColoredLog("\n中断: 结束", color: .red)
                exit(-2)
            }
        }
    }
    // 代码中提取出来的全部key
    var allkeysFromCode = Set<String>()
    for file in files {
        for ss in file.realStrings(callingErrorStr: includeErrorStr) {
            allkeysFromCode.insert(ss)
        }
    }
    
    // 解析翻译文档
    guard let fp = LSFileParser(xmlPath: config.xlsxFilePath) else {
        printColoredLog(lastErrorMsg, color: .red)
        printColoredLog("\n中断: 翻译文档解析失败, 仅支持xlsx格式文件. \n\(config.xlsxFilePath)", color: .red)
        exit(-3)
    }
    fp.parse(headRowIdx: 0, sheetName: config.xlsxSheetName)
    if lastErrorMsg.isEmpty == false {
        printColoredLog("\n中断: \(lastErrorMsg)", color: .red)
        exit(-4)
    }
    let allKeysFromExcel = fp.allKeys
    
    // 检查文档中是否缺失key
    var hitCount = 0
    for key in allkeysFromCode.sorted() {
        if allKeysFromExcel.contains(key) == false {
            if key.hasPrefix(" ") || key.hasSuffix(" ") {
                printColoredLog("缺失: \"#\(key)#\"", color: .red)
            } else {
                printColoredLog("缺失: \"\(key)\"", color: .red)
            }
            
            hitCount += 1
        }
    }
    if hitCount > 0 {
        printColoredLog("\n\n 中断: 请补充以上\(hitCount)个缺失翻译", color: .red)
        exit(-5)
    }
    
    // 覆盖
    fp.backWrite { key in
        switch keyMode {
        case .excel:
            return true
        case .code:
            return allkeysFromCode.contains(key)
        }
    }
    printColoredLog("结束啦~~ 👏🏻👏🏻👏🏻\n\n", color: .green)
    
    // 询问是否需要打印出来 excel中已经多余的key

    print("-------------------可选操作-------------------")
    var print = false
    while true {
        printColoredLog("是否需要打印出来Excel中已废弃的key(excel中有,代码中没有), 如不需处理, 请输入\"n\", 以\"回车键\"继续:", color: .green)
#if DEBUG
        print = true
        break
#endif
        let input = getchar()
        if input == 110 {
            // Enter key(10) , Space key(32)
            print = true
        }
        break
    }
    if print {
        var hitCount = 0
        for key in allKeysFromExcel.sorted() {
            if allkeysFromCode.contains(key) == false {
                if key.hasPrefix(" ") || key.hasSuffix(" ") {
                    printColoredLog("冗余: \"#\(key)#\"", color: .red)
                } else {
                    printColoredLog("冗余: \"\(key)\"", color: .red)
                }
                hitCount += 1
            }
        }
        if hitCount > 0 {
            printColoredLog("\n: 检测到以上\(hitCount)个冗余翻译", color: .red)
        }
    }
    printColoredLog("这次真的结束啦~~ 👏🏻👏🏻👏🏻\n\n", color: .green)
}
