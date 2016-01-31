//
//  ViewController.m
//  SamaritanF
//
//  Created by Alexander Ou on 1/31/16.
//  Copyright © 2016 ChrineApps. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController
@synthesize inputStream;
@synthesize outputStream;
@synthesize LocationManager;
@synthesize messages;
@synthesize mapView;

- (void)viewDidLoad {
    [super viewDidLoad];

    mapView.delegate = self;
    LocationManager = [[CLLocationManager alloc] init];
    LocationManager.delegate = self;
    
    LocationManager.distanceFilter = kCLDistanceFilterNone;
    LocationManager.desiredAccuracy = kCLLocationAccuracyBest;
    
    //if ([[[UIDevice currentDevice]systemVersion ] floatValue]>=8.0) {
    [LocationManager  requestAlwaysAuthorization];
    //}
    [LocationManager startUpdatingLocation];
    
    
    [self initNetworkCommunication];
    messages = [[NSMutableArray alloc]init];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations{
    NSLog(@"%f" @" " @"%f", LocationManager.location.coordinate.latitude, LocationManager.location.coordinate.longitude);
    //[LocationManager stopUpdatingLocation];
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error{
    NSLog(@"Failed");
}

- (void) initNetworkCommunication {
    CFReadStreamRef readStream;
    CFWriteStreamRef writeStream;
    CFStreamCreatePairWithSocketToHost(NULL, (CFStringRef)@"169.233.195.50", 80, &readStream, &writeStream);
    
    // did not change ownership thru bridge, error could be here
    inputStream = (__bridge NSInputStream *) readStream;
    outputStream = (__bridge NSOutputStream *) writeStream;
    
    [inputStream setDelegate:self];
    [outputStream setDelegate:self];
    
    [inputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    
    [inputStream open];
    [outputStream open];
    
    
}

- (void)stream:(NSStream *)theStream handleEvent:(NSStreamEvent)streamEvent {
    
    NSLog(@"stream event %lu", (unsigned long)streamEvent);
    
    switch (streamEvent) {
            
        case NSStreamEventOpenCompleted:
            NSLog(@"Stream opened");
            break;
        case NSStreamEventHasBytesAvailable:
            
            if (theStream == inputStream) {
                
                uint8_t buffer[1024];
                long len;
                
                while ([inputStream hasBytesAvailable]) {
                    len = [inputStream read:buffer maxLength:sizeof(buffer)];
                    if (len > 0) {
                        
                        NSString *output = [[NSString alloc] initWithBytes:buffer length:len encoding:NSASCIIStringEncoding];
                        
                        if (nil != output) {
                            
                            NSLog(@"server said: %@", output);
                            [self messageReceived:output];
                            
                            // loop through to check for distance to sound alarm
                            
                            NSString *outputMsg = [NSString stringWithFormat:@"%@", output];
                            NSArray *components = [outputMsg componentsSeparatedByString:@","];
                            NSString *latitude = [components objectAtIndex:0];
                            NSString *longitude = [components objectAtIndex:1];
                            float lati = [latitude floatValue];
                            float longi = [longitude floatValue];
                            
                            NSLog(@"siglat:%f" @"siglongi:%f", lati, longi);

                            
                            // cllocation object with lati and longi
                            CLLocation *outputCoord =[[CLLocation alloc]initWithLatitude:lati longitude:longi];
                            CLLocationDistance distance = [outputCoord distanceFromLocation:LocationManager.location];
                            
                            NSLog(@"distanceis:%f", distance);
                            
                            if (distance < 1600) {
                                //for (int i = 0; i < 50; i++) {
                                AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
                            
                                //}
                            }
                        }
                    }
                }
            }
            break;
            
            
        case NSStreamEventErrorOccurred:
            
            NSLog(@"Can not connect to the host!");
            break;
            
        case NSStreamEventEndEncountered:
            
            [theStream close];
            [theStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
            theStream = nil;
            
            break;
        default:
            NSLog(@"Unknown event");
    }
    
}

- (void) messageReceived:(NSString *)message {
    [messages addObject:message];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)panicPressed:(id)sender {
    NSString *response = [NSString stringWithFormat:@"%f" @"," @"%f", LocationManager.location.coordinate.latitude, LocationManager.location.coordinate.longitude];
    NSData *data = [[NSData alloc] initWithData:[response dataUsingEncoding:NSASCIIStringEncoding]];
    [outputStream write:[data bytes] maxLength:[data length]];

}

- (IBAction)signalPressed:(id)sender {
  
    float lati=0, longi=0;
    for (unsigned long i = 0; i < messages.count; i++) {
        //NSLog(@"thisisreceivedmsg:%@", messages[i]);
        
        NSString *coordString = [NSString stringWithFormat:@"%@", messages[i]];
        NSArray *components = [coordString componentsSeparatedByString:@","];
        NSString *latitude = [components objectAtIndex:0];
        NSString *longitude = [components objectAtIndex:1];
        lati = [latitude floatValue];
        longi = [longitude floatValue];
        
        NSLog(@"siglat:%f" @"siglongi:%f", lati, longi);
        CLLocationCoordinate2D sigLocation = CLLocationCoordinate2DMake(lati, longi);
        MKCoordinateRegion sigRegion = MKCoordinateRegionMakeWithDistance(sigLocation, 5000, 5000);
        
        [mapView setRegion:sigRegion animated:NO];
        CLLocation *sigCoord = [[CLLocation alloc]initWithLatitude:lati longitude:longi];
        MKPointAnnotation *sigPoint = [[MKPointAnnotation alloc]init];
        sigPoint.coordinate = sigCoord.coordinate;
        sigPoint.title = @"Signal here!";
        sigPoint.subtitle = @"Please help!";
        
        CLLocationDistance distance = [sigCoord distanceFromLocation:LocationManager.location];
        
        if (distance <= 1600) {
            [self.mapView addAnnotation:sigPoint];
        }
    }
    
    /*if (messages.count > 0) {
        NSLog(@"siglat:%f" @"siglongi:%f", lati, longi);
        CLLocationCoordinate2D sigLocation = CLLocationCoordinate2DMake(lati, longi);
        MKCoordinateRegion sigRegion = MKCoordinateRegionMakeWithDistance(sigLocation, 5000, 5000);
    
        [mapView setRegion:sigRegion animated:NO];
    
        MKPointAnnotation *sigPoint = [[MKPointAnnotation alloc]init];
        sigPoint.coordinate = LocationManager.location.coordinate;
        sigPoint.title = @"Signal here!";
        sigPoint.subtitle = @"Please help!";
        [self.mapView addAnnotation:sigPoint];
    //}*/

    
    
    CLLocationCoordinate2D myLocation = CLLocationCoordinate2DMake(LocationManager.location.coordinate.latitude, LocationManager.location.coordinate.longitude);
    MKCoordinateRegion myRegion = MKCoordinateRegionMakeWithDistance(myLocation, 5000, 5000);
    
    [mapView setRegion:myRegion animated:NO];
    
    MKPointAnnotation *myPoint = [[MKPointAnnotation alloc]init];
    myPoint.coordinate = LocationManager.location.coordinate;
    myPoint.title = @"You are here";
    myPoint.subtitle = @"Go help!";
    [self.mapView addAnnotation:myPoint];

}
@end
