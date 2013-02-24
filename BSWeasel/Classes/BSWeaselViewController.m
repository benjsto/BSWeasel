#import "BSWeaselViewController.h"
#import "ImageHelper.h"

@interface BSWeaselViewController ()

@property (atomic, retain) UIImage* myImage;
@property (atomic, retain) UIImageView *imageView;

@end

@implementation BSWeaselViewController

@synthesize captureManager;
@synthesize myImage;
@synthesize imageView;

//UIImage *referenceImage;
UIImage *image1;
UIImage *image2;
unsigned char *bitmap1;
unsigned char *bitmap2;
//unsigned char *referenceBitmap;

UILabel *label;

dispatch_queue_t backgroundQueue;

UIButton *captureButton;

NSTimer *uiTimer;

int imageCounter = 0;

- (void)viewDidLoad {
    
    backgroundQueue = dispatch_queue_create("com.bs.weasel.queue", NULL);
    
    imageView = [[UIImageView alloc] initWithImage:image1];
    
    [imageView setFrame:CGRectMake(0, 0,[UIScreen mainScreen].bounds.size.width,[UIScreen mainScreen].bounds.size.height)];
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
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(displayImage) name:kImageCapturedSuccessfully object:[self captureManager]];
    
	[[captureManager captureSession] startRunning];
}

- (void)buttonPressed {
    [[self captureManager] captureStillImage];
}

- (void)updateImage {
    @synchronized(self){
        int width = [[self captureManager] stillImage].size.width;
        int height = [[self captureManager] stillImage].size.height;
        
        UIImage *img = [ImageHelper convertBitmapRGBA8ToUIImage:bitmap2 withWidth:width withHeight:height];
        
        [self setMyImage:img];
        
        [imageView setImage:myImage];
        [[self view] bringSubviewToFront:imageView];        
        [imageView setNeedsDisplay];
    }
}

- (void)displayImage
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
        
        dispatch_async(backgroundQueue,^ {
            for (int i = 0; i < 50000; i++) {
                @autoreleasepool {
                    @synchronized(self){
                        bitmap2 = [self doGeneration:bitmap2];
                    }
                    
                    [NSThread sleepForTimeInterval:0.001];
                }
            }
            
            [uiTimer invalidate];
            uiTimer = nil;
        });
        
        uiTimer = [NSTimer scheduledTimerWithTimeInterval:0.05 target:self selector:@selector(updateImage) userInfo:nil repeats:YES];
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

typedef struct
{
    unsigned char b;
    unsigned char g;
    unsigned char r;
    unsigned char a;
} bgra;

- (unsigned char*)doGeneration :(unsigned char*)bmp {
    
    for (int i = 0; i < 50; i++) {
        int idx = arc4random_uniform(691200);
                        
        idx = idx - (idx % 4);
        
        bgra *ref = (bgra *)(&bitmap1[idx]);
        bgra *n = (bgra *)(&bmp[idx]);        
        
        n->b = ref->b;
        n->g = ref->g;
        n->r = ref->r;
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