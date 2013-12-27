//
//  MapViewController.h
//  WaypointViewer
//
//  Created by Antony Chazapis on 12/24/13.
//  Copyright (c) 2013 Antony Chazapis. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import <CoreLocation/CoreLocation.h>
#import "RscMgr.h"

@interface MapViewController : UIViewController <MKMapViewDelegate, NSFetchedResultsControllerDelegate, RscMgrDelegate>

@property (nonatomic, weak) IBOutlet MKMapView *mapView;
@property (nonatomic, weak) IBOutlet UITextView *textView;

@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;

@end
