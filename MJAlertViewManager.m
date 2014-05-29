//
//  MJAlertViewManager.h
//  Created by Joan Martin on 29/05/14.
//  Copyright (c) 2014 Mobile Jazz SL. All rights reserved.
//

#import "MJAlertViewManager.h"

@implementation MJAlertViewManager
{
    NSMutableArray *_queuedAlertViews;
    UIView *_currentAlertView;
    UIView *_backgroundView;
    
    CGRect _keyboardRect;
    BOOL _hasKeyboard;
    
    BOOL _isRotating;
    BOOL _isAppearing;
    
    UIWindow *_window;
}

+ (MJAlertViewManager*)defaultManager
{
    static MJAlertViewManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[MJAlertViewManager alloc] init];
    });
    
    return instance;
}

- (id)init
{
    self = [super init];
    if (self)
    {
        _queuedAlertViews = [NSMutableArray array];
        
        _backroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.8f];
        _appearingAnimationTransform = CGAffineTransformMakeScale(1.2f, 1.2f);
        _disappearingAnimationTransform = CGAffineTransformMakeScale(0.8f, 0.8f);
        _animationDuration = 0.20;
        
        _window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
        _window.windowLevel = UIWindowLevelAlert;
        
        _isRotating = NO;
        _isAppearing = NO;
        _hasKeyboard = NO;
        _keyboardRect = CGRectZero;
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mjz_willChangeOrientation:) name:UIApplicationWillChangeStatusBarOrientationNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mjz_didChangeOrientation:) name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mjz_keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mjz_keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    }
    return self;
}

- (void)dealloc
{
    // Removing observer from everywhere!
    [[NSNotificationCenter defaultCenter] removeObserver:self name:nil object:nil];
}

#pragma mark Properties

- (void)setBackroundColor:(UIColor *)backroundColor
{
    _backroundColor = backroundColor;
    
    if (_backgroundView)
        _backgroundView.backgroundColor = backroundColor;
}

//- (void)setWindow:(UIWindow *)window
//{
//    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:_window];
//    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:_window];
//    
//    _window = window;
//    
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mjz_keyboardWillShow:) name:UIKeyboardWillShowNotification object:_window];
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mjz_keyboardWillHide:) name:UIKeyboardWillHideNotification object:_window];
//}

#pragma mark Public Methods

- (void)addAlertView:(UIView*)alertView
{
    if ([_queuedAlertViews containsObject:alertView])
    {
        NSException *exception = [NSException exceptionWithName:NSInternalInconsistencyException reason:@"You are trying to display twice the alertView. An alertView can only be displayed once." userInfo:nil];
        [exception raise];
    }
    
    [_queuedAlertViews addObject:alertView];
    [self mjz_setNeedsDisplayAlertView];
}

- (void)popAlertView
{
    [self mjz_dismissAlertView];
}

#pragma mark Private Methods

- (void)mjz_setNeedsDisplayAlertView
{
    UIView *nextAlertView = [_queuedAlertViews lastObject];
    
    if (nextAlertView)
    {
        if (_currentAlertView == nil)
        {
            _isAppearing = YES;
            [self mjz_displayBackgroundViewAnimated:YES completionBlock:nil];
        }
        else
        {
            // If an existing alert view is displayed, remove it without animation
            [_currentAlertView removeFromSuperview];
            _currentAlertView = nil;
        }
        
        // Display the new alert view
        [self mjz_displayNextAlertView];
    }
    else
    {
        // Nothing to display
        _currentAlertView = nil;
    }
}

- (void)mjz_displayNextAlertView
{
    // Getting the next alert view to display
    UIView *nextAlertView = [_queuedAlertViews lastObject];
    
    // If there is an alert view to display, then show it.
    _currentAlertView = nextAlertView;
    [self mjz_showAlertView:_currentAlertView completionBlock:^{
        _isAppearing = NO;
    }];
}

- (void)mjz_dismissAlertView
{
    // If no alert view to hide, return
    if (_currentAlertView == nil)
        return;
    
    // Check that the current displayed alert view is the last queued alert view on the list, otherwise assert.
    NSAssert(_currentAlertView == [_queuedAlertViews lastObject], @"Inconsistency in alert view stack. Last alert view in stack doesn't correspond to current displayed alert view.");
    
    BOOL dismissAnimated = YES;
    
    // Pop the alert view from the pile
    [_queuedAlertViews removeLastObject];
    
    // Hide the alert view
    [self mjz_hideAlertView:_currentAlertView completionBlock:nil];
    
    if (_queuedAlertViews.count == 0)
    {
        // If no more alert views to display, hide the background
        [self mjz_hideBackgroundViewAnimated:dismissAnimated completionBlock:^{
            if (!_currentAlertView)
                _window.hidden = YES;
        }];
        
        // Nothing more to display
        _currentAlertView = nil;
    }
    else
    {
        // Otherwise, display the next alert view
        [self mjz_setNeedsDisplayAlertView];
    }
}

- (void)mjz_showAlertView:(UIView *)alertView completionBlock:(void (^)())completionBlock
{
    UIWindow *window = _window;
    
    [window makeKeyAndVisible];
    
    CGAffineTransform transform = [self mjz_transformForCurrentOrientation:UIInterfaceOrientationPortrait newOrientation:[UIApplication sharedApplication].statusBarOrientation];
    transform = [self mjz_transformByCorrectingKeyboardOffsetToTransform:transform];
    
    [alertView sizeToFit];
    alertView.center = CGPointMake(floorf(window.bounds.size.width/2.0f), floorf(window.bounds.size.height/2.0f));
    alertView.transform = transform;
    
    CGFloat alpha = 0.0f;
    CGAffineTransform appearingTransform = _appearingAnimationTransform;
    
    if ([alertView conformsToProtocol:@protocol(MJAlertView)] && [alertView respondsToSelector:@selector(transformForAppearingAnimation)])
        appearingTransform = [(id<MJAlertView>)alertView transformForAppearingAnimation];
    
    alertView.alpha = alpha;
    alertView.transform = CGAffineTransformConcat(alertView.transform, appearingTransform);
    
    [window addSubview:alertView];
    
    [UIView animateWithDuration:_animationDuration
                     animations:^{
                         alertView.alpha = 1.0f;
                         alertView.transform = [self mjz_transformByCorrectingKeyboardOffsetToTransform:transform];
                     } completion:^(BOOL finished) {
                         if (completionBlock)
                             completionBlock();
                     }];
}

- (void)mjz_hideAlertView:(UIView *)alertView completionBlock:(void(^)())completionBlock
{
    CGFloat alpha = 0.0f;
    
    CGAffineTransform disappearingTransform = _disappearingAnimationTransform;
    if ([alertView conformsToProtocol:@protocol(MJAlertView)] && [alertView respondsToSelector:@selector(transformForDisappearingAnimation)])
        disappearingTransform = [(id<MJAlertView>)alertView transformForDisappearingAnimation];
    
    CGAffineTransform transform = [self mjz_transformForCurrentOrientation:UIInterfaceOrientationPortrait newOrientation:[UIApplication sharedApplication].statusBarOrientation];
    transform = CGAffineTransformConcat(alertView.transform, disappearingTransform);
    
    [UIView animateWithDuration:_animationDuration
                     animations:^{
                         alertView.alpha = alpha;
                         alertView.transform = transform;
                     } completion:^(BOOL finished) {
                         [alertView removeFromSuperview];
                         if (completionBlock)
                             completionBlock();
                     }];
}

- (void)mjz_displayBackgroundViewAnimated:(BOOL)animated completionBlock:(void(^)())completionBlock
{
    if (_backgroundView != nil)
        return;
    
    UIWindow *window = _window;
    
    _backgroundView = [[UIView alloc] initWithFrame:window.bounds];
    _backgroundView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    
    _backgroundView.backgroundColor = _backroundColor;
    
    _backgroundView.alpha = 0.0f;
    [window addSubview:_backgroundView];
    
    [UIView animateWithDuration:_animationDuration
                     animations:^{
                         _backgroundView.alpha = 1.0f;
                     } completion:^(BOOL finished) {
                         if (completionBlock)
                             completionBlock();
                     }];
}

- (void)mjz_hideBackgroundViewAnimated:(BOOL)animated completionBlock:(void(^)())completionBlock
{
    if (_backgroundView == nil)
        return;
    
    UIView *backgroundView = _backgroundView;
    _backgroundView = nil;
    
    [UIView animateWithDuration:_animationDuration
                     animations:^{
                         backgroundView.alpha = 0.0f;
                     } completion:^(BOOL finished) {
                         [backgroundView removeFromSuperview];
                         if (completionBlock)
                             completionBlock();
                     }];
}

- (CGAffineTransform)mjz_transformForCurrentOrientation:(UIInterfaceOrientation)current newOrientation:(UIInterfaceOrientation)orientation
{
    if (current == orientation)
        return CGAffineTransformIdentity;
    
    CGFloat angle = 0.0f;
    
    switch (current)
    {
        case UIInterfaceOrientationPortrait:
        {
            switch (orientation)
            {
                case UIInterfaceOrientationPortraitUpsideDown:
                    angle = (CGFloat)M_PI;  // 180.0*M_PI/180.0 == M_PI
                    break;
                case UIInterfaceOrientationLandscapeLeft:
                    angle = (CGFloat)(M_PI*-90.0)/180.0;
                    break;
                case UIInterfaceOrientationLandscapeRight:
                    angle = (CGFloat)(M_PI*90.0)/180.0;
                    break;
                default:
                    return CGAffineTransformIdentity;
            }
            break;
        }
        case UIInterfaceOrientationPortraitUpsideDown:
        {
            switch (orientation)
            {
                case UIInterfaceOrientationPortrait:
                    angle = (CGFloat)M_PI;  // 180.0*M_PI/180.0 == M_PI
                    break;
                case UIInterfaceOrientationLandscapeLeft:
                    angle = (CGFloat)(M_PI*90.0)/180.0;
                    break;
                case UIInterfaceOrientationLandscapeRight:
                    angle = (CGFloat)(M_PI*-90.0)/180.0;
                    break;
                default:
                    return CGAffineTransformIdentity;
            }
            break;
        }
        case UIInterfaceOrientationLandscapeLeft:
        {
            switch (orientation)
            {
                case UIInterfaceOrientationLandscapeRight:
                    angle = (CGFloat)M_PI;  // 180.0*M_PI/180.0 == M_PI
                    break;
                case UIInterfaceOrientationPortraitUpsideDown:
                    angle = (CGFloat)(M_PI*-90.0)/180.0;
                    break;
                case UIInterfaceOrientationPortrait:
                    angle = (CGFloat)(M_PI*90.0)/180.0;
                    break;
                default:
                    return CGAffineTransformIdentity;
            }
            break;
        }
        case UIInterfaceOrientationLandscapeRight:
        {
            switch (orientation)
            {
                case UIInterfaceOrientationLandscapeLeft:
                    angle = (CGFloat)M_PI;  // 180.0*M_PI/180.0 == M_PI
                    break;
                case UIInterfaceOrientationPortrait:
                    angle = (CGFloat)(M_PI*-90.0)/180.0;
                    break;
                case UIInterfaceOrientationPortraitUpsideDown:
                    angle = (CGFloat)(M_PI*90.0)/180.0;
                    break;
                default:
                    return CGAffineTransformIdentity;
            }
            break;
        }
    }
    
    CGAffineTransform rotation = CGAffineTransformMakeRotation( angle );
    return rotation;
}

- (CGAffineTransform)mjz_transformByCorrectingKeyboardOffsetToTransform:(CGAffineTransform)transform
{
    if (!_hasKeyboard)
        return transform;
    
    CGAffineTransform keyboardTransform = CGAffineTransformIdentity;
    
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    
    switch (orientation)
    {
        case UIInterfaceOrientationPortrait:
            keyboardTransform = CGAffineTransformMakeTranslation(0, -_keyboardRect.size.height/2.0f);
            break;
        case UIInterfaceOrientationPortraitUpsideDown:
            keyboardTransform = CGAffineTransformMakeTranslation(0, _keyboardRect.size.height/2.0f);
            break;
        case UIInterfaceOrientationLandscapeLeft:
            keyboardTransform = CGAffineTransformMakeTranslation(-_keyboardRect.size.width/2.0f, 0);
            break;
        case UIInterfaceOrientationLandscapeRight:
            keyboardTransform = CGAffineTransformMakeTranslation(_keyboardRect.size.width/2.0f, 0);
            break;
        default:
            return CGAffineTransformIdentity;
    }
    
    return CGAffineTransformConcat(transform, keyboardTransform);
}

#pragma mark Notifications

- (void)mjz_willChangeOrientation:(NSNotification*)notification
{
    _isRotating = YES;
    
    // if no current alert view, just abort.
    if (!_currentAlertView)
        return;
    
    if (!_hasKeyboard)
    {
        UIInterfaceOrientation current = [[UIApplication sharedApplication] statusBarOrientation];
        UIInterfaceOrientation orientation = [notification.userInfo[UIApplicationStatusBarOrientationUserInfoKey] integerValue];
        
        CGAffineTransform transform = [self mjz_transformForCurrentOrientation:UIInterfaceOrientationPortrait newOrientation:current];
        
        CGAffineTransform rotation = [self mjz_transformForCurrentOrientation:current newOrientation:orientation];
        transform = CGAffineTransformConcat(transform, rotation);
        
        // Because this method is called in an animation block, the transform will be animated.
        _currentAlertView.transform = transform;
    }
}

- (void)mjz_didChangeOrientation:(NSNotification*)notification
{
    // Set the rotating flag on next loop, so other methods that will be called on this loop will get the rotating value flag.
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.01 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        _isRotating = NO;
    });
}

- (void)mjz_keyboardWillShow:(NSNotification*)notification
{
    _hasKeyboard = YES;
    _keyboardRect = [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    
    // if the view is appearing, lets do the appearing animation in the appearing method.
    if (_isAppearing)
        return;
    
    // if there is no current alert view, just abort.
    if (!_currentAlertView)
        return;
    
    CGAffineTransform transform = [self mjz_transformForCurrentOrientation:UIInterfaceOrientationPortrait newOrientation:[[UIApplication sharedApplication] statusBarOrientation]];
    transform = [self mjz_transformByCorrectingKeyboardOffsetToTransform:transform];

    if (_isRotating)
    {
        // if rotating, there is already an animation block. Just set the new transform value.
        _currentAlertView.transform = transform;
    }
    else
    {
        // if no rotating, lets create an animation block.
        
        UIViewAnimationCurve curve = [notification.userInfo[UIKeyboardAnimationCurveUserInfoKey] integerValue];
        NSTimeInterval duration = [notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
        
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationCurve:curve];
        [UIView setAnimationDuration:duration];
        
        _currentAlertView.transform = transform;
        
        [UIView commitAnimations];
    }
}

- (void)mjz_keyboardWillHide:(NSNotification*)notification
{
    if (!_hasKeyboard)
        return;
    
    _hasKeyboard = NO;
    _keyboardRect = [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    
    CGAffineTransform transform = [self mjz_transformForCurrentOrientation:UIInterfaceOrientationPortrait newOrientation:[[UIApplication sharedApplication] statusBarOrientation]];
    transform = [self mjz_transformByCorrectingKeyboardOffsetToTransform:transform];
    
    if (_isRotating)
    {
        // if rotating, there is already an animation block. Just set the new transform value.
        _currentAlertView.transform = transform;
    }
    else
    {
        // if no rotating, lets create an animation block.
        
        UIViewAnimationCurve curve = [notification.userInfo[UIKeyboardAnimationCurveUserInfoKey] integerValue];
        NSTimeInterval duration = [notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
        
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationCurve:curve];
        [UIView setAnimationDuration:duration];
        
        _currentAlertView.transform = transform;
        
        [UIView commitAnimations];
    }
}

@end
