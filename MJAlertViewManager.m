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
    }
    return self;
}

#pragma mark Properties

- (void)setBackroundColor:(UIColor *)backroundColor
{
    _backroundColor = backroundColor;
    
    if (_backgroundView)
        _backgroundView.backgroundColor = backroundColor;
}

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
            // If no alert view is currenlty displayed, show the background view
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
    [self mjz_showAlertView:_currentAlertView completionBlock:nil];
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
        [self mjz_hideBackgroundViewAnimated:dismissAnimated completionBlock:nil];
        
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
    UIView *superview = [self mjz_window];
    
    [alertView sizeToFit];
    alertView.center = CGPointMake(floorf(superview.bounds.size.width/2.0f), floorf(superview.bounds.size.height/2.0f));
    
    CGFloat alpha = 0.0f;
    CGAffineTransform transform = _appearingAnimationTransform;
    
    if ([alertView conformsToProtocol:@protocol(MJAlertView)] && [alertView respondsToSelector:@selector(transformForAppearingAnimation)])
        transform = [(id<MJAlertView>)alertView transformForAppearingAnimation];
    
    alertView.alpha = alpha;
    alertView.transform = transform;
    
    [superview addSubview:alertView];
    
    [UIView animateWithDuration:_animationDuration
                     animations:^{
                         alertView.alpha = 1.0f;
                         alertView.transform = CGAffineTransformIdentity;
                     } completion:^(BOOL finished) {
                         if (completionBlock)
                             completionBlock();
                     }];
}

- (void)mjz_hideAlertView:(UIView *)alertView completionBlock:(void(^)())completionBlock
{
    CGFloat alpha = 0.0f;
    CGAffineTransform transform = _disappearingAnimationTransform;

    if ([alertView conformsToProtocol:@protocol(MJAlertView)] && [alertView respondsToSelector:@selector(transformForDisappearingAnimation)])
        transform = [(id<MJAlertView>)alertView transformForDisappearingAnimation];
    
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
    
    UIView *superview = [self mjz_window];
    
    _backgroundView = [[UIView alloc] initWithFrame:superview.bounds];
    _backgroundView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    
    _backgroundView.backgroundColor = _backroundColor;
    
    _backgroundView.alpha = 0.0f;
    [superview addSubview:_backgroundView];
    
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

- (UIWindow*)mjz_window
{
    if (_window)
        return _window;
    
    return [[UIApplication sharedApplication] keyWindow];
}

@end
