//
//  MJAlertView.h
//  Created by Joan Martin on 14/05/14.
//  Copyright (c) 2014 MobileJazz SL. All rights reserved.
//

#import <UIKit/UIKit.h>

/**
 * Customized alert views.
 **/
@interface MJAlertView : UIView

/**
 * Default initializer.
 * @param title The title of the alert. Can be nil.
 * @param message The message of the alert. Can be nil.
 * @param cancelButtonTitle The cancel button title. If nil, a default cancel button title will be set.
 * @discussion Title, subtitle and message will be layouted automatically in multiple lines if needed. However, the cancel button title is rendered only in one line.
 **/
- (id)initWithTitle:(NSString *)title message:(NSString *)message cancelButtonTitle:(NSString *)cancelButtonTitle;

/**
 * Default initializer.
 * @param title The title of the alert. Can be nil.
 * @param subtitle The subtitle of the alert. Can be nil.
 * @param message The message of the alert. Can be nil.
 * @param cancelButtonTitle The cancel button title. If nil, a default cancel button title will be set.
 * @discussion Title, subtitle and message will be layouted automatically in multiple lines if needed. However, the cancel button title is rendered only in one line.
 **/
- (id)initWithTitle:(NSString *)title subtitle:(NSString*)subtitle message:(NSString *)message cancelButtonTitle:(NSString *)cancelButtonTitle;

/**
 * Default initializer.
 * @param title The title of the alert. Can be nil.
 * @param subtitle The subtitle of the alert. Can be nil.
 * @param message The message of the alert. Can be nil.
 * @param cancelButtonTitle The cancel button title. If nil, a default cancel button title will be set.
 * @param destructiveButtonTitle The destructive button title. Can be nil.
 * @discussion Title, subtitle and message will be layouted automatically in multiple lines if needed. However, the cancel and destructive button title are rendered only in one line.
 **/
- (id)initWithTitle:(NSString *)title subtitle:(NSString*)subtitle message:(NSString *)message cancelButtonTitle:(NSString *)cancelButtonTitle destructiveButtonTitle:(NSString*)destructiveButtonTitle;

/**
 * The title.
 **/
@property (nonatomic, strong, readonly) NSString *title;

/**
 * The subtitle.
 **/
@property (nonatomic, strong, readonly) NSString *subtitle;

/**
 * The message.
 **/
@property (nonatomic, strong, readonly) NSString *message;

/**
 * The cancel button title.
 **/
@property (nonatomic, strong, readonly) NSString *cancelButtonTitle;

/**
 * The destructive button title
 **/
@property (nonatomic, strong, readonly) NSString *destructiveButtonTitle;

/**
 * Index of cancel button
 **/
@property (nonatomic, assign, readonly) NSInteger cancelButtonIndex;

/**
 * Index of destructive button
 **/
@property (nonatomic, assign, readonly) NSInteger destructiveButtonIndex;

/**
 * To display the alert view call this method.
 **/
- (void)show;

/**
 * Call this method to display the alert view.
 * @param completionBlock This block is called when the user taps on the alert view buttons.
 * @discussion The block is called just after starting the dismiss alert view animation.
 **/
- (void)showWithDismissBlock:(void(^)(MJAlertView *alertView, NSInteger buttonIndex))dismissBlock;

@end
