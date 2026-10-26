#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

@interface ChronoView : UIView <UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextFieldDelegate>
@property (nonatomic, strong) UIImageView *bgImageView;
@property (nonatomic, strong) UIView *dimView;
@property (nonatomic, strong) UITextField *titleField;
@property (nonatomic, strong) UILabel *timeLabel;
@property (nonatomic, strong) UIButton *startStopBtn;
@property (nonatomic, strong) UIButton *resetBtn;
@property (nonatomic, strong) UIButton *imageBtn;
@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic) NSTimeInterval accumulated;
@property (nonatomic) NSTimeInterval startTime;
@property (nonatomic) BOOL running;
@end

static UIWindow *KeyWindow(void) {
    for (UIScene *s in UIApplication.sharedApplication.connectedScenes) {
        if ([s isKindOfClass:[UIWindowScene class]]) {
            for (UIWindow *w in ((UIWindowScene *)s).windows) {
                if (w.isKeyWindow) return w;
            }
        }
    }
    return UIApplication.sharedApplication.windows.firstObject;
}

static UIViewController *TopVC(void) {
    UIViewController *vc = KeyWindow().rootViewController;
    while (vc.presentedViewController) vc = vc.presentedViewController;
    return vc;
}

@implementation ChronoView

- (instancetype)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        self.backgroundColor = [UIColor colorWithWhite:0.1 alpha:0.9];
        self.layer.cornerRadius = 16;
        self.clipsToBounds = YES;

        // Image de fond
        _bgImageView = [[UIImageView alloc] initWithFrame:self.bounds];
        _bgImageView.contentMode = UIViewContentModeScaleAspectFill;
        _bgImageView.clipsToBounds = YES;
        [self addSubview:_bgImageView];

        // Voile sombre pour la lisibilité
        _dimView = [[UIView alloc] initWithFrame:self.bounds];
        _dimView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.35];
        _dimView.hidden = YES;
        [self addSubview:_dimView];

        // Texte au-dessus du chrono
        _titleField = [[UITextField alloc] initWithFrame:CGRectMake(10, 8, 220, 28)];
        _titleField.placeholder = @"Écrire un texte…";
        _titleField.textColor = UIColor.whiteColor;
        _titleField.textAlignment = NSTextAlignmentCenter;
        _titleField.font = [UIFont boldSystemFontOfSize:16];
        _titleField.returnKeyType = UIReturnKeyDone;
        _titleField.delegate = self;
        _titleField.attributedPlaceholder = [[NSAttributedString alloc]
            initWithString:@"Écrire un texte…"
                attributes:@{NSForegroundColorAttributeName: [UIColor colorWithWhite:1 alpha:0.5]}];
        [self addSubview:_titleField];

        // Affichage du temps
        _timeLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 40, 220, 50)];
        _timeLabel.textColor = UIColor.whiteColor;
        _timeLabel.textAlignment = NSTextAlignmentCenter;
        _timeLabel.font = [UIFont monospacedDigitSystemFontOfSize:36 weight:UIFontWeightBold];
        _timeLabel.adjustsFontSizeToFitWidth = YES;
        _timeLabel.text = @"00:00.00";
        [self addSubview:_timeLabel];

        // Boutons
        _startStopBtn = [self makeButton:@"Démarrer" x:10 action:@selector(toggle)];
        _resetBtn     = [self makeButton:@"Reset"    x:85 action:@selector(reset)];
        _imageBtn     = [self makeButton:@"Image"    x:160 action:@selector(imageMenu)];

        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(drag:)];
        [self addGestureRecognizer:pan];
    }
    return self;
}

- (UIButton *)makeButton:(NSString *)title x:(CGFloat)x action:(SEL)sel {
    UIButton *b = [UIButton buttonWithType:UIButtonTypeSystem];
    b.frame = CGRectMake(x, 105, 70, 40);
    [b setTitle:title forState:UIControlStateNormal];
    [b setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    b.titleLabel.font = [UIFont boldSystemFontOfSize:14];
    b.backgroundColor = [UIColor colorWithWhite:1 alpha:0.2];
    b.layer.cornerRadius = 10;
    [b addTarget:self action:sel forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:b];
    return b;
}

#pragma mark - Chrono

- (NSTimeInterval)elapsed {
    return self.accumulated + (self.running ? CACurrentMediaTime() - self.startTime : 0);
}

- (void)refresh {
    NSTimeInterval t = [self elapsed];
    int h = (int)(t / 3600);
    int m = ((int)t % 3600) / 60;
    int s = (int)t % 60;
    int c = (int)((t - floor(t)) * 100);
    self.timeLabel.text = h > 0
        ? [NSString stringWithFormat:@"%d:%02d:%02d.%02d", h, m, s, c]
        : [NSString stringWithFormat:@"%02d:%02d.%02d", m, s, c];
}

- (void)toggle {
    if (self.running) {
        // Arrêt
        self.accumulated += CACurrentMediaTime() - self.startTime;
        self.running = NO;
        [self.timer invalidate];
        self.timer = nil;
        [self refresh];
        [self.startStopBtn setTitle:@"Reprendre" forState:UIControlStateNormal];
    } else {
        // Démarrage / reprise
        self.startTime = CACurrentMediaTime();
        self.running = YES;
        self.timer = [NSTimer timerWithTimeInterval:0.03 target:self selector:@selector(refresh) userInfo:nil repeats:YES];
        [[NSRunLoop mainRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];
        [self.startStopBtn setTitle:@"Stop" forState:UIControlStateNormal];
    }
}

- (void)reset {
    [self.timer invalidate];
    self.timer = nil;
    self.running = NO;
    self.accumulated = 0;
    [self refresh];
    [self.startStopBtn setTitle:@"Démarrer" forState:UIControlStateNormal];
}

#pragma mark - Image de fond

- (void)imageMenu {
    UIAlertController *ac = [UIAlertController alertControllerWithTitle:@"Image de fond"
                                                                message:nil
                                                         preferredStyle:UIAlertControllerStyleAlert];
    [ac addAction:[UIAlertAction actionWithTitle:@"Choisir une image" style:UIAlertActionStyleDefault handler:^(UIAlertAction *a) {
        UIImagePickerController *p = [UIImagePickerController new];
        p.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        p.delegate = self;
        [TopVC() presentViewController:p animated:YES completion:nil];
    }]];
    if (self.bgImageView.image) {
        [ac addAction:[UIAlertAction actionWithTitle:@"Retirer l'image" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *a) {
            self.bgImageView.image = nil;
            self.dimView.hidden = YES;
        }]];
    }
    [ac addAction:[UIAlertAction actionWithTitle:@"Annuler" style:UIAlertActionStyleCancel handler:nil]];
    [TopVC() presentViewController:ac animated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<UIImagePickerControllerInfoKey,id> *)info {
    UIImage *img = info[UIImagePickerControllerOriginalImage];
    if (img) {
        self.bgImageView.image = img;
        self.dimView.hidden = NO;
    }
    [picker dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Divers

- (BOOL)textFieldShouldReturn:(UITextField *)tf {
    [tf resignFirstResponder];
    return YES;
}

- (void)drag:(UIPanGestureRecognizer *)g {
    CGPoint d = [g translationInView:self.superview];
    CGPoint c = CGPointMake(self.center.x + d.x, self.center.y + d.y);
    CGRect b = self.superview.bounds;
    c.x = MAX(self.bounds.size.width / 2, MIN(b.size.width - self.bounds.size.width / 2, c.x));
    c.y = MAX(self.bounds.size.height / 2, MIN(b.size.height - self.bounds.size.height / 2, c.y));
    self.center = c;
    [g setTranslation:CGPointZero inView:self.superview];
}

@end

#pragma mark - Entrée du dylib

static ChronoView *gChrono = nil;

static void ShowChrono(void) {
    if (gChrono) return;
    UIWindow *w = KeyWindow();
    if (!w) return;
    gChrono = [[ChronoView alloc] initWithFrame:CGRectMake(20, 100, 240, 160)];
    [w addSubview:gChrono];
}

__attribute__((constructor))
static void chrono_init(void) {
    [[NSNotificationCenter defaultCenter]
        addObserverForName:UIApplicationDidBecomeActiveNotification
                    object:nil
                     queue:NSOperationQueue.mainQueue
                usingBlock:^(NSNotification *n) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)),
                       dispatch_get_main_queue(), ^{ ShowChrono(); });
    }];
}
