//
//  NSDate+Common.h
//  GuaGuaAccount
//
//  Created by xxb on 17/1/20.
//  Copyright © 2017年 xxb. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDate (Common)

-(NSString *)formattedTimeWithFormat:(NSString *)dateFormat;

/**
 字符串转日期

 @param dateString 字符串
 @param formatter 字符串格式
 @return 日期
 */
+(NSDate*) convertDateFromString:(NSString*)dateString andFormat:(NSString*)formatter;

/**
 获取年份

 @return 年
 */
- (NSInteger) year;

/**
 获取月份

 @return 月
 */
- (NSInteger) month;

/**
 获取周几

 @return 几
 */
- (NSInteger) weekday;

/**
 根据偏移量算出偏移到了几月份

 @param currentMonth 当前月份
 @param offset 偏移量
 @return 求出的月份
 */
-(NSInteger)getMonthByOffset:(NSInteger)offset;

/**
 根据偏移量算出偏移到了第几年

 @param currentYear 当年
 @param currentMonth 当前月份
 @param offset 偏移量
 @return 求出的年份
 */
-(NSInteger)getYearByOffset:(NSInteger)offset;
@end
