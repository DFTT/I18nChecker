//
//  Regix.m
//  I18nChecker
//
//  Created by dadadongl on 2024/8/8.
//

#import "Regix.h"

@implementation Regix


+ (NSArray<NSString *> *)matchStringsFrom:(NSString *)content with:(NSString *)parten {
    return [content componentsMatchedByRegex:parten];
}
@end
