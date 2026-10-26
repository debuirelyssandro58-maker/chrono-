// Chrono.m — v3 (style LiveSplit)
//
// Utilisation :
//   1 clic sur le chrono  -> lance
//   1 clic                -> pause
//   1 clic en pause       -> reset
//   Appui long            -> réglages
//   Glisser               -> déplacer
//
// Frameworks : Foundation, UIKit, QuartzCore, PhotosUI, CoreGraphics

#import <UIKit/UIKit.h>
#import <PhotosUI/PhotosUI.h>
#import <QuartzCore/QuartzCore.h>
#import <CoreGraphics/CoreGraphics.h>

#pragma clang diagnostic ignored "-Wunguarded-availability-new"
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"

#define kScale   @"chrono3_scale"
#define kSat     @"chrono3_saturation"
#define kOpacity @"chrono3_bg_opacity"
#define kRunC    @"chrono3_color_run"
#define kPauseC  @"chrono3_color_pause"
#define kBgC     @"chrono3_color_bg"
#define kTextC   @"chrono3_color_text"
#define kText    @"chrono_text"

typedef NS_ENUM(NSInteger, CRState) { CRStateIdle, CRStateRunning, CRStatePaused };

#pragma mark - Helpers

static UIWindow *CRKeyWindow(void) {
    UIWindow *fallback = nil;
    for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
        if (![scene isKindOfClass:UIWindowScene.class]) continue;
        UIWindowScene *ws = (UIWindowScene *)scene;
        if (ws.activationState != UISceneActivationStateForegroundActive) continue;
        for (UIWindow *w in ws.windows) {
            if (w.isKeyWindow) return w;
        }
        if (!fallback) fallback = ws.windows.firstObject;
    }
    return fallback;
}

static UIViewController *CRTop(UIViewController *vc) {
    while (vc.presentedViewController) vc = vc.presentedViewController;
    return vc;
}

static NSString *CRImagePath(void) {
    NSString *dir = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    return [dir stringByAppendingPathComponent:@"chrono_bg.jpg"];
}

static UIColor *CRLoadColor(NSString *key, UIColor *def) {
    NSData *d = [NSUserDefaults.standardUserDefaults dataForKey:key];
    UIColor *c = d ? [NSKeyedUnarchiver unarchivedObjectOfClass:UIColor.class fromData:d error:nil] : nil;
    return c ?: def;
}

static void CRSaveColor(NSString *key, UIColor *c) {
    NSData *d = [NSKeyedArchiver archivedDataWithRootObject:c requiringSecureCoding:YES error:nil];
    if (d) [NSUserDefaults.standardUserDefaults setObject:d forKey:key];
}

#pragma mark - Classes

@interface CRChrono : NSObject <PHPickerViewControllerDelegate, UITextFieldDelegate>
+ (instancetype)shared;
- (void)installWhenReady;
- (void)layoutChanged;
@end

// Fenêtre par-dessus le jeu : laisse passer les touches là où il n'y a rien.
@interface CROverlayWindow : UIWindow
@end

@implementation CROverlayWindow
- (BOOL)canBecomeKeyWindow { return YES; }
- (UIView *)hitTest:(CGPoint)p withEvent:(UIEvent *)e {
    UIView *v = [super hitTest:p withEvent:e];
    if (v == nil || v == self || v == self.rootViewController.view || v.tag == 7001) return nil;
    return v;
}
@end

@interface CRRootVC : UIViewController
@end

@implementation CRRootVC
- (void)loadView {
    UIView *v = [UIView new];
    v.backgroundColor = UIColor.clearColor;
    self.view = v;
}
- (UIInterfaceOrientationMask)supportedInterfaceOrientations { return UIInterfaceOrientationMaskAll; }
- (BOOL)shouldAutorotate { return YES; }
- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [[CRChrono shared] layoutChanged];
}
@end

#pragma mark - Chrono

@implementation CRChrono {
    UIWindow *_gameWindow;
    CROverlayWindow *_overlay;
    CRRootVC *_rootVC;

    UIView *_box;          // chrono + texte
    UILabel *_textLabel;   // texte, au-dessus et hors du chrono
    UIView *_card;         // le chrono
    UIImageView *_bg;
    UIView *_tint;
    UILabel *_timeLabel;

    UIView *_panel;
    UIScrollView *_scroll;
    UILabel *_satValue;
    UILabel *_opValue;
    UITextField *_field;

    NSTimer *_timer;
    CFTimeInterval _startTime;
    NSTimeInterval _accumulated;
    CRState _state;

    CGFloat _scale;
    CGFloat _saturation;
    CGFloat _bgOpacity;
    UIColor *_runColor;
    UIColor *_pauseColor;
    UIColor *_bgColor;
    UIColor *_textColor;
    NSString *_text;
    BOOL _editing;
}

+ (instancetype)shared {
    static CRChrono *s; static dispatch_once_t once;
    dispatch_once(&once, ^{ s = [CRChrono new]; });
    return s;
}

#pragma mark Install

- (void)installWhenReady {
    UIWindow *w = CRKeyWindow();
    if (!w || !w.windowScene) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            [self installWhenReady];
        });
        return;
    }
    _gameWindow = w;
    [self loadPrefs];

    _overlay = [[CROverlayWindow alloc] initWithWindowScene:w.windowScene];
    _overlay.windowLevel = UIWindowLevelAlert + 100;
    _overlay.backgroundColor = UIColor.clearColor;
    _rootVC = [CRRootVC new];
    _overlay.rootViewController = _rootVC;
    _overlay.hidden = NO;

    [self buildBox];
    [self buildPanel];
    [self applyStyle];
    [self applySaturation];
}

- (void)loadPrefs {
    NSUserDefaults *d = NSUserDefaults.standardUserDefaults;
    float sc = [d floatForKey:kScale];
    _scale = (sc >= 0.4 && sc <= 1.4) ? sc : 1.0;
    float sat = [d objectForKey:kSat] ? [d floatForKey:kSat] : 50;
    _saturation = MAX(1, MIN(100, sat));
    _bgOpacity = [d objectForKey:kOpacity] ? [d floatForKey:kOpacity] : 0.55;
    _text = [d stringForKey:kText] ?: @"";
    _runColor   = CRLoadColor(kRunC,   [UIColor colorWithRed:0.24 green:0.86 blue:0.52 alpha:1]);
    _pauseColor = CRLoadColor(kPauseC, [UIColor colorWithRed:1.00 green:0.69 blue:0.13 alpha:1]);
    _bgColor    = CRLoadColor(kBgC,    UIColor.blackColor);
    _textColor  = CRLoadColor(kTextC,  UIColor.whiteColor);
}

- (void)savePrefs {
    NSUserDefaults *d = NSUserDefaults.standardUserDefaults;
    [d setFloat:_scale forKey:kScale];
    [d setFloat:_saturation forKey:kSat];
    [d setFloat:_bgOpacity forKey:kOpacity];
    [d setObject:_text ?: @"" forKey:kText];
    CRSaveColor(kRunC, _runColor);
    CRSaveColor(kPauseC, _pauseColor);
    CRSaveColor(kBgC, _bgColor);
    CRSaveColor(kTextC, _textColor);
}

#pragma mark UI helpers

- (UIButton *)buttonTitle:(NSString *)title frame:(CGRect)f action:(SEL)a {
    UIButton *b = [UIButton buttonWithType:UIButtonTypeSystem];
    b.frame = f;
    [b setTitle:title forState:UIControlStateNormal];
    [b setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    b.titleLabel.font = [UIFont boldSystemFontOfSize:14];
    b.backgroundColor = [UIColor colorWithWhite:1 alpha:0.2];
    b.layer.cornerRadius = 8;
    [b addTarget:self action:a forControlEvents:UIControlEventTouchUpInside];
    return b;
}

- (UILabel *)labelText:(NSString *)t frame:(CGRect)f size:(CGFloat)sz {
    UILabel *l = [[UILabel alloc] initWithFrame:f];
    l.text = t;
    l.textColor = UIColor.whiteColor;
    l.font = [UIFont boldSystemFontOfSize:sz];
    return l;
}

- (UISlider *)sliderMin:(float)mn max:(float)mx value:(float)v frame:(CGRect)f action:(SEL)a {
    UISlider *s = [[UISlider alloc] initWithFrame:f];
    s.minimumValue = mn;
    s.maximumValue = mx;
    s.value = v;
    [s addTarget:self action:a forControlEvents:UIControlEventValueChanged];
    return s;
}

#pragma mark Le chrono

- (void)buildBox {
    UIView *root = _rootVC.view;

    _box = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 200, 100)];
    _box.tag = 7001;
    _box.center = CGPointMake(_overlay.bounds.size.width / 2, 80);
    [root addSubview:_box];

    // Texte : au-dessus du chrono, en dehors
    _textLabel = [self labelText:_text frame:CGRectMake(0, 0, 200, 22) size:14];
    _textLabel.textAlignment = NSTextAlignmentCenter;
    _textLabel.adjustsFontSizeToFitWidth = YES;
    _textLabel.minimumScaleFactor = 0.6;
    _textLabel.layer.shadowColor = UIColor.blackColor.CGColor;
    _textLabel.layer.shadowOpacity = 0.9;
    _textLabel.layer.shadowRadius = 2;
    _textLabel.layer.shadowOffset = CGSizeMake(0, 1);
    [_box addSubview:_textLabel];

    // Chrono
    _card = [[UIView alloc] initWithFrame:CGRectMake(0, 24, 200, 76)];
    _card.layer.cornerRadius = 10;
    _card.clipsToBounds = YES;
    [_box addSubview:_card];

    _bg = [[UIImageView alloc] initWithFrame:_card.bounds];
    _bg.contentMode = UIViewContentModeScaleAspectFill;
    _bg.clipsToBounds = YES;
    _bg.image = [UIImage imageWithContentsOfFile:CRImagePath()];
    [_card addSubview:_bg];

    _tint = [[UIView alloc] initWithFrame:_card.bounds];
    [_card addSubview:_tint];

    _timeLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, 180, 76)];
    _timeLabel.textAlignment = NSTextAlignmentRight;
    _timeLabel.adjustsFontSizeToFitWidth = YES;
    _timeLabel.minimumScaleFactor = 0.5;
    [_card addSubview:_timeLabel];

    // Gestes : clic, appui long, glisser
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapped)];
    UILongPressGestureRecognizer *lp = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPress:)];
    lp.minimumPressDuration = 0.6;
    [tap requireGestureRecognizerToFail:lp];
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(pan:)];
    [_card addGestureRecognizer:tap];
    [_card addGestureRecognizer:lp];
    [_card addGestureRecognizer:pan];
}

- (void)pan:(UIPanGestureRecognizer *)g {
    UIView *sv = _box.superview;
    CGPoint t = [g translationInView:sv];
    _box.center = CGPointMake(_box.center.x + t.x, _box.center.y + t.y);
    [g setTranslation:CGPointZero inView:sv];
}

- (void)longPress:(UILongPressGestureRecognizer *)g {
    if (g.state == UIGestureRecognizerStateBegan) [self openSettings];
}

- (void)layoutChanged {
    if (!_box) return;
    CGSize b = _rootVC.view.bounds.size;
    CGPoint c = _box.center;
    c.x = MAX(20, MIN(b.width - 20, c.x));
    c.y = MAX(20, MIN(b.height - 20, c.y));
    _box.center = c;
    if (_panel && !_panel.hidden) [self layoutPanel];
}

#pragma mark Logique du chrono

- (NSTimeInterval)elapsed {
    return _accumulated + (_state == CRStateRunning ? CACurrentMediaTime() - _startTime : 0);
}

// 1 clic : lancer / pause / (en pause) reset
- (void)tapped {
    switch (_state) {
        case CRStateIdle:
            _startTime = CACurrentMediaTime();
            _state = CRStateRunning;
            _timer = [NSTimer scheduledTimerWithTimeInterval:0.02 target:self selector:@selector(tick) userInfo:nil repeats:YES];
            [NSRunLoop.mainRunLoop addTimer:_timer forMode:NSRunLoopCommonModes];
            break;
        case CRStateRunning:
            _accumulated += CACurrentMediaTime() - _startTime;
            _state = CRStatePaused;
            [_timer invalidate];
            _timer = nil;
            break;
        case CRStatePaused:
            _accumulated = 0;
            _state = CRStateIdle;
            break;
    }
    [self showTime:[self elapsed]];
}

- (void)tick {
    [self showTime:[self elapsed]];
}

- (void)showTime:(NSTimeInterval)t {
    int cs = (int)(t * 100) % 100;
    int s  = (int)t % 60;
    int m  = ((int)t / 60) % 60;
    int h  = (int)t / 3600;
    NSString *main = h > 0 ? [NSString stringWithFormat:@"%d:%02d:%02d", h, m, s]
                           : [NSString stringWithFormat:@"%d:%02d", m, s];
    NSString *dec = [NSString stringWithFormat:@".%02d", cs];
    UIColor *c = (_state == CRStatePaused) ? _pauseColor : _runColor;

    NSMutableAttributedString *a = [[NSMutableAttributedString alloc] initWithString:main attributes:@{
        NSFontAttributeName: [UIFont monospacedDigitSystemFontOfSize:46 weight:UIFontWeightSemibold],
        NSForegroundColorAttributeName: c }];
    [a appendAttributedString:[[NSAttributedString alloc] initWithString:dec attributes:@{
        NSFontAttributeName: [UIFont monospacedDigitSystemFontOfSize:26 weight:UIFontWeightSemibold],
        NSForegroundColorAttributeName: c }]];
    _timeLabel.attributedText = a;
}

#pragma mark Style

- (void)applyStyle {
    _box.transform = CGAffineTransformMakeScale(_scale, _scale);
    _tint.backgroundColor = [_bgColor colorWithAlphaComponent:_bgOpacity];
    _textLabel.textColor = _textColor;
    _textLabel.text = _text;
    [self showTime:[self elapsed]];
}

// Saturation de l'écran du jeu : 1 à 100 (50 = normal)
- (void)applySaturation {
    if (!_gameWindow) return;
    if (fabs(_saturation - 50) < 0.5) {
        _gameWindow.layer.filters = nil;
        return;
    }
    Class cls = NSClassFromString(@"CAFilter");
    SEL sel = NSSelectorFromString(@"filterWithType:");
    if (!cls || ![cls respondsToSelector:sel]) return;
    id f = [cls performSelector:sel withObject:@"colorSaturate"];
    if (!f) return;
    [f setValue:@(_saturation / 50.0) forKey:@"inputAmount"];
    _gameWindow.layer.filters = @[f];
}

#pragma mark Réglages

- (void)buildPanel {
    CGFloat pw = 300, W = pw - 32, y = 14;

    _panel = [[UIView alloc] initWithFrame:CGRectMake(0, 0, pw, 400)];
    _panel.backgroundColor = [UIColor colorWithWhite:0.08 alpha:0.96];
    _panel.layer.cornerRadius = 16;
    _panel.hidden = YES;
    [_rootVC.view addSubview:_panel];

    _scroll = [[UIScrollView alloc] initWithFrame:_panel.bounds];
    _scroll.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [_panel addSubview:_scroll];

    UILabel *title = [self labelText:@"Réglages" frame:CGRectMake(0, y, pw, 24) size:18];
    title.textAlignment = NSTextAlignmentCenter;
    [_scroll addSubview:title];
    y += 40;

    // Taille
    [_scroll addSubview:[self labelText:@"Taille" frame:CGRectMake(16, y, W, 20) size:14]];
    y += 22;
    [_scroll addSubview:[self sliderMin:0.4 max:1.4 value:_scale frame:CGRectMake(16, y, W, 30) action:@selector(sizeChanged:)]];
    y += 42;

    // Saturation
    [_scroll addSubview:[self labelText:@"Saturation du jeu (50 = normal)" frame:CGRectMake(16, y, W - 50, 20) size:14]];
    _satValue = [self labelText:[NSString stringWithFormat:@"%d", (int)_saturation] frame:CGRectMake(16 + W - 46, y, 46, 20) size:14];
    _satValue.textAlignment = NSTextAlignmentRight;
    [_scroll addSubview:_satValue];
    y += 22;
    [_scroll addSubview:[self sliderMin:1 max:100 value:_saturation frame:CGRectMake(16, y, W, 30) action:@selector(satChanged:)]];
    y += 42;

    // Couleurs
    y = [self colorRow:@"Chrono en marche" tag:1 color:_runColor y:y width:W];
    y = [self colorRow:@"Chrono en pause" tag:2 color:_pauseColor y:y width:W];
    y = [self colorRow:@"Fond du chrono" tag:3 color:_bgColor y:y width:W];
    y = [self colorRow:@"Couleur du texte" tag:4 color:_textColor y:y width:W];

    // Opacité du fond
    [_scroll addSubview:[self labelText:@"Opacité du fond" frame:CGRectMake(16, y, W - 50, 20) size:14]];
    _opValue = [self labelText:[NSString stringWithFormat:@"%d%%", (int)roundf(_bgOpacity * 100)] frame:CGRectMake(16 + W - 46, y, 46, 20) size:14];
    _opValue.textAlignment = NSTextAlignmentRight;
    [_scroll addSubview:_opValue];
    y += 22;
    [_scroll addSubview:[self sliderMin:0 max:100 value:_bgOpacity * 100 frame:CGRectMake(16, y, W, 30) action:@selector(opChanged:)]];
    y += 42;

    // Texte
    [_scroll addSubview:[self labelText:@"Texte (au-dessus du chrono)" frame:CGRectMake(16, y, W, 20) size:14]];
    y += 24;
    _field = [[UITextField alloc] initWithFrame:CGRectMake(16, y, W, 34)];
    _field.text = _text;
    _field.textColor = UIColor.whiteColor;
    _field.backgroundColor = [UIColor colorWithWhite:1 alpha:0.15];
    _field.layer.cornerRadius = 8;
    _field.leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 8, 34)];
    _field.leftViewMode = UITextFieldViewModeAlways;
    _field.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"Ton texte"
        attributes:@{NSForegroundColorAttributeName: [UIColor colorWithWhite:1 alpha:0.5]}];
    _field.returnKeyType = UIReturnKeyDone;
    _field.delegate = self;
    [_field addTarget:self action:@selector(textChanged:) forControlEvents:UIControlEventEditingChanged];
    [_scroll addSubview:_field];
    y += 46;

    // Image
    [_scroll addSubview:[self buttonTitle:@"Choisir une image" frame:CGRectMake(16, y, W, 34) action:@selector(pickImage)]];
    y += 42;
    [_scroll addSubview:[self buttonTitle:@"Retirer l'image" frame:CGRectMake(16, y, W, 34) action:@selector(removeImage)]];
    y += 42;
    [_scroll addSubview:[self buttonTitle:@"Fermer" frame:CGRectMake(16, y, W, 34) action:@selector(closeSettings)]];
    y += 48;

    _scroll.contentSize = CGSizeMake(pw, y);
}

- (CGFloat)colorRow:(NSString *)title tag:(NSInteger)tag color:(UIColor *)c y:(CGFloat)y width:(CGFloat)W {
    [_scroll addSubview:[self labelText:title frame:CGRectMake(16, y + 6, W - 60, 20) size:14]];
    UIColorWell *w = [[UIColorWell alloc] initWithFrame:CGRectMake(16 + W - 48, y, 48, 32)];
    w.tag = tag;
    w.title = title;
    w.supportsAlpha = NO;
    w.selectedColor = c;
    [w addTarget:self action:@selector(colorChanged:) forControlEvents:UIControlEventValueChanged];
    [_scroll addSubview:w];
    return y + 44;
}

- (void)layoutPanel {
    CGSize b = _rootVC.view.bounds.size;
    CGFloat h = MIN(_scroll.contentSize.height, b.height - 24);
    if (_editing) h = MIN(h, 150);
    _panel.frame = CGRectMake((b.width - 300) / 2, _editing ? 8 : (b.height - h) / 2, 300, h);
}

- (void)openSettings {
    _panel.hidden = NO;
    [_rootVC.view bringSubviewToFront:_panel];
    [self layoutPanel];
}

- (void)closeSettings {
    [_field resignFirstResponder];
    _panel.hidden = YES;
    [self savePrefs];
}

- (void)sizeChanged:(UISlider *)s {
    _scale = s.value;
    [self applyStyle];
    [self savePrefs];
}

- (void)satChanged:(UISlider *)s {
    _saturation = roundf(s.value);
    _satValue.text = [NSString stringWithFormat:@"%d", (int)_saturation];
    [self applySaturation];
    [self savePrefs];
}

- (void)opChanged:(UISlider *)s {
    _bgOpacity = roundf(s.value) / 100.0;
    _opValue.text = [NSString stringWithFormat:@"%d%%", (int)roundf(s.value)];
    [self applyStyle];
    [self savePrefs];
}

- (void)colorChanged:(UIColorWell *)w {
    UIColor *c = w.selectedColor;
    if (!c) return;
    switch (w.tag) {
        case 1: _runColor = c; break;
        case 2: _pauseColor = c; break;
        case 3: _bgColor = c; break;
        case 4: _textColor = c; break;
    }
    [self applyStyle];
    [self savePrefs];
}

- (void)textChanged:(UITextField *)f {
    _text = f.text ?: @"";
    _textLabel.text = _text;
    [self savePrefs];
}

#pragma mark Clavier

- (BOOL)textFieldShouldReturn:(UITextField *)f {
    [f resignFirstResponder];
    return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)f {
    _editing = YES;
    [_overlay makeKeyWindow];
    [self layoutPanel];
    [_scroll setContentOffset:CGPointMake(0, MAX(0, f.frame.origin.y - 36)) animated:NO];
}

- (void)textFieldDidEndEditing:(UITextField *)f {
    _editing = NO;
    [self layoutPanel];
    [_gameWindow makeKeyWindow];
}

#pragma mark Image

- (void)pickImage {
    PHPickerConfiguration *cfg = [[PHPickerConfiguration alloc] init];
    cfg.filter = PHPickerFilter.imagesFilter;
    cfg.selectionLimit = 1;
    PHPickerViewController *p = [[PHPickerViewController alloc] initWithConfiguration:cfg];
    p.delegate = self;
    [CRTop(_rootVC) presentViewController:p animated:YES completion:nil];
}

- (void)removeImage {
    [NSFileManager.defaultManager removeItemAtPath:CRImagePath() error:nil];
    _bg.image = nil;
}

- (void)picker:(PHPickerViewController *)picker didFinishPicking:(NSArray<PHPickerResult *> *)results {
    [picker dismissViewControllerAnimated:YES completion:nil];
    PHPickerResult *r = results.firstObject;
    if (!r || ![r.itemProvider canLoadObjectOfClass:UIImage.class]) return;
    [r.itemProvider loadObjectOfClass:UIImage.class completionHandler:^(id obj, NSError *err) {
        if (![obj isKindOfClass:UIImage.class]) return;
        UIImage *img = (UIImage *)obj;
        NSData *d = UIImageJPEGRepresentation(img, 0.85);
        [d writeToFile:CRImagePath() atomically:YES];
        dispatch_async(dispatch_get_main_queue(), ^{ self->_bg.image = img; });
    }];
}

@end

#pragma mark - Entrée du dylib

__attribute__((constructor))
static void CRInit(void) {
    dispatch_async(dispatch_get_main_queue(), ^{
        [[CRChrono shared] installWhenReady];
    });
}
