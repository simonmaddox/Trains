//
//  NSRailConnection.h
//  NSTimes
//
//  Created by Robert Dougan on 11/29/12.
//  Copyright (c) 2012 Robert Dougan. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Train, DDXMLElement;

@protocol NSRailConnectionDataSource <NSObject>

- (NSURLRequest *)requestWithFrom:(NSString *)from to:(NSString *)to;
- (NSURLRequest *)requestForMoreWithFrom:(NSString *)from to:(NSString *)to;

- (NSString *)XPathQueryForTrains;

- (NSDate *)departureDateFromElement:(DDXMLElement *)element;
- (NSDate *)arrivalDateFromElement:(DDXMLElement *)element;
- (NSString *)platformFromElement:(DDXMLElement *)element;
- (NSString *)travelTimeFromElement:(DDXMLElement *)element;
- (NSString *)departureDelayFromElement:(DDXMLElement *)element;
- (NSString *)arrivalDelayFromElement:(DDXMLElement *)element;
- (BOOL)shouldDisplayTrain:(Train *)train;

@end

@interface NSRailConnection : NSObject

@property (nonatomic, assign) NSString *from;
@property (nonatomic, assign) NSString *to;

@property (nonatomic, assign) id <NSRailConnectionDataSource> dataSource;

+ (NSRailConnection *)sharedInstance;

#pragma mark - Fetching

- (void)fetchWithSuccess:(void (^)(NSArray *trains))success failure:(void (^)(NSError *error))failure;
- (void)fetchMoreWithSuccess:(void (^)(NSArray *trains))success failure:(void (^)(NSError *error))failure;

#pragma mark - Normalization

- (NSDate *)dateForString:(NSString *)string;
- (NSString *)normalizeString:(NSString *)string;

@end
