# I18nChecker


```
Commands:
    + init - 生成'I18nConfig.json'配置文件到当前文件夹<br>
    + update - 根据配置文件信息, 扫描当前文件夹中.m和.swift文件,
             | 提取"xx".i18n后缀的硬编码, 和excel中配置校对, 最终生成新的strings文件覆盖到指定目录
             |  Options:
             |  --keyMode [default: excel] - excel: 取excel中全部的key生成strings文件 
                                           - code: 仅取代码中提取的key生成strings文件
```

-------------------------------------------  

#### 注意: 目前只提取如下格式硬编码
```
// swift
"xxx".i18n
// oc
@"xx".i18n
```

#### 工作流程
1. 提取代码中国际化字符串, 检测是否存在异常串
2. 解析并校验excel配置表, 检测是否存在缺失/重复
3. 验证提取到的字符串配置表中是否存在
4. 生成新的strings文件覆盖到指定目录
