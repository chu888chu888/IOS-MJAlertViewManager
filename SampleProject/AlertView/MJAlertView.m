//
//  MJAlertView.m
//  Created by Joan Martin on 14/05/14.
//  Copyright (c) 2014 MobileJazz SL. All rights reserved.
//

#import "MJAlertView.h"

#import "MJAlertViewManager.h"

#define BLACK_COLOR [UIColor blackColor]
#define RED_COLOR [UIColor colorWithRed:228.0/255.0 green:48.0/255.0 blue:48.0/255.0 alpha:1.0]
#define GRAY_COLOR [UIColor colorWithRed:168.0/255.0 green:168.0/255.0 blue:168.0/255.0 alpha:1.0]

#define ALERT_WIDTH 300
#define TEXT_WIDTH 280

#define BUTTON_HEIGH 50
#define TOP_MARGIN 25
#define SUBTITLE_TOP_MARGIN 15
#define MESSAGE_TOP_MARGIN 5
#define BOTTOM_MARGIN 25

UIImage* resizableImageWithColor(UIColor *color)
{
    CGRect rect = CGRectMake(0.0f, 0.0f, 1.0f, 1.0f);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

@interface MJAlertView ()

@property (nonatomic, readonly) BOOL showAnimated;

@end

@implementation MJAlertView
{
    UILabel *_titleLabel;
    UILabel *_subtitleLabel;
    UILabel *_messageLabel;
    
    UIButton *_cancelButton;
    UIButton *_destructiveButton;
    
    NSArray *_buttons; // Array of button instances
    
    void(^_dismissBlock)(MJAlertView *alertView, NSInteger buttonIndex);
}

- (id)initWithFrame:(CGRect)frame
{
    return [self initWithTitle:nil subtitle:nil message:nil cancelButtonTitle:nil];
}

- (id)initWithTitle:(NSString *)title message:(NSString *)message cancelButtonTitle:(NSString *)cancelButtonTitle
{
    return [self initWithTitle:title subtitle:nil message:message cancelButtonTitle:cancelButtonTitle destructiveButtonTitle:nil];
}

- (id)initWithTitle:(NSString *)title subtitle:(NSString*)subtitle message:(NSString *)message cancelButtonTitle:(NSString *)cancelButtonTitle
{
    return [self initWithTitle:title subtitle:subtitle message:message cancelButtonTitle:cancelButtonTitle destructiveButtonTitle:nil];
}

- (id)initWithTitle:(NSString *)title subtitle:(NSString*)subtitle message:(NSString *)message cancelButtonTitle:(NSString *)cancelButtonTitle destructiveButtonTitle:(NSString*)destructiveButtonTitle
{
    CGRect defaultFrame = CGRectMake(0, 0, ALERT_WIDTH, 200);
    
    self = [super initWithFrame:defaultFrame];
    if (self)
    {
        _title = title;
        _subtitle = subtitle;
        _message = message;
        _cancelButtonTitle = cancelButtonTitle;
        _destructiveButtonTitle = destructiveButtonTitle;
        
        _cancelButtonIndex = NSNotFound;
        _destructiveButtonIndex = NSNotFound;
        
        [self mjz_initAlertView];
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
//    CGRect bounds = self.bounds;
    
    CGRect titleFrame = CGRectZero;
    CGRect subtitleFrame = CGRectZero;
    CGRect messageFrame = CGRectZero;
    
    // --- Setting ORIGIN.X & SIZE.WIDTH --- //
    
    CGFloat labelOriginX = floorf((ALERT_WIDTH - TEXT_WIDTH)/2.0f);
    titleFrame.origin.x = labelOriginX;
    subtitleFrame.origin.x = labelOriginX;
    messageFrame.origin.x = labelOriginX;
    
    titleFrame.size.width = TEXT_WIDTH;
    subtitleFrame.size.width = TEXT_WIDTH;
    messageFrame.size.width = TEXT_WIDTH;
    
    // --- Setting ORIGIN.Y & SIZE.HEIGHT --- //
    
    CGFloat titleHeight = [[_title uppercaseString] boundingRectWithSize:CGSizeMake(TEXT_WIDTH, FLT_MAX)
                                               options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading
                                            attributes:@{NSFontAttributeName: _titleLabel.font}
                                               context:nil].size.height;
    
    CGFloat subtitleHeight = [_subtitle boundingRectWithSize:CGSizeMake(TEXT_WIDTH, FLT_MAX)
                                                     options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading
                                                  attributes:@{NSFontAttributeName: _subtitleLabel.font}
                                                     context:nil].size.height;
    
    CGFloat messageHeight = [_message boundingRectWithSize:CGSizeMake(TEXT_WIDTH, FLT_MAX)
                                                   options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading
                                                attributes:@{NSFontAttributeName: _messageLabel.font}
                                                   context:nil].size.height;
    
    titleFrame.origin.y = TOP_MARGIN;
    titleFrame.size.height = titleHeight;
    
    subtitleFrame.origin.y = CGRectGetMaxY(titleFrame) + ((subtitleHeight>0 && titleHeight>0)?SUBTITLE_TOP_MARGIN:0);
    subtitleFrame.size.height = subtitleHeight;
    
    messageFrame.origin.y = CGRectGetMaxY(subtitleFrame) + ((messageHeight>0 && (subtitleHeight>0 || titleHeight>0))?MESSAGE_TOP_MARGIN:0);
    messageFrame.size.height = messageHeight;
    
    // --- Assign new frames --- //
    
    _titleLabel.frame = titleFrame;
    _subtitleLabel.frame = subtitleFrame;
    _messageLabel.frame = messageFrame;
    
    // --- Buttons --- //
    
    CGFloat buttonWidth = floorf(ALERT_WIDTH / _buttons.count);
    for (NSInteger i=0; i<_buttons.count; ++i)
    {
        UIButton *button = _buttons[i];
        CGRect buttonFrame = button.frame;
        
        buttonFrame.origin.y = CGRectGetMaxY(messageFrame) + BOTTOM_MARGIN;
        buttonFrame.origin.x = buttonWidth * i;
        buttonFrame.size.height = BUTTON_HEIGH;
        
        if (i == _buttons.count-1)
            buttonFrame.size.width = ALERT_WIDTH - buttonWidth*i;
        else
            buttonFrame.size.width = buttonWidth;
        
        button.frame = buttonFrame;
    }
}

- (CGSize)sizeThatFits:(CGSize)size
{
    CGFloat titleHeight = [[_title uppercaseString] boundingRectWithSize:CGSizeMake(TEXT_WIDTH, FLT_MAX)
                                               options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading
                                            attributes:@{NSFontAttributeName: _titleLabel.font}
                                               context:nil].size.height;
    
    CGFloat subtitleHeight = [_subtitle boundingRectWithSize:CGSizeMake(TEXT_WIDTH, FLT_MAX)
                                                     options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading
                                                  attributes:@{NSFontAttributeName: _subtitleLabel.font}
                                                     context:nil].size.height;
    
    CGFloat messageHeight = [_message boundingRectWithSize:CGSizeMake(TEXT_WIDTH, FLT_MAX)
                                                   options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading
                                                attributes:@{NSFontAttributeName: _messageLabel.font}
                                                   context:nil].size.height;
    
    CGFloat width = ALERT_WIDTH;
    
    CGFloat height = 0.0f;
    height += TOP_MARGIN;
    height += titleHeight;
    height += subtitleHeight + ((subtitleHeight>0 && titleHeight>0)?SUBTITLE_TOP_MARGIN:0);
    height += messageHeight + ((messageHeight>0 && (subtitleHeight>0 || titleHeight>0))?MESSAGE_TOP_MARGIN:0);
    height += BOTTOM_MARGIN + BUTTON_HEIGH;
    
    return CGSizeMake(width, height);
}

#pragma mark Public Methods

- (void)show
{
    [self showWithDismissBlock:nil];
}

- (void)showWithDismissBlock:(void(^)(MJAlertView *alertView, NSInteger buttonIndex))dismissBlock
{
    _dismissBlock = dismissBlock;
    [[MJAlertViewManager defaultManager] addAlertView:self];
}

#pragma mark Private Methods

- (void)mjz_initAlertView
{
    self.backgroundColor = [UIColor whiteColor];
    
    _titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    _titleLabel.textColor = RED_COLOR;
    _titleLabel.font = [UIFont boldSystemFontOfSize:20.0];
    _titleLabel.numberOfLines = 0;
    _titleLabel.textAlignment = NSTextAlignmentCenter;
    [self addSubview:_titleLabel];
    
    _subtitleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    _subtitleLabel.textColor = BLACK_COLOR;
    _subtitleLabel.font = [UIFont boldSystemFontOfSize:16.0];
    _subtitleLabel.numberOfLines = 0;
    _subtitleLabel.textAlignment = NSTextAlignmentCenter;
    [self addSubview:_subtitleLabel];
    
    _messageLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    _messageLabel.textColor = BLACK_COLOR;
    _messageLabel.font = [UIFont systemFontOfSize:14.0];
    _messageLabel.numberOfLines = 0;
    _messageLabel.textAlignment = NSTextAlignmentCenter;
    [self addSubview:_messageLabel];
    
    _cancelButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _cancelButton.titleLabel.font = [UIFont boldSystemFontOfSize:20.0];
    [_cancelButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [_cancelButton setBackgroundImage:resizableImageWithColor(GRAY_COLOR) forState:UIControlStateNormal];
    [_cancelButton addTarget:self action:@selector(mjz_buttonAction:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:_cancelButton];
    _cancelButtonIndex = 0;
    _cancelButton.tag = _cancelButtonIndex;
    
    if (_destructiveButtonTitle)
    {
        _destructiveButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _destructiveButton.titleLabel.font = [UIFont boldSystemFontOfSize:20.0];
        [_destructiveButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_destructiveButton setBackgroundImage:resizableImageWithColor(RED_COLOR) forState:UIControlStateNormal];
        [_destructiveButton addTarget:self action:@selector(mjz_buttonAction:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_destructiveButton];
        _destructiveButtonIndex = 1;
        _destructiveButton.tag = _destructiveButtonIndex;
    }

    _titleLabel.text = [_title uppercaseString];
    _subtitleLabel.text = _subtitle;
    _messageLabel.text = _message;
    if (_cancelButtonTitle)
        [_cancelButton setTitle:[_cancelButtonTitle uppercaseString] forState:UIControlStateNormal];
    else
        [_cancelButton setTitle:[@"Dismiss" uppercaseString] forState:UIControlStateNormal];
    
    [_destructiveButton setTitle:[_destructiveButtonTitle uppercaseString] forState:UIControlStateNormal];
    
    if (_destructiveButton)
        _buttons = @[_cancelButton, _destructiveButton];
    else
        _buttons = @[_cancelButton];
}

- (void)mjz_buttonAction:(UIButton*)button
{
    [[MJAlertViewManager defaultManager] popAlertView];
    
    if (_dismissBlock)
        _dismissBlock(self, button.tag);
}

#pragma mark - Protocols

@end

// ####################################################################################################################### //
// ####################################################################################################################### //
// ####################################################################################################################### //
