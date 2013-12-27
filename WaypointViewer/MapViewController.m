//
//  MapViewController.m
//  WaypointViewer
//
//  Created by Antony Chazapis on 12/24/13.
//  Copyright (c) 2013 Antony Chazapis. All rights reserved.
//

#import "MapViewController.h"
#import "Waypoint.h"

@interface MapViewController ()

@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, strong) NSTimer *waypointCleanTimer;

@property (nonatomic, strong) RscMgr *serialManager;
@property (nonatomic, strong) NSMutableString *readString;

- (void)parseWaypointInString:(NSString *)string;

@end

@implementation MapViewController

#pragma mark -
#pragma mark Controller lifecycle

- (void)viewDidLoad {
	[super viewDidLoad];
    
    self.serialManager = [[RscMgr alloc] init];
    self.serialManager.delegate = self;
    
    self.readString = [[NSMutableString alloc] init];
    
    self.textView.text = @"Nothing yet...";
    
	NSArray *mapRegionArray = [[NSUserDefaults standardUserDefaults] objectForKey:@"MapRegion"];
	MKCoordinateRegion mapRegion;
	if (mapRegionArray != nil) {
		mapRegion.center.latitude = [[mapRegionArray objectAtIndex:0] doubleValue];
		mapRegion.center.longitude = [[mapRegionArray objectAtIndex:1] doubleValue];
		mapRegion.span.latitudeDelta = [[mapRegionArray objectAtIndex:2] doubleValue];
		mapRegion.span.longitudeDelta = [[mapRegionArray objectAtIndex:3] doubleValue];
		self.mapView.region = mapRegion;
	}
    
    [self cleanWaypoints];
    self.waypointCleanTimer = [NSTimer scheduledTimerWithTimeInterval:60 target:self selector:@selector(cleanWaypoints) userInfo:nil repeats:YES];
    
    NSError *error;
	if (![self.fetchedResultsController performFetch:&error]) {
		// Update to handle the error appropriately.
		NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
		exit(-1);  // Fail
	}
    for (Waypoint *waypoint in self.fetchedResultsController.fetchedObjects)
        [self.mapView performSelectorOnMainThread:@selector(addAnnotation:) withObject:waypoint waitUntilDone:YES];
}

- (void)viewDidUnload {
    self.fetchedResultsController = nil;
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
	
	MKCoordinateRegion mapRegion = self.mapView.region;
	[[NSUserDefaults standardUserDefaults] setObject:[NSArray arrayWithObjects:
                                                      [NSNumber numberWithDouble:mapRegion.center.latitude],
                                                      [NSNumber numberWithDouble:mapRegion.center.longitude],
                                                      [NSNumber numberWithDouble:mapRegion.span.latitudeDelta],
                                                      [NSNumber numberWithDouble:mapRegion.span.longitudeDelta],
                                                      nil] forKey:@"MapRegion"];
}

- (void)parseWaypointInString:(NSString *)string {
    NSLog(@"parseWaypointInString: %@", string);
    self.textView.text = string;
    
    NSArray *part = [string componentsSeparatedByString:@","];
    if (part.count != 6 || ![part[0] isEqualToString:@"$GPWPL"]) {
        return;
    }
    
    NSString *name = [part[5] substringToIndex:[part[5] rangeOfString:@"*"].location];
    float latitude = ([part[2] isEqualToString:@"N"] ? 1 : -1) * ((int)([part[1] floatValue] / 100) + ([[part[1] substringFromIndex:2] floatValue] / 60));
    float longitude = ([part[4] isEqualToString:@"E"] ? 1 : -1) * ((int)([part[3] floatValue] / 100) + ([[part[3] substringFromIndex:3] floatValue] / 60));
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    fetchRequest.entity = [NSEntityDescription entityForName:@"Waypoint" inManagedObjectContext:self.managedObjectContext];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"name == %@", name];
    
    Waypoint *waypoint = (Waypoint *)[[self.managedObjectContext executeFetchRequest:fetchRequest error:nil] firstObject];
    if (!waypoint) {
        waypoint = (Waypoint *)[NSEntityDescription insertNewObjectForEntityForName:@"Waypoint" inManagedObjectContext:self.managedObjectContext];
        waypoint.name = name;
    }
    waypoint.latitude = [NSNumber numberWithFloat:latitude];
    waypoint.longitude = [NSNumber numberWithFloat:longitude];
}

- (void)cleanWaypoints {
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    fetchRequest.entity = [NSEntityDescription entityForName:@"Waypoint" inManagedObjectContext:self.managedObjectContext];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"timestamp < %@", [NSDate dateWithTimeIntervalSinceNow:-1800]];
    
    for (Waypoint *waypoint in [self.managedObjectContext executeFetchRequest:fetchRequest error:nil]) {
        [self.managedObjectContext deleteObject:waypoint];
    }
}

#pragma mark -
#pragma mark MKMapView delegate

- (MKAnnotationView *)mapView:(MKMapView *)theMapView viewForAnnotation:(id <MKAnnotation>)annotation {
    if (![annotation isKindOfClass:[Waypoint class]])
        return nil;
	
	MKAnnotationView *annotationView = [theMapView dequeueReusableAnnotationViewWithIdentifier:@"waypointAnnotationView"];
	if (annotationView == nil) {
		annotationView = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"waypointAnnotationView"];
        annotationView.canShowCallout = YES;
	}
	
	return annotationView;
}

#pragma mark -
#pragma mark NSFetchedResultsControllerDelegate

- (NSFetchedResultsController *)fetchedResultsController {
    if (!_fetchedResultsController) {
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        fetchRequest.entity = [NSEntityDescription entityForName:@"Waypoint" inManagedObjectContext:self.managedObjectContext];
        fetchRequest.sortDescriptors = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES]];
        _fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                        managedObjectContext:self.managedObjectContext
                                                                          sectionNameKeyPath:nil
                                                                                   cacheName:nil];
        _fetchedResultsController.delegate = self;
    }
    return _fetchedResultsController;
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath
     forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath {
    switch (type) {
        case NSFetchedResultsChangeInsert:
        case NSFetchedResultsChangeUpdate:
            [self.mapView performSelectorOnMainThread:@selector(addAnnotation:) withObject:anObject waitUntilDone:YES];
            break;
        case NSFetchedResultsChangeDelete:
            [self.mapView performSelectorOnMainThread:@selector(removeAnnotation:) withObject:anObject waitUntilDone:YES];
            break;
        case NSFetchedResultsChangeMove:
        default:
            break;
    }
}

#pragma mark -
#pragma mark RscMgrDelegate

- (void)cableConnected:(NSString *)protocol {
    [self.serialManager open];
    [self.serialManager setBaud:9600];
    [self.serialManager setDataSize:SERIAL_DATABITS_8];
    [self.serialManager setParity:SERIAL_PARITY_NONE];
    [self.serialManager setStopBits:STOPBITS_1];
    self.textView.text = @"Cable connected.";
}

- (void)cableDisconnected {
    self.textView.text = @"Cable disconnected.";
}

- (void)portStatusChanged {
    return;
}

- (void)readBytesAvailable:(UInt32)length {
    [self.readString appendString:[self.serialManager getStringFromBytesAvailable]];
    [self.readString enumerateSubstringsInRange:NSMakeRange(0, self.readString.length) options:NSStringEnumerationByLines usingBlock:^(NSString *substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop) {
        if (substringRange.length == enclosingRange.length) {
            return;
        }
        [self parseWaypointInString:substring];
        [self.readString deleteCharactersInRange:enclosingRange];
    }];
}

@end
