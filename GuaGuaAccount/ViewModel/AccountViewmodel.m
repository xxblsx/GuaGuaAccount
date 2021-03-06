//
//  AccountViewmodel.m
//  GuaGuaAccount
//
//  Created by xxb on 17/1/15.
//  Copyright © 2017年 xxb. All rights reserved.
//

#import "AccountViewmodel.h"
#import "CategoryModel.h"
#import "AccountModel.h"
#import "AccountStatisticsModel.h"

#define PayOutCategoryNames @[@"饮食",@"衣服",@"护肤品",@"日用",@"外借",@"零食",@"装饰",@"电影"]
#define InComeCategoryNames @[@"工资",@"还钱"]//薪资ID必须是0
#define MonthBeginFrom 5  //每个月从5号算起

@implementation AccountViewmodel

+(void)load{
    //本地初始化类别
    int index = 0;
    CategoryModel *model;
    for(NSString *name in InComeCategoryNames){
        model = [[CategoryModel alloc] init];
        model.categoryId = [NSString stringWithFormat:@"%d", index];
        model.categoryName = name;
        model.categoryType = enumToString(TypeIncome);
        [model saveToDB];
        index ++;
    }
    for(NSString *name in PayOutCategoryNames){
        model = [[CategoryModel alloc] init];
        model.categoryId = [NSString stringWithFormat:@"%d", index];
        model.categoryName = name;
        model.categoryType = enumToString(TypePayOut);
        [model saveToDB];
        index ++;
    }
}

+(NSMutableArray*)getPayOutCategorys{
    return [CategoryModel searchWithWhere:[NSString stringWithFormat:@"categoryType='%@'", enumToString(TypePayOut)]];
}

+(NSMutableArray*)getInComeCategorys{
    return [CategoryModel searchWithWhere:[NSString stringWithFormat:@"categoryType='%@'", enumToString(TypeIncome)]];
}

+(void)getLastLeftMoneyWithBlock:(void(^)(NSString*leftCount,NSString*consumeCount))block{
    NSString *sql = @"SELECT \
                        * \
                        FROM \
                        Account \
                        WHERE \
                        time >= ( \
                             SELECT \
                             time \
                             FROM \
                             Account \
                             WHERE \
                             categoryId = '0' \
                             ORDER BY \
                             time DESC \
                             LIMIT 0, \
                             1 \
                         )";
    NSMutableArray *array = [AccountModel searchWithSQL:sql];
    NSDecimalNumber *number;
    NSDecimalNumber *inComeCount = [NSDecimalNumber decimalNumberWithString:@"0.0"];
    NSDecimalNumber *leftCount = [NSDecimalNumber decimalNumberWithString:@"0.0"];
    NSDecimalNumber *consumeCount = [NSDecimalNumber decimalNumberWithString:@"0.0"];
    for(AccountModel *model in array){
        number = [NSDecimalNumber decimalNumberWithString:model.price];
        if([model.accountType isEqualToString:enumToString(TypeIncome)]){
            //收入
            leftCount = [leftCount decimalNumberByAdding:number];
            inComeCount = [inComeCount decimalNumberByAdding:number];
        }else{
            //支出
            leftCount = [leftCount decimalNumberBySubtracting:number];
            consumeCount = [consumeCount decimalNumberByAdding:number];
        }
    }
    NSString *leftCountS;
    if(inComeCount.doubleValue <= 0){
        //如果没有录入收入的话
        leftCountS = @"--";
    }else{
        leftCountS = [NSString stringWithFormat:@"%g", leftCount.doubleValue];
    }
    block(leftCountS,[NSString stringWithFormat:@"%g", consumeCount.doubleValue]);
}

+(NSMutableArray*)getAccountByCategory{
    NSString *sql = [NSString stringWithFormat:@"SELECT \
                    *,sum(price) priceCount \
                    FROM \
                    Account \
                    WHERE accountType = '%@' \
                    GROUP BY \
                    categoryId", enumToString(TypePayOut)];
    return [AccountStatisticsModel searchWithSQL:sql];
}

+(NSMutableArray*)getAccountList{
    NSMutableArray *array = [AccountModel searchWithWhere:[NSString stringWithFormat:@"accountType = '%@'", enumToString(TypePayOut)] orderBy:@"time desc" offset:0 count:0];
    //按月份分开
    NSDate *now = [NSDate date];
    NSString *temp = [[now getFirstDateForThisMonth] formattedTimeWithFormat:timeFormat];
    NSMutableArray *arrays = [[NSMutableArray alloc] init];
    NSMutableArray *models = [[NSMutableArray alloc] init];
    for(AccountModel *model in array){
        //算出日期显示部分
        model.timeText = [self getDate:model.time];
        if([model.time compare:temp] >= 0){
            [models addObject:model];
        }else{
            //已经是上个月了
            temp = [self getLastMonth:temp];
            if(models.count > 0){
                [arrays addObject:models];
            }
            models = [[NSMutableArray alloc] init];
            [models addObject:model];
        }
    }
    if(models.count > 0){
        [arrays addObject:models];
    }
    return arrays;
}


+(NSString*)getDate:(NSString*)timeStr{
    //2016-03-02 00:00:00 zzz
    NSRange range = [timeStr rangeOfString:@"^[0-9]{4}(-[0-9]{2}){2} ([0-9]{2}:){2}[0-9]{2}$" options:NSRegularExpressionSearch];
    if(range.location == NSNotFound){
        //不符合格式不做处理
        return nil;
    }
    
    NSString *sourceTimeStr = timeStr;
    NSDateFormatter *dateFmt = [[NSDateFormatter alloc]init];
    dateFmt.dateFormat = timeFormat;
    NSDate *souceTime = [dateFmt dateFromString:sourceTimeStr];
    //取日期比较就好
    timeStr = [NSString stringWithFormat:@"%@ 00:00:00", [timeStr substringToIndex:10]];
    NSDate *date = [NSDate convertDateFromString:timeStr andFormat:timeFormat];
    NSString *nowStr = [NSString stringWithFormat:@"%@ 00:00:00", [[[NSDate date] formattedTimeWithFormat:timeFormat] substringToIndex:10]];
    NSDate *now = [NSDate convertDateFromString:nowStr andFormat:timeFormat];
    NSTimeInterval secondsInterval = [now timeIntervalSinceDate:date];
    if(secondsInterval == 0){
        //今天
        NSRange range = NSMakeRange(11, 5);
        return [NSString stringWithFormat:@"今天\r\n%@", [sourceTimeStr substringWithRange:range]];
    }else if(secondsInterval == 24 * 60 * 60){
        //昨天
        NSRange range = NSMakeRange(11, 5);
        return [NSString stringWithFormat:@"昨天\r\n%@", [sourceTimeStr substringWithRange:range]];
    }else{
        //周几
        NSString *weekDayStr;
        switch (souceTime.weekday) {
            case 1:
                weekDayStr = @"周日";
                break;
            case 2:
                weekDayStr = @"周一";
                break;
            case 3:
                weekDayStr = @"周二";
                break;
            case 4:
                weekDayStr = @"周三";
                break;
            case 5:
                weekDayStr = @"周四";
                break;
            case 6:
                weekDayStr = @"周五";
                break;
            case 7:
                weekDayStr = @"周六";
                break;
            default:
                weekDayStr = @"";
                break;
        }
        NSRange range = NSMakeRange(5, 5);
        return [NSString stringWithFormat:@"%@\r\n%@", weekDayStr, [sourceTimeStr substringWithRange:range]];
    }
}


/**
 获取上个月的该日期

 @param dateString 2017-01-01
 @return 2016-12-01
 */
+(NSString*)getLastMonth:(NSString*)dateString{
    NSDate *date = [NSDate convertDateFromString:dateString andFormat:timeFormat];
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSDateComponents *components = [calendar components:(NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay) fromDate:date];
    [components setMonth:components.month - 1];
    return [[calendar dateFromComponents:components] formattedTimeWithFormat:timeFormat];
}

/**
 根据日期获取一个月内的消费

 @param dateString 有特殊格式的
 @return 数组
 */
+(NSMutableArray*)getAccountByDate:(NSString*)dateString{
    NSDate *date = [NSDate convertDateFromString:dateString andFormat:DateSelectFormat];
    NSDate *startDateOfDay = [date getFirstDateForThisMonth];
    NSString *fMonthDay = [startDateOfDay formattedTimeWithFormat:timeFormat];//当月的第一天
    NSString *sMonthDay = [[startDateOfDay distanceByOffsetMonthes:1] formattedTimeWithFormat :timeFormat];//第二月的第一天
    NSString *sql = [NSString stringWithFormat:@"SELECT *,sum(price) priceCount FROM Account WHERE time >= '%@' AND time < '%@' AND accountType = '%@' GROUP BY categoryId ORDER BY time DESC", fMonthDay, sMonthDay, enumToString(TypePayOut)];
    return [AccountStatisticsModel searchWithSQL:sql];
}

/**
 根据日期选择的格式来返回上/下个月的日期字符串，带有回调，并且有指示日期正常与否
 
 @param dateString DateSelectFormat格式，日期从1号00:00:00
 */
+(void)getSelectDateStrBy:(NSString*)dateString monthOffset:(NSInteger)offset block:(void(^)(BOOL canNext, NSString *dateString))callBack{
    //传进来的日期
    NSDate *date = [NSDate convertDateFromString:dateString andFormat:DateSelectFormat];
    //要返回的日期
    NSDate *next1Date = [date distanceByOffsetMonthes:offset];
    NSDate *next2Date = [date distanceByOffsetMonthes:offset + 1];
    NSDate *now = [NSDate date];
    BOOL canNext = YES;
    if([next2Date timeIntervalSinceDate:now] > 0){
        canNext = NO;
    }
    callBack(canNext, [next1Date formattedTimeWithFormat:DateSelectFormat]);
}

/**
 根据日期选择的格式来返回上/下个月的日期字符串，带有回调，并且有指示日期正常与否
 
 @param date DateSelectFormat格式，日期从1号00:00:00
 */
+(void)getSelectDateBy:(NSDate*)date monthOffset:(NSInteger)offset block:(void(^)(BOOL canNext, NSDate *date))callBack{
    //要返回的日期
    NSDate *next1Date = [date distanceByOffsetMonthes:offset];
    NSDate *next2Date = [date distanceByOffsetMonthes:offset + 1];
    NSDate *now = [NSDate date];
    BOOL canNext = YES;
    if([next2Date timeIntervalSinceDate:now] > 0){
        canNext = NO;
    }
    callBack(canNext, next1Date);
}

#pragma mark -从起始日期到结束日期按照月份、类别分组获取数据

+(NSMutableArray*)getAccountListGBMonthCategoryFrom:(NSString*)from to:(NSString*)to{
    NSString *sql = [NSString stringWithFormat:@"SELECT *,sum(price) priceCount FROM Account WHERE time >= '%@' AND time < '%@' AND accountType = '%@' GROUP BY categoryId,month ORDER BY month,categoryId DESC", from, to, enumToString(TypePayOut)];
    return [AccountStatisticsModel searchWithSQL:sql];
}
@end
