//
//  NSRailConnection.m
//  NSTimes
//
//  Created by Robert Dougan on 11/29/12.
//  Copyright (c) 2012 Robert Dougan. All rights reserved.
//

#import "NSRailConnection.h"

#import "Train.h"

#import "DDXML.h"
#import "AFNetworking.h"
#import "TFHpple.h"

@implementation NSRailConnection

@synthesize from = _from, to = _to;

static NSRailConnection *sharedInstance = nil;

+ (NSRailConnection *)sharedInstance {
    if (!sharedInstance) {
        sharedInstance = [[NSRailConnection alloc] init];
        [sharedInstance setFrom:@"Haarlem"];
        [sharedInstance setTo:@"Amsterdam"];
    }
    
    return sharedInstance;
}

#pragma mark - Fetching

- (void)fetchWithSuccess:(void (^)(NSArray *trains))success failure:(void (^)(NSError *error))failure
{
    NSURLRequest *urlRequest = [self.dataSource requestWithFrom:self.from to:self.to];
    
    AFHTTPRequestOperation *requestOperation = [[AFHTTPRequestOperation alloc] initWithRequest:urlRequest];
    [requestOperation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        TFHpple *document = [[TFHpple alloc] initWithHTMLData:responseObject];
        NSArray *elements = [document searchWithXPathQuery:[self.dataSource XPathQueryForTrains]];
        
        success([self trainsWithHTMLElements:elements]);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (failure) {
            failure(error);
        }
    }];
    
    [requestOperation start];
}

- (void)fetchMoreWithSuccess:(void (^)(NSArray *trains))success failure:(void (^)(NSError *error))failure
{
    NSURLRequest *urlRequest = [self.dataSource requestForMoreWithFrom:self.from to:self.to];
    
    AFHTTPRequestOperation *requestOperation = [[AFHTTPRequestOperation alloc] initWithRequest:urlRequest];
    [requestOperation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        success([self trainsWithXMLData:responseObject]);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (failure) {
            failure(error);
        }
    }];
    
    [requestOperation start];
}

#pragma mark - Element searching

- (NSArray *)trainsWithHTMLElements:(NSArray *)elements {
    NSMutableArray *trains = [NSMutableArray array];
    BOOL foundSelected = NO;
    
    for (TFHppleElement *element in elements) {
        Train *train = [[Train alloc] init];
        
        // Check if something has been selected
        if (!foundSelected) {
            if ([[element objectForKey:@"class"] isEqualToString:@"selected"]) {
                foundSelected = YES;
            } else {
                continue;
            }
        }
        
        // Simple fields
        [train setPlatform:[self normalizeString:[[element firstChildWithClassName:@"platform"] text]]];
        [train setTravelTime:[self normalizeString:[[element firstChildWithClassName:@"travel-time"] text]]];
        
        // Dates
        NSString *departureString = [NSString stringWithFormat:@"%@ %@", [self normalizeString:[[element firstChildWithClassName:@"departure-date"] text]], [self normalizeString:[[element firstChildWithClassName:@"departure"] text]]];
        NSString *arrivalString = [NSString stringWithFormat:@"%@ %@", [self normalizeString:[[element firstChildWithClassName:@"arrival-date"] text]], [self normalizeString:[[element firstChildWithClassName:@"arrival"] text]]];
        
        NSDate *departure = [self dateForString:departureString];
        [train setDeparture:departure];
        [train setArrival:[self dateForString:arrivalString]];
        
        NSInteger diff = ([departure timeIntervalSinceReferenceDate] - [NSDate timeIntervalSinceReferenceDate]) / 60;
        if (diff > 60) {
            continue;
        }
        
        // Delays
        NSArray *departureDelay = [[element firstChildWithClassName:@"departure"] childrenWithTagName:@"strong"];
        if (departureDelay && [departureDelay count] > 0) {
            [train setDepartureDelay:[self normalizeString:[[departureDelay objectAtIndex:0] text]]];
        }
        
        NSArray *arrivalDelay = [[element firstChildWithClassName:@"arrival"] childrenWithTagName:@"strong"];
        if (arrivalDelay && [arrivalDelay count] > 0) {
            [train setArrivalDelay:[self normalizeString:[[arrivalDelay objectAtIndex:0] text]]];
        }
        
        [trains addObject:train];
    }
    
    return trains;
}

- (NSArray *)trainsWithXMLData:(NSData *)data {
    NSMutableArray *trains = [NSMutableArray array];
    
    DDXMLDocument *document = [[DDXMLDocument alloc] initWithData:data options:0 error:nil];
    NSArray *elements = [document nodesForXPath:@"//reistijden/reizen/reis" error:nil];
    
    for (DDXMLElement *element in elements) {
        Train *train = [[Train alloc] init];
    
        // Simple fields
        [train setPlatform:[self.dataSource platformFromElement:element]];
        [train setTravelTime:[self.dataSource travelTimeFromElement:element]];
        
        // Delays
        
        NSString *arrivalString = [NSString stringWithFormat:@"%@ %@", [self normalizeString:[[[element nodesForXPath:@"aankomstdatum" error:nil] objectAtIndex:0] stringValue]], [self normalizeString:[[[element nodesForXPath:@"aankomst" error:nil] objectAtIndex:0] stringValue]]];

        [train setDeparture:[self.dataSource departureDateFromElement:element]];
        [train setArrival:[self dateForString:arrivalString]];
        
        NSInteger diff = ([train.departure timeIntervalSinceReferenceDate] - [NSDate timeIntervalSinceReferenceDate]) / 60;
        if (diff > 60) {
            continue;
        }
        
        [trains addObject:train];
    }
    
    return trains;
}

#pragma mark - Helpers

- (NSDate *)dateForString:(NSString *)string
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm"];
    [dateFormatter setTimeZone:[NSTimeZone systemTimeZone]];
    
    NSDate *sourceDate = [dateFormatter dateFromString:string];
    
    return sourceDate;
}

- (NSString *)normalizeString:(NSString *)string
{
    return [string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

@end
