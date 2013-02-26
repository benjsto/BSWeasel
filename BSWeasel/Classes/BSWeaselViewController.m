//
//  BSWeaselViewController.m
//  BSWeasel
//
//  Created by Benjamin Stockwell on 2/13/13.
//
//

#import "BSWeaselViewController.h"
#import "ImageHelper.h"
#import "FitnessCalculator.h"

@interface BSWeaselViewController ()

@property (atomic, retain) UIImage* myImage;
@property (atomic, retain) UIImageView *imageView;

@end

@implementation BSWeaselViewController

@synthesize captureManager;
@synthesize myImage;
@synthesize imageView;

unsigned char *bitmap1;
unsigned char *bitmap2;

NSTimer *uiTimer;
UIButton *captureButton;
UIProgressView *progressBar;
UISwitch *cheaterSwitch;
UILabel *label;

dispatch_queue_t backgroundQueue;

int imageCounter = 0;
int progress = 0;

const int GENERATIONS = 20000;
const int PIXELS_PER_GEN = 100;
const int DELTA_MAX = 150;

- (BOOL)shouldAutorotate
{
    return NO;
}

- (void)viewDidLoad {
    backgroundQueue = dispatch_queue_create("com.bs.weasel.queue", NULL);
    
    imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0,[UIScreen mainScreen].bounds.size.width,[UIScreen mainScreen].bounds.size.height)];
    
    //[imageView setFrame:CGRectMake(0, 0,[UIScreen mainScreen].bounds.size.width,[UIScreen mainScreen].bounds.size.height)];
    [[self view] addSubview:imageView];
           
	[self setCaptureManager:[[[CaptureSessionManager alloc] init] autorelease]];
	[[self captureManager] addVideoInputFrontCamera:NO];
    [[self captureManager] addStillImageOutput];
	[[self captureManager] addVideoPreviewLayer];
    
	CGRect layerRect = [[[self view] layer] bounds];
    [[[self captureManager] previewLayer] setBounds:layerRect];
    [[[self captureManager] previewLayer] setPosition:CGPointMake(CGRectGetMidX(layerRect),CGRectGetMidY(layerRect))];
	[[[self view] layer] addSublayer:[[self captureManager] previewLayer]];
    
    UIImage *icon = [UIImage imageNamed:@"lens-icon.png"];
    
    captureButton= [UIButton buttonWithType:UIButtonTypeRoundedRect];
    captureButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [captureButton setImage:icon forState:UIControlStateNormal];
    [captureButton setFrame:CGRectMake(0, 0, 140, 140)];
    [captureButton setCenter:CGPointMake(layerRect.size.width / 2, layerRect.size.height - 80)];
    [captureButton addTarget:self action:@selector(buttonPressed) forControlEvents:UIControlEventTouchUpInside];
    [[self view] addSubview:captureButton];
    
    label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 300, 50)];
    
    [label setCenter:CGPointMake(layerRect.size.width /2, 50)];
    [label setFont:[UIFont systemFontOfSize:16]];
    [label setBackgroundColor:[UIColor clearColor]];
    [label setTextAlignment:NSTextAlignmentCenter];
    [label setTextColor:[UIColor whiteColor]];
    [label setText:@"Capture Image 1"];
    [[self view] addSubview:label];
    
    progressBar = [UIProgressView alloc];
    [progressBar initWithFrame:CGRectMake(0, 0, 200, 50)];
    [progressBar setCenter:CGPointMake(layerRect.size.width / 2, layerRect.size.height - 100)];
    [progressBar setProgressViewStyle:UIProgressViewStyleDefault];
    [progressBar setTrackTintColor:[UIColor blackColor]];
    [progressBar setProgressTintColor:[UIColor lightGrayColor]];
    
    cheaterSwitch = [UISwitch alloc];
    [cheaterSwitch initWithFrame:CGRectMake(0, 0, 80, 40)];
    [cheaterSwitch setCenter:CGPointMake(layerRect.size.width / 2, layerRect.size.height - 50)];
    [cheaterSwitch setOnTintColor:[UIColor lightGrayColor]];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleImageCapture) name:kImageCapturedSuccessfully object:[self captureManager]];
    
	[[captureManager captureSession] startRunning];
}

- (void)buttonPressed {
    [[self captureManager] captureStillImage];
}

// Periodic image update (asynchronous from image mutation).
- (void)updateImage {
    @synchronized(self){
        int width = [[self captureManager] stillImage].size.width;
        int height = [[self captureManager] stillImage].size.height;
        
        UIImage *img = [ImageHelper convertBitmapRGBA8ToUIImage:bitmap2 withWidth:width withHeight:height];
        
        [self setMyImage:img];
        
        [imageView setImage:myImage];
        
        float prg = ((float)progress / (float)GENERATIONS);
        
        [progressBar setProgress:prg animated:YES];
        [progressBar setNeedsDisplay];
       
        [imageView setNeedsDisplay];
    }
}

// Handle the 2 image captures here.
- (void)handleImageCapture
{
    imageCounter++;
    
    if (imageCounter == 1)
    {
        [captureButton setTitle:@"Image 2" forState:UIControlStateNormal];
        
        bitmap1 = [ImageHelper convertUIImageToBitmapRGBA8:[[self captureManager] stillImage]];
        
        [label setText:@"Capture Image 2"];
    }
    else if (imageCounter == 2)
    {
        [captureButton removeFromSuperview];
        
        bitmap2 = [ImageHelper convertUIImageToBitmapRGBA8:[[self captureManager] stillImage]];
        
        int width = [[self captureManager] stillImage].size.width;
        int height = [[self captureManager] stillImage].size.height;
        
        // Dispatch the image process asynchronously using GCD.
        dispatch_async(backgroundQueue,^ {
            int error = INT32_MAX;
            
            int sz = sizeof(bgra) * width * height;
            unsigned char *newBitmap = malloc(sz);
            
            for (int i = 0; i < GENERATIONS; i++) {
                @autoreleasepool {                    
                    @synchronized(self){
                        memcpy(newBitmap, bitmap2, sz);
                        
                        newBitmap = [self doGeneration:newBitmap numPixels:sz];
                        
                        int newError = [FitnessCalculator CalculateFitness:bitmap1 compareTo:newBitmap withWidth:width withHeight:height];
                        
                        if (newError <= error)
                        {
                            memcpy(bitmap2, newBitmap, sz);
                            
                            error = newError;
                        }
                        
                        progress = i;
                    }
                }
            }
            
            free(newBitmap);
            
            // After our processing is done, stop updating the UI.
            [uiTimer invalidate];
            uiTimer = nil;
        });
        
        [[[self captureManager] previewLayer] removeFromSuperlayer];
        
        // Start the timer to periodically update the image displayed to the user.
        uiTimer = [NSTimer scheduledTimerWithTimeInterval:0.20 target:self selector:@selector(updateImage) userInfo:nil repeats:YES];
        
        [label setText:@"Mutating..."];
        [[self view] addSubview:cheaterSwitch];
        [[self view] addSubview:progressBar];
        
        UILabel *cheatLabel = [UILabel alloc];
        
        [cheatLabel initWithFrame:CGRectMake(0,0, 80, 30)];
        [cheatLabel setCenter:CGPointMake(cheaterSwitch.center.x, cheaterSwitch.center.y + 30)];
        [cheatLabel setFont:[UIFont systemFontOfSize:14]];
        [cheatLabel setBackgroundColor:[UIColor clearColor]];
        [cheatLabel setTextAlignment:NSTextAlignmentCenter];
        [cheatLabel setTextColor:[UIColor whiteColor]];
        [cheatLabel setText:@"Cheat"];
        [[self view] addSubview:cheatLabel];
    }
}

-(UIImage *)resizeImage:(UIImage *)image width:(CGFloat)resizedWidth height:(CGFloat)resizedHeight
{
    UIGraphicsBeginImageContext(CGSizeMake(resizedWidth ,resizedHeight));
    [image drawInRect:CGRectMake(0, 0, resizedWidth, resizedHeight)];
    UIImage *result = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return result;
}

- (unsigned char*)doGeneration:(unsigned char*)bmp
                    numPixels:(int)count
{
    for (int i = 0; i <  PIXELS_PER_GEN; i++) {
        int idx = arc4random_uniform(count);
                        
        idx = idx - (idx % 4);
        
        bgra *ref = (bgra *)(&bitmap1[idx]);
        bgra *n = (bgra *)(&bmp[idx]);
        
        if ([cheaterSwitch isOn])
        {
            n->b = ref->b;
            n->g = ref->g;
            n->r = ref->r;
        }
        else
        {
            int bdelta = (int)arc4random_uniform(DELTA_MAX * 2 + 1) - DELTA_MAX;
            int gdelta = (int)arc4random_uniform(DELTA_MAX * 2 + 1) - DELTA_MAX;
            int rdelta = (int)arc4random_uniform(DELTA_MAX * 2 + 1) - DELTA_MAX;
            
            n->b += bdelta;
            n->g += gdelta;
            n->r += rdelta;
        }
    }
    
    return bmp;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)dealloc {
    free(bitmap1);
    free(bitmap2);    
    
    [captureManager release], captureManager = nil;
    [window release], window = nil;
    [imageView release], imageView = nil;
    [myImage release], myImage = nil;
    dispatch_release(backgroundQueue);
    [super dealloc];
}

@end