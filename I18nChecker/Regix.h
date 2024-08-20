//
//  Regix.h
//  I18nChecker
//
//  Created by dadadongl on 2024/8/8.
//

#import <Foundation/Foundation.h>
#import "RegexKitLite.h"

NS_ASSUME_NONNULL_BEGIN

@interface Regix : NSObject

+ (NSArray<NSString *> *)matchStringsFrom:(NSString *)content with:(NSString *)parten;

@end

NS_ASSUME_NONNULL_END
