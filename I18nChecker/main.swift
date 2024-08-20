//
//  main.swift
//  I18nChecker
//
//  Created by dadadongl on 2024/8/7.
//

import Commander
import Foundation

//#if DEBUG
//let curDirURL = URL(filePath: "/Users/dadadongl/Desktop/works/TaTaPlanet")
//cmdInit(curDirURL)
//let kfm = KeyFromMode(rawValue: "code")!
//cmdUpdate(curDirURL, keyMode: kfm)
//#else
// 获取当前运行目录
let curDirURL = URL(filePath: FileManager.default.currentDirectoryPath)
//#endif

Group
{ group in
    group.command("init",
                  description: "生成'I18nConfig.json'配置文件到当前文件夹")
    {
        cmdInit(curDirURL)
    }

    group.command("update",
                  Option<String>("keyFrom",
                                 default: "excel",
                                 description: """
                                 excel: 取excel中全部的key生成strings文件
                                 code: 仅取代码中提取的key生成strings文件
                                 """,
                                 validator: { sp in
                                     if sp == "excel" || sp == "code"
                                     {
                                         return sp
                                     }
                                     throw NSError(domain: "", code: paramErr, userInfo: ["reason": "keyFrom only support excel/code"])
                                 }),
                  description: "根据配置文件信息, 扫描当前文件夹中.m和.swift文件, 提取\"xx\".i18n后缀的硬编码, 和excel中配置校对, 最终生成新的strings文件覆盖到指定目录")
    { km in

        let kfm = KeyFromMode(rawValue: km)!
        cmdUpdate(curDirURL, keyMode: kfm)
    }
}.run()
