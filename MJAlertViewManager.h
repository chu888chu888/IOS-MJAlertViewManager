//
//  MJAlertViewManager.h
//  Created by Joan Martin on 29/05/14.
//  Copyright (c) 2014 Mobile Jazz SL. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 * Alert views (UIView subclasses) may implement this protocol to customize its behaviour.
 **/
@protocol MJAlertView <NSObject>

/** *************************************** **
 * @name Configuring the animation
 ** *************************************** **/

@optional

/**
 * Returns the desired transform to be applied to the alert view when appearing.
 * @param animation The animation
 * @return The affine transform to be applied on the alert view
 * @discussion the transform will be applied before starting the animation and will animate to the identity.
 **/
- (CGAffineTransform)transformForAppearingAnimation;

/**
 * Returns the desired transform to be applied to the alert view when disappearing.
 * @param animation The animation
 * @return The affine transform to be applied on the alert view
 * @discussion The transform will be applied on the animation block.
 **/
- (CGAffineTransform)transformForDisappearingAnimation;

@end


/**
 * This class contains the logic for displaying & hidding alert views. 
 * Implements the singleton pattern, therefore your alert views will have to use the instance returned by `+defaultManager` to present and dismiss alert views.
 **/
@interface MJAlertViewManager : NSObject

/** *************************************** **
 * @name Getting the default manager
 ** *************************************** **/

/**
 * Returns the default instance.
 * @return The default alert view manager instance.
 **/
+ (MJAlertViewManager*)defaultManager;

/** *************************************** **
 * @name Configuring the background
 ** *************************************** **/

/**
 * Background color of the screen when prompting an alert view. Default value is black transparent 0.8.
 **/
@property (nonatomic, strong) UIColor *backroundColor;

/** *************************************** **
 * @name Configuring the animations
 ** *************************************** **/

/**
 * Appearing alert view animation. Default value is a scaling of 1.2.
 **/
@property (nonatomic, assign) CGAffineTransform appearingAnimationTransform;

/**
 * Dismiss alert view animation. Default value is a scaling of 0.8.
 **/
@property (nonatomic, assign) CGAffineTransform disappearingAnimationTransform;

/**
 * Duration of animations. Default value is 0.20.
 **/
@property (nonatomic, assign) NSTimeInterval animationDuration;

/** *************************************** **
 * @name Managing the alert view stack
 ** *************************************** **/

/**
 * Add a new alert view to the stack.
 * @param alertView The new alert view to be displayed.
 **/
- (void)addAlertView:(UIView*)alertView;

/**
 * Removes the top-most alert view from the stack.
 **/
- (void)popAlertView;

/** *************************************** **
 * @name Managing the alert view stack
 ** *************************************** **/

/**
 * The window that will be used to display alert views as subviews. If nil, the `keyWindow` of the UIApplication will be used instead. Default value is nil.
 **/
@property (nonatomic, strong) UIWindow *window;

@end
