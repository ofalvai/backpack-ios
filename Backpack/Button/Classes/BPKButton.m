/*
 * Backpack - Skyscanner's Design System
 *
 * Copyright 2018-2019 Skyscanner Ltd
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import "BPKButton.h"

#import <Backpack/Color.h>
#import <Backpack/Common.h>
#import <Backpack/Font.h>
#import <Backpack/Gradient.h>
#import <Backpack/Radii.h>
#import <Backpack/Spacing.h>
#import <Backpack/DarkMode.h>
#import <Backpack/UIView+BPKRTL.h>

NS_ASSUME_NONNULL_BEGIN
@interface BPKButton ()
@property(nonatomic, getter=isInitializing) BOOL initializing;

@property(nonatomic) BPKGradientLayer *gradientLayer;

@property(nonatomic, readonly, getter=isIconOnly) BOOL iconOnly;
@property(nonatomic, readonly, getter=isTextOnly) BOOL textOnly;
@property(nonatomic, readonly, getter=isTextAndIcon) BOOL textAndIcon;

@property(nonatomic, readonly) UIColor *currentContentColor;
@property(nonatomic, readonly) BPKFontStyle currentFontStyle;
@property(nonatomic, class, readonly) UIColor *disabledBackgroundColor;
@property(nonatomic, class, readonly) UIColor *disabledContentColor;
@property(nonatomic, class, readonly) UIColor *disabledBorderColor;
@property(nonatomic, class, readonly) UIColor *boxyBackgroundColor;
@property(nonatomic, class, readonly) UIColor *boxyBorderColor;
@property(nonatomic, class, readonly) CGFloat buttonTitleIconSpacing;
@property (nonatomic, strong) UIActivityIndicatorView *spinner;
@end

@implementation BPKButton

- (instancetype)initWithSize:(BPKButtonSize)size style:(BPKButtonStyle)style {
    BPKAssertMainThread();
    self = [super initWithFrame:CGRectZero];

    if (self) {
        [self setupWithSize:size style:style];
    }

    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    BPKAssertMainThread();
    self = [super initWithFrame:frame];

    if (self) {
        [self setupWithSize:BPKButtonSizeDefault style:BPKButtonStylePrimary];
    }

    return self;
}

- (nullable instancetype)initWithCoder:(NSCoder *)aDecoder {
    BPKAssertMainThread();
    self = [super initWithCoder:aDecoder];

    if (self) {
        [self setupWithSize:BPKButtonSizeDefault style:BPKButtonStylePrimary];
    }

    return self;
}

- (void)setupWithSize:(BPKButtonSize)size style:(BPKButtonStyle)style {
    self.initializing = YES;

    _cornerRadius = @(BPKBorderRadiusSm);

    self.layer.masksToBounds = YES;
    self.adjustsImageWhenHighlighted = NO;
    self.adjustsImageWhenDisabled = NO;
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    self.titleLabel.tintAdjustmentMode = UIViewTintAdjustmentModeNormal;

    // Use this to get the title value if one has been set in storyboard.
    if (self.titleLabel != nil && self.titleLabel.text != nil) {
        _title = self.titleLabel.text;
    }

    self.size = size;
    self.style = style;
    self.imagePosition = BPKButtonImagePositionTrailing;

    self.gradientLayer = [[BPKGradientLayer alloc] init];
    [self.layer insertSublayer:self.gradientLayer atIndex:0];

    [self updateEdgeInsets];
    [self updateFont];
    [self updateBackgroundAndStyle];
    self.initializing = NO;
}

- (BOOL)isIconOnly {
    return self.currentImage && self.titleLabel.text.length == 0;
}

- (BOOL)isTextOnly {
    return (self.currentImage == nil) && self.titleLabel.text.length > 0;
}

- (BOOL)isTextAndIcon {
    return self.currentImage && self.titleLabel.text.length > 0;
}

#pragma mark - Style setters

- (void)setSize:(BPKButtonSize)size {
    BPKAssertMainThread();
    if (_size != size || self.isInitializing) {
        _size = size;

        [self updateFont];
        [self updateEdgeInsets];
    }
}

- (void)setStyle:(BPKButtonStyle)style {
    BPKAssertMainThread();
    if (_style != style || self.isInitializing) {
        _style = style;

        [self updateBackgroundAndStyle];
        [self updateEdgeInsets];
    }
}

- (void)setImagePosition:(BPKButtonImagePosition)imagePosition {
    if (_imagePosition != imagePosition || self.isInitializing) {
        _imagePosition = imagePosition;

        [self setNeedsLayout];
    }
}

- (void)setTitle:(NSString *_Nullable)title {
    BPKAssertMainThread();
    _title = [title copy];
    [self updateTitle];
}

- (void)updateTitle {
    if (self.title) {
        NSAttributedString *attributedTitle = [BPKFont attributedStringWithFontStyle:self.currentFontStyle
                                                                             content:self.title
                                                                           textColor:self.currentContentColor
                                                                         fontMapping:_fontMapping];
        [self setAttributedTitle:attributedTitle forState:UIControlStateNormal];
    } else {
        [self setAttributedTitle:nil forState:UIControlStateNormal];
    }

    [self updateFont];
    [self updateEdgeInsets];
}

- (void)setImage:(UIImage *_Nullable)image {
    BPKAssertMainThread();
    [super setImage:image forState:UIControlStateNormal];

    [self updateBackgroundAndStyle];
    [self updateFont];
    [self updateEdgeInsets];
}

- (void)setFontMapping:(BPKFontMapping *_Nullable)fontMapping {
    if (_fontMapping != fontMapping) {
        _fontMapping = fontMapping;

        [self updateTitle];
    }
}

#pragma mark - State setters

- (void)setEnabled:(BOOL)enabled {
    BPKAssertMainThread();
    BOOL changed = self.isEnabled != enabled;

    [super setEnabled:enabled];

    if (changed) {
        [self updateBackgroundAndStyle];
        [self updateFont];
    }
}

- (void)setSelected:(BOOL)selected {
    BPKAssertMainThread();
    NSAssert(NO, @"The Backpack button does not support selected");
    [super setSelected:selected];
}

- (void)setHighlighted:(BOOL)highlighted {
    BPKAssertMainThread();
    [super setHighlighted:highlighted];
    if (self.isHighlighted != highlighted) {
        // TODO Update hightlighted overlay!
    }
}

- (void)setCornerRadius:(nullable NSNumber *)cornerRadius {
    if (_cornerRadius != cornerRadius) {
        _cornerRadius = cornerRadius;

        [self setNeedsLayout];
    }
}

#pragma mark - Layout

- (void)layoutSubviews {
    [super layoutSubviews];

    self.gradientLayer.frame = self.layer.bounds;

    if (self.style != BPKButtonStyleLink) {
        if (self.cornerRadius != nil && !self.iconOnly) {
            self.layer.cornerRadius = self.cornerRadius.doubleValue;
        } else {
            // Pill shape
            CGFloat radius = CGRectGetHeight(self.bounds) / 2.0f;
            [self.layer setCornerRadius:radius];
        }
    } else {
        self.layer.cornerRadius = 0;
    }
    CGFloat buttonTitleIconSpacing = [[self class] buttonTitleIconSpacing];

    if (self.isTextAndIcon) {
        if (self.imagePosition == BPKButtonImagePositionTrailing) {
            UIEdgeInsets titleEdgeInsets =
            [self bpk_makeRTLAwareEdgeInsetsWithTop:0
                                            leading:-(CGRectGetWidth(self.imageView.bounds) +
                                                      buttonTitleIconSpacing / 2.0)
                                             bottom:0
                                           trailing:(CGRectGetWidth(self.imageView.bounds) +
                                                     buttonTitleIconSpacing / 2.0)];
            self.titleEdgeInsets = titleEdgeInsets;

            UIEdgeInsets imageEdgeInsets =
            [self bpk_makeRTLAwareEdgeInsetsWithTop:0
                                            leading:(CGRectGetWidth(self.titleLabel.bounds) +
                                                     buttonTitleIconSpacing / 2.0)
                                             bottom:0
                                           trailing:-(CGRectGetWidth(self.titleLabel.bounds) +
                                                      buttonTitleIconSpacing / 2.0)];
            self.imageEdgeInsets = imageEdgeInsets;
        } else {
            UIEdgeInsets titleEdgeInsets = [self bpk_makeRTLAwareEdgeInsetsWithTop:0
                                                                           leading:(buttonTitleIconSpacing / 2.0)
                                                                            bottom:0
                                                                          trailing:-(buttonTitleIconSpacing / 2.0)];
            self.titleEdgeInsets = titleEdgeInsets;

            UIEdgeInsets imageEdgeInsets = [self bpk_makeRTLAwareEdgeInsetsWithTop:0
                                                                           leading:-(buttonTitleIconSpacing / 2.0)
                                                                            bottom:0
                                                                          trailing:(buttonTitleIconSpacing / 2.0)];
            self.imageEdgeInsets = imageEdgeInsets;
        }
    } else {
        self.titleEdgeInsets = UIEdgeInsetsZero;
        self.imageEdgeInsets = UIEdgeInsetsZero;
        self.contentEdgeInsets = self.contentEdgeInsets = [self contentEdgeInsetsForStyle:self.style size:self.size];
    }

    self.spinner.center = self.imageView.center;
    self.imageView.alpha = self.isLoading ? .0f : 1.f;
}

- (CGSize)intrinsicContentSize {
    CGSize superSize = [super intrinsicContentSize];
    if (self.isIconOnly || self.isTextOnly) {
        return superSize;
    }

    return CGSizeMake(superSize.width + [[self class] buttonTitleIconSpacing], superSize.height);
}

#pragma mark Spacing

- (UIEdgeInsets)contentEdgeInsetsForStyle:(BPKButtonStyle)style size:(BPKButtonSize)size {
    switch (style) {
        case BPKButtonStyleLink:
            return UIEdgeInsetsMake(BPKSpacingNone, BPKSpacingNone, BPKSpacingNone, BPKSpacingNone);

            // NOTE: Explicit fall-through
        case BPKButtonStylePrimary:
        case BPKButtonStyleFeatured:
        case BPKButtonStyleSecondary:
        case BPKButtonStyleDestructive:
        case BPKButtonStyleOutline:
            switch (size) {
                case BPKButtonSizeDefault: {
                    if (self.isIconOnly) {
                        return UIEdgeInsetsMake(BPKSpacingMd, BPKSpacingMd, BPKSpacingMd, BPKSpacingMd);
                    } else {
                        return UIEdgeInsetsMake(BPKSpacingMd, BPKSpacingSm * 3, BPKSpacingMd, BPKSpacingSm * 3);
                    }
                }
                case BPKButtonSizeLarge: {
                    if (self.isIconOnly) {
                        return UIEdgeInsetsMake(BPKSpacingSm * 3, BPKSpacingSm * 3, BPKSpacingSm * 3, BPKSpacingSm * 3);
                    } else {
                        return UIEdgeInsetsMake(BPKSpacingSm * 3, BPKSpacingBase, BPKSpacingSm * 3, BPKSpacingBase);
                    }
                }
                default:
                    NSAssert(NO, @"Unknown size %d", (int)size);
                    break;
            }
            break;
        default:
            NSAssert(NO, @"Unknown style %d", (int)style);
    }
}

#pragma mark - Updates

- (void)updateBackgroundAndStyle {
    // We need this here so that if the button was disabled, and is now enabled, opacity is reset.
    self.layer.opacity = 1;
    self.layer.borderWidth = 0;
    self.gradientLayer.gradient = nil;

    switch (self.style) {
        case BPKButtonStylePrimary:
        case BPKButtonStyleFeatured: {
            [self updateBackgroundAndStyleFilled];
            break;
        }
        case BPKButtonStyleSecondary:
        case BPKButtonStyleDestructive:
        case BPKButtonStyleOutline: {
            [self updateBackgroundAndStyleBoxy];
            break;
        }
        case BPKButtonStyleLink: {
            [self updateBackgroundAndStyleLink];
            break;
        }
    }
}

- (void)updateBackgroundAndStyleFilled {
    if (self.isEnabled && !self.isLoading) {
        UIColor *startColor = nil;
        UIColor *endColor = nil;
        UIColor *contentColor = nil;

        switch (self.style) {
            case BPKButtonStylePrimary: {
                startColor = self.primaryGradientStartColor ? self.primaryGradientStartColor : BPKColor.monteverde;
                endColor = self.primaryGradientEndColor ? self.primaryGradientEndColor : BPKColor.monteverde;
                contentColor = self.primaryContentColor ? self.primaryContentColor : BPKColor.white;
                break;
            }
            case BPKButtonStyleFeatured: {
                startColor = self.featuredGradientStartColor ? self.featuredGradientStartColor : BPKColor.skyBlue;
                endColor = self.featuredGradientEndColor ? self.featuredGradientEndColor : BPKColor.skyBlue;
                contentColor = self.featuredContentColor ? self.featuredContentColor : BPKColor.white;
                break;
            }
            default: {
                NSAssert(NO, @"Invalid style value %d", (int)self.style);
                break;
            }
        }
        if(startColor == endColor) {
            self.backgroundColor = startColor;
        }else{
            [self setFilledStyleWithNormalBackgroundColorGradientOnTop:startColor gradientOnBottom:endColor];
        }
        self.currentContentColor = contentColor;
        self.imageView.tintColor = contentColor;
    } else {
        self.backgroundColor = [self class].disabledBackgroundColor;
        self.currentContentColor = [self class].disabledContentColor;
        self.imageView.tintColor = [self class].disabledContentColor;
    }

    [self updateTitle];
    [self setNeedsDisplay];
}

- (void)updateBackgroundAndStyleBoxy {
        if (self.isEnabled && !self.isLoading) {
            UIColor *borderColor = nil;
            UIColor *backgroundColor = nil;
            UIColor *contentColor = nil;

            switch (self.style) {
                case BPKButtonStyleSecondary: {
                    borderColor = self.secondaryBorderColor ? self.secondaryBorderColor : [self class].boxyBorderColor;
                    backgroundColor = self.secondaryBackgroundColor ? self.secondaryBackgroundColor : [self class].boxyBackgroundColor;
                    contentColor = self.secondaryContentColor ? self.secondaryContentColor : BPKColor.primaryLightColor;
                    break;
                }
                case BPKButtonStyleDestructive: {
                    borderColor = self.destructiveBorderColor ? self.destructiveBorderColor : [self class].boxyBorderColor;
                    backgroundColor = self.destructiveBackgroundColor ? self.destructiveBackgroundColor : [self class].boxyBackgroundColor;
                    contentColor = self.destructiveContentColor ? self.destructiveContentColor : BPKColor.panjin;
                    break;
                }
                case BPKButtonStyleOutline: {
                    borderColor = BPKColor.white;
                    backgroundColor = BPKColor.clear;
                    contentColor = BPKColor.white;
                    break;
                }
                default: {
                    NSAssert(NO, @"Invalid style value %d", (int)self.style);
                    break;
                }
            }
            self.backgroundColor = backgroundColor;
            self.currentContentColor = contentColor;
            self.imageView.tintColor = contentColor;
            self.layer.borderColor = borderColor.CGColor;
        } else {
            self.backgroundColor = [self class].disabledBackgroundColor;
            self.currentContentColor = [self class].disabledContentColor;
            self.imageView.tintColor = [self class].disabledContentColor;
            self.layer.borderColor = [self class].disabledBorderColor.CGColor;
        }
        self.layer.borderWidth = 3;

    [self updateTitle];
        [self setNeedsDisplay];
    }


- (void)updateBackgroundAndStyleLink {
}

- (void)updateFont {
    if (self.isIconOnly) {
        self.titleLabel.font = [UIFont systemFontOfSize:0];
        [self setAttributedTitle:nil forState:UIControlStateNormal];
    }

    [self setNeedsDisplay];
}

//- (void)updateContentColor {
//    [self setTitleColor:self.currentContentColor forState:UIControlStateNormal];
//    if (self.title) {
//        NSAttributedString *attributedTitle = [BPKFont attributedStringWithFontStyle:self.currentFontStyle
//                                                                             content:self.title
//                                                                           textColor:self.currentContentColor
//                                                                         fontMapping:_fontMapping];
//        [self setAttributedTitle:attributedTitle forState:UIControlStateNormal];
//    } else {
//        [self setAttributedTitle:nil forState:UIControlStateNormal];
//    }
//
//    self.imageView.tintColor = self.currentContentColor;
//    UIColor *highlightedContentColor;
//
//    switch (self.style) {
//        case BPKButtonStylePrimary:
//            if (self.primaryContentColor != nil) {
//                highlightedContentColor = [BPKColor blend:self.primaryContentColor with:BPKColor.skyGray weight:0.85f];
//            } else {
//                highlightedContentColor = [self class].highlightedWhite;
//            }
//            break;
//        case BPKButtonStyleFeatured:
//            if (self.featuredContentColor != nil) {
//                highlightedContentColor = [BPKColor blend:self.featuredContentColor with:BPKColor.skyGray weight:0.85f];
//            } else {
//                highlightedContentColor = [self class].highlightedWhite;
//            }
//            break;
//        case BPKButtonStyleSecondary:
//            if (self.secondaryContentColor != nil) {
//                highlightedContentColor = [BPKColor blend:self.secondaryContentColor with:BPKColor.skyGray weight:0.85f];
//            } else {
//                highlightedContentColor = [self class].highlightedBlue;
//            }
//            break;
//        case BPKButtonStyleDestructive:
//            if (self.destructiveContentColor != nil) {
//                highlightedContentColor = [BPKColor blend:self.destructiveContentColor with:BPKColor.skyGray weight:0.85f];
//            } else {
//                highlightedContentColor = [self class].highlightedRed;
//            }
//            break;
//        case BPKButtonStyleOutline:
//            highlightedContentColor = [self class].highlightedOutline;
//            break;
//        case BPKButtonStyleLink:
//            highlightedContentColor = [self.currentContentColor colorWithAlphaComponent:0.2];
//            break;
//        default:
//            highlightedContentColor = nil;
//    }
//
//    if (highlightedContentColor) {
//        if (self.title) {
//            NSAttributedString *attributedHighlightedTitle =
//            [BPKFont attributedStringWithFontStyle:self.currentFontStyle
//                                           content:self.title
//                                         textColor:highlightedContentColor
//                                       fontMapping:_fontMapping];
//
//            [self setAttributedTitle:attributedHighlightedTitle forState:UIControlStateHighlighted];
//            [self setAttributedTitle:attributedHighlightedTitle forState:UIControlStateSelected];
//        }
//
//        self.imageView.tintColor = self.isHighlighted ? highlightedContentColor : self.currentContentColor;
//    }
//
//    [self setNeedsDisplay];
//}

- (void)updateEdgeInsets {
    if (self.isIconOnly) {
        self.imageEdgeInsets = UIEdgeInsetsZero;
        self.titleEdgeInsets = UIEdgeInsetsZero;
    }

    self.contentEdgeInsets = [self contentEdgeInsetsForStyle:self.style size:self.size];
    [self setNeedsLayout];
}

#pragma mark - Helpers

- (BPKFontStyle)currentFontStyle {
    switch (self.size) {
        case BPKButtonSizeDefault:
            return BPKFontStyleTextSmEmphasized;
        case BPKButtonSizeLarge:
            return BPKFontStyleTextLgEmphasized;
        default:
            NSAssert(NO, @"Unknown button size %ld", (unsigned long)self.size);
            return BPKFontStyleTextSmEmphasized;
    }
}

- (UIColor *)currentContentColor {
    if (!self.enabled) {
        return [self class].disabledContentColor;
    }
    switch (self.style) {
        case BPKButtonStylePrimary:
            if (self.primaryContentColor != nil) {
                return self.primaryContentColor;
            }
            return BPKColor.white;
        case BPKButtonStyleFeatured:
            if (self.featuredContentColor != nil) {
                return self.featuredContentColor;
            }
            return BPKColor.white;
        case BPKButtonStyleSecondary:
            if (self.secondaryContentColor != nil) {
                return self.secondaryContentColor;
            }
            return BPKColor.skyBlue;
        case BPKButtonStyleLink:
            if (self.linkContentColor != nil) {
                return self.linkContentColor;
            }
            return BPKColor.skyBlue;
        case BPKButtonStyleDestructive:
            if (self.destructiveContentColor != nil) {
                return self.destructiveContentColor;
            }
            return BPKColor.systemRed;
        case BPKButtonStyleOutline:
            return BPKColor.white;
        default:
            NSAssert(NO, @"Unknown BPKButtonStyle %d", (int)self.style);
            return BPKColor.white;
    }
}

- (BPKGradient *)gradientWithSingleColor:(UIColor *)color {
    NSParameterAssert(color);

    return [self gradientWithTopColor:color bottomColor:color];
}

- (BPKGradient *)gradientWithTopColor:(UIColor *)top bottomColor:(UIColor *)bottom {
    NSParameterAssert(top);
    NSParameterAssert(bottom);

    BPKGradientDirection direction = BPKGradientDirectionDown;
    return [[BPKGradient alloc] initWithColors:@[top, bottom]
                                    startPoint:[BPKGradient startPointForDirection:direction]
                                      endPoint:[BPKGradient endPointForDirection:direction]];
}

- (void)setFilledStyleWithNormalBackgroundColorGradientOnTop:(UIColor *)normalColorOnTop
                                            gradientOnBottom:(UIColor *)normalColorOnBottom {
    if (self.isHighlighted) {
        self.gradientLayer.gradient = [self gradientWithSingleColor:[BPKColor blend:normalColorOnTop
                                                                               with:BPKColor.skyGray
                                                                             weight:0.85f]];
    } else {
        self.gradientLayer.gradient = [self gradientWithTopColor:normalColorOnTop bottomColor:normalColorOnBottom];
    }
    [self.gradientLayer setNeedsDisplay];

    [self.layer setBorderColor:BPKColor.clear.CGColor];
    [self.layer setBorderWidth:0];
}

- (void)setBorderedStyleWithColor:(UIColor *)color withGradientColor:(UIColor *)gradientColor {
    self.gradientLayer.gradient = [self gradientWithSingleColor:gradientColor];

    UIColor *borderColor = color;
    [self.layer setBorderColor:borderColor.CGColor];
    self.layer.borderWidth = 2;
}

- (void)setLinkStyleWithColor:(UIColor *)color {
    self.gradientLayer.gradient = nil;

    [self.layer setBorderColor:BPKColor.clear.CGColor];
    [self.layer setBorderWidth:0];
}

- (void)setDisabledStyle {
    UIColor *backgroundColor = nil;
    switch (self.style) {
            // Explicit fall-through
        case BPKButtonStylePrimary:
        case BPKButtonStyleFeatured:
        case BPKButtonStyleSecondary:
        case BPKButtonStyleDestructive:
            backgroundColor = [self class].disabledBackgroundColor;
            break;
        case BPKButtonStyleOutline:
            backgroundColor = BPKColor.white;
            break;
        case BPKButtonStyleLink:
            backgroundColor = BPKColor.clear;
            break;
        default:
            backgroundColor = nil;
    }

    self.gradientLayer.gradient = [self gradientWithSingleColor:backgroundColor];
    [self setTintColor:[self class].disabledContentColor];
    [self setTitleColor:[self class].disabledContentColor forState:UIControlStateDisabled];
    self.layer.borderColor = BPKColor.clear.CGColor;
    self.layer.opacity = self.style == BPKButtonStyleOutline ? 0.8 : 1;
    self.layer.borderWidth = 0;
}

- (void)setupSpinner {
    self.spinner = [[UIActivityIndicatorView alloc] init];
    switch (self.size) {
        case BPKButtonSizeDefault:
            self.spinner.transform = CGAffineTransformMakeScale(.75f, .75f);
            break;

        case BPKButtonSizeLarge:
            self.spinner.transform = CGAffineTransformMakeScale(1.f, 1.f);
            break;
    }
    self.spinner.color = [self class].disabledContentColor;

    [self addSubview:self.spinner];
}

- (void)updateLoadingState:(BOOL)loading {
    self.enabled = !loading;
    self.spinner.hidden = !self.isLoading;

    if (!self.spinner && self.isLoading) {
        [self setupSpinner];
    }

    if (loading) {
        [self.spinner startAnimating];
    } else {
        [self.spinner stopAnimating];
    }
}

- (void)setFeaturedContentColor:(UIColor *_Nullable)featuredContentColor {
    if (featuredContentColor != _featuredContentColor) {
        _featuredContentColor = featuredContentColor;
        [self updateBackgroundAndStyle];
    }
}

- (void)setFeaturedGradientStartColor:(UIColor *_Nullable)featuredGradientStartColor {
    if (featuredGradientStartColor != _featuredGradientStartColor) {
        _featuredGradientStartColor = featuredGradientStartColor;
        [self updateBackgroundAndStyle];
    }
}

- (void)setFeaturedGradientEndColor:(UIColor *_Nullable)featuredGradientEndColor {
    if (featuredGradientEndColor != _featuredGradientEndColor) {
        _featuredGradientEndColor = featuredGradientEndColor;
        [self updateBackgroundAndStyle];
    }
}

- (void)setPrimaryContentColor:(UIColor *_Nullable)primaryContentColor {
    if (primaryContentColor != _primaryContentColor) {
        _primaryContentColor = primaryContentColor;
        [self updateBackgroundAndStyle];
    }
}

- (void)setPrimaryGradientStartColor:(UIColor *_Nullable)primaryGradientStartColor {
    if (primaryGradientStartColor != _primaryGradientStartColor) {
        _primaryGradientStartColor = primaryGradientStartColor;
        [self updateBackgroundAndStyle];
    }
}

- (void)setPrimaryGradientEndColor:(UIColor *_Nullable)primaryGradientEndColor {
    if (primaryGradientEndColor != _primaryGradientEndColor) {
        _primaryGradientEndColor = primaryGradientEndColor;
        [self updateBackgroundAndStyle];
    }
}

- (void)setSecondaryContentColor:(UIColor *_Nullable)secondaryContentColor {
    if (secondaryContentColor != _secondaryContentColor) {
        _secondaryContentColor = secondaryContentColor;
        [self updateBackgroundAndStyle];
    }
}

- (void)setSecondaryBackgroundColor:(UIColor *_Nullable)secondaryBackgroundColor {
    if (secondaryBackgroundColor != _secondaryBackgroundColor) {
        _secondaryBackgroundColor = secondaryBackgroundColor;
        [self updateBackgroundAndStyle];
    }
}

- (void)setSecondaryBorderColor:(UIColor *_Nullable)secondaryBorderColor {
    if (secondaryBorderColor != _secondaryBorderColor) {
        _secondaryBorderColor = secondaryBorderColor;
        [self updateBackgroundAndStyle];
    }
}

- (void)setDestructiveContentColor:(UIColor *_Nullable)destructiveContentColor {
    if (destructiveContentColor != _destructiveContentColor) {
        _destructiveContentColor = destructiveContentColor;
        [self updateBackgroundAndStyle];
    }
}

- (void)setDestructiveBackgroundColor:(UIColor *_Nullable)destructiveBackgroundColor {
    if (destructiveBackgroundColor != _destructiveBackgroundColor) {
        _destructiveBackgroundColor = destructiveBackgroundColor;
        [self updateBackgroundAndStyle];
    }
}

- (void)setDestructiveBorderColor:(UIColor *_Nullable)destructiveBorderColor {
    if (destructiveBorderColor != _destructiveBorderColor) {
        _destructiveBorderColor = destructiveBorderColor;
        [self updateBackgroundAndStyle];
    }
}

- (void)setLinkContentColor:(UIColor *_Nullable)linkContentColor {
    if (linkContentColor != _linkContentColor) {
        _linkContentColor = linkContentColor;
        [self updateBackgroundAndStyle];
    }
}

- (void)setIsLoading:(BOOL)isLoading {
    if (_isLoading != isLoading && self.currentImage) {
        _isLoading = isLoading;
        [self updateLoadingState: isLoading];
    }
}

// Note this is needed as the system does not correctly respond to the trait collection change to update the background color.
- (void) traitCollectionDidChange: (UITraitCollection *_Nullable) previousTraitCollection {
    [super traitCollectionDidChange: previousTraitCollection];
    if (@available(iOS 12.0, *)) {
        if(self.traitCollection.userInterfaceStyle != previousTraitCollection.userInterfaceStyle) {
            [self updateBackgroundAndStyle];
        }
    }
}

+ (UIColor *)disabledBackgroundColor {
    return [BPKColor dynamicColorWithLightVariant:BPKColor.skyGrayTint06 darkVariant:BPKColor.blackTint02];
}

+ (UIColor *)disabledContentColor {
    return [BPKColor dynamicColorWithLightVariant:BPKColor.skyGrayTint04 darkVariant:BPKColor.blackTint01];
}

+ (UIColor *)disabledBorderColor {
    return [BPKColor dynamicColorWithLightVariant:BPKColor.skyGrayTint03 darkVariant:BPKColor.black];
}

+ (UIColor *)boxyBackgroundColor {
    return [BPKColor dynamicColorWithLightVariant:BPKColor.white darkVariant:BPKColor.blackTint01];
}

+ (UIColor *)boxyBorderColor {
    return [BPKColor dynamicColorWithLightVariant:BPKColor.skyGrayTint06 darkVariant:BPKColor.blackTint02];
}

+ (CGFloat)buttonTitleIconSpacing {
    return BPKSpacingSm;
}

@end

NS_ASSUME_NONNULL_END
