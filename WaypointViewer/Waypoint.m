//
//  Waypoint.m
//  WaypointViewer
//
//  Created by Antony Chazapis on 12/24/13.
//  Copyright (c) 2013 Antony Chazapis. All rights reserved.
//

#import "Waypoint.h"


@implementation Waypoint

@dynamic name;
@dynamic latitude;
@dynamic longitude;
@dynamic timestamp;

- (void)awakeFromInsert {
    [super awakeFromInsert];
    
    self.timestamp = [NSDate date];
}

- (NSString *)title {
    return self.name;
}

- (CLLocationCoordinate2D)coordinate {
    return CLLocationCoordinate2DMake(self.latitude.doubleValue, self.longitude.doubleValue);
}

@end
