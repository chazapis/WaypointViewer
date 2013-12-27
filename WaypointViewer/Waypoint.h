//
//  Waypoint.h
//  WaypointViewer
//
//  Created by Antony Chazapis on 12/24/13.
//  Copyright (c) 2013 Antony Chazapis. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import <MapKit/MapKit.h>


@interface Waypoint : NSManagedObject <MKAnnotation>

@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSNumber *latitude;
@property (nonatomic, retain) NSNumber *longitude;
@property (nonatomic, retain) NSDate *timestamp;

@end
