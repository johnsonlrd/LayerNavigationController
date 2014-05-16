
#import "LayerNavigationController.h"
#import <QuartzCore/QuartzCore.h>

@interface LayerNavigationController ()
{
    CGPoint startTouch;
    
    UIImageView *lastScreenShotView;
    UIView *blackMask;
    
    UIImageView *tempView;
    
    UIPanGestureRecognizer* pan;
    BOOL _isFromBackButton;
}

@property (nonatomic,strong) UIView *backgroundView;
@property (nonatomic,strong) NSMutableArray *screenShotsList;

@end

@implementation LayerNavigationController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        _isFromBackButton = YES;
        self.screenShotsList = [[NSMutableArray alloc]initWithCapacity:2];
        self.canDragBack = YES;
    }
    return self;
}

-(id)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder]) {
        _isFromBackButton = YES;
        self.screenShotsList = [[NSMutableArray alloc]initWithCapacity:2];
        self.canDragBack = YES;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    // Do any additional setup after loading the view.
    
    // draw a shadow for navigation view to differ the layers obviously.
    // using this way to draw shadow will lead to the low performace
    // the best alternative way is making a shadow image.
    //
    self.view.layer.shadowColor = [[UIColor blackColor]CGColor];
    self.view.layer.shadowOffset = CGSizeMake(5, 5);
    self.view.layer.shadowRadius = 5;
    self.view.layer.shadowOpacity = 1;
    self.view.userInteractionEnabled = YES;
    
    UIImageView *shadowImageView = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"leftside_shadow_bg"]];
    shadowImageView.frame = CGRectMake(-10, 0, 10, self.view.frame.size.height);
    [self.view addSubview:shadowImageView];
    
    pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGestureRecognized:)];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    [self.screenShotsList addObject:[self capture]];
    [self addCurrentBackView];
    
    //设置view的frame的x点为320
    __block CGRect frame = self.view.frame;
    frame.origin.x = 320;
    self.view.frame = frame;
    
    [UIView animateWithDuration:kDefaultAnimationDuration animations:^{
        CGRect zeroFrame = frame;
        frame.origin.x = 0;
        self.view.frame = zeroFrame;
        
        [self moveViewWithX:0];
    }completion:^(BOOL finished) {
        [self.backgroundView removeFromSuperview];
        self.backgroundView = nil;
    }];
    
    if (self.viewControllers.count == 1) {
        [self.view addGestureRecognizer:pan];
    }
    [super pushViewController:viewController animated:NO];
}

- (UIViewController *)popViewControllerAnimated:(BOOL)animated
{
    if (_isFromBackButton) {
        __block UIImageView *currentView = [[UIImageView alloc] initWithFrame:self.view.frame];
        currentView.image = [self capture];
        [self.view addSubview:currentView];
        [self addCurrentBackView];
        
        __block CGRect frame = self.view.frame;
        frame.origin.x = 320;
        _backgroundView.transform = CGAffineTransformMakeScale(0.9,0.9);
        blackMask.alpha = 0.4;
        
        [UIView animateWithDuration:kDefaultAnimationDuration animations:^{
            self.view.frame = frame;
            [self moveViewWithX:320];
        } completion:^(BOOL finished) {
            
            CGRect frame = self.view.frame;
            frame.origin.x = 0;
            self.view.frame = frame;
            
            [self.backgroundView removeFromSuperview];
            self.backgroundView = nil;
            [currentView removeFromSuperview];
        }];
    }
    _isFromBackButton = YES;
    [self cleanLastData];
    return [super popViewControllerAnimated:NO];
}

- (NSArray *)popToRootViewControllerAnimated:(BOOL)animated
{
    [self.screenShotsList removeAllObjects];
    [self removePan];
    return [super popToRootViewControllerAnimated:YES];
}

-(void)cleanLastData
{
    [self.screenShotsList removeLastObject];
    if (self.viewControllers.count == 2) {
        [self removePan];
    }
}

-(void)addPan
{
    [self.view addGestureRecognizer:pan];
}

-(void)removePan
{
    for (UIGestureRecognizer* g in self.view.gestureRecognizers)
    {
        [self.view removeGestureRecognizer:g];
    }
}

#pragma mark - Utility Methods

/**
 *  get the current view screen shot
 *
 *  @return screenShots
 */
- (UIImage *)capture
{
    UIGraphicsBeginImageContextWithOptions(self.view.bounds.size, self.view.opaque, 0.0);
    [self.view.layer renderInContext:UIGraphicsGetCurrentContext()];
    
    UIImage * img = UIGraphicsGetImageFromCurrentImageContext();

    img = [UIImage imageWithData:UIImageJPEGRepresentation(img, 0.9)];
    
    UIGraphicsEndImageContext();
    
    return img;
}


//x -> 滑动的像素
- (void)moveViewWithX:(float)x
{
    x = x>320?320:x;
    x = x<0?0:x;
    
    CGRect frame = self.view.frame;
    frame.origin.x = x;
    self.view.frame = frame;
    
    float alpha = 0.4 - (x/800);
    //lastScreenShotView.center = CGPointMake(100 + x*60/320, lastScreenShotView.center.y);

    float transX = x / (320 * 9);
    transX += 0.9;
    transX = transX > 1?1:transX;
    
    _backgroundView.transform = CGAffineTransformMakeScale(transX,transX);
    
    blackMask.alpha = alpha;
}

/**
 * backgroundview上add屏幕截图
 */
- (void)addCurrentBackView
{
    CGRect frame = self.view.frame;
    self.backgroundView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, frame.size.width , frame.size.height)];
    [self.view.superview insertSubview:self.backgroundView belowSubview:self.view];
    //blackMask可以设定alpha,滑动时效果
    UIImage *lastScreenShot = [self.screenShotsList lastObject];
    lastScreenShotView = [[UIImageView alloc]initWithImage:lastScreenShot];
    lastScreenShotView.frame = self.view.bounds;
    lastScreenShotView.contentMode = UIViewContentModeScaleAspectFit;
    [self.backgroundView addSubview:lastScreenShotView];
}
- (void)panGestureRecognized:(UIPanGestureRecognizer *)recognizer
{
//    if (self.viewDeckController.visible) return;
    
    if (self.viewControllers.count <= 1 || !self.canDragBack) return;
    
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        
        _isMoving = NO;
        startTouch = [recognizer translationInView:self.view];
    }
    else if(recognizer.state == UIGestureRecognizerStateChanged)
    {
        
        CGPoint moveTouch = [recognizer translationInView:self.view];
        
        if (!_isMoving) {
            if(moveTouch.x - startTouch.x > 10)
            {
                _isMoving = YES;
                
                if (self.backgroundView == nil)
                {
                    CGRect frame = self.view.frame;
                    self.backgroundView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, frame.size.width , frame.size.height)];
                    
                    [self.view.superview insertSubview:self.backgroundView belowSubview:self.view];
                    //blackMask可以设定alpha,滑动时效果
                    blackMask = [[UIView alloc]initWithFrame:CGRectMake(0, 0, frame.size.width , frame.size.height)];
                    blackMask.backgroundColor = [UIColor blackColor];
                    [self.backgroundView addSubview:blackMask];
                }
                
                if (lastScreenShotView != nil)
                {
                    [lastScreenShotView removeFromSuperview];
                    lastScreenShotView = nil;
                }
                
                UIImage *lastScreenShot = [self.screenShotsList lastObject];
                lastScreenShotView = [[UIImageView alloc]initWithImage:lastScreenShot];
                lastScreenShotView.frame = self.view.bounds;
                lastScreenShotView.contentMode = UIViewContentModeScaleAspectFit;
                [self.backgroundView insertSubview:lastScreenShotView belowSubview:blackMask];
                
            }
        }
        
        if (_isMoving) {
            [self moveViewWithX:moveTouch.x - startTouch.x];
        }
    }
    else if(recognizer.state == UIGestureRecognizerStateEnded)
    {
        
        CGPoint endTouch = [recognizer translationInView:self.view];
        
        if (endTouch.x - startTouch.x > 100)
        {
            [UIView animateWithDuration:0.3 animations:^{
                [self moveViewWithX:320];
            } completion:^(BOOL finished) {
                _isFromBackButton = NO;
                [self popViewControllerAnimated:NO];
                CGRect frame = self.view.frame;
                frame.origin.x = 0;
                self.view.frame = frame;
                
                _isMoving = NO;
                [self.backgroundView removeFromSuperview];
                self.backgroundView = nil;
            }];
        }
        else
        {
            [UIView animateWithDuration:0.3 animations:^{
                [self moveViewWithX:0];
            } completion:^(BOOL finished) {
                _isMoving = NO;
                [self.backgroundView removeFromSuperview];
                self.backgroundView = nil;
                
            }];
            
        }
    }
    else if(recognizer.state == UIGestureRecognizerStateCancelled || recognizer.state == UIGestureRecognizerStateFailed)
    {
        [UIView animateWithDuration:0.3 animations:^{
            [self moveViewWithX:0];
        } completion:^(BOOL finished) {
            _isMoving = NO;
            [self.backgroundView removeFromSuperview];
            self.backgroundView = nil;
        }];
    }
}

@end