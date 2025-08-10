@Entry
@Component
struct SplashPage {
  @State currentStep: number = 0
  private steps: string[] = [
    '智能证件管理',
    'AI识别技术',
    '一键编辑美化',
    '无线打印功能'
  ]

  aboutToAppear() {
    this.startAnimation()
  }

  startAnimation() {
    let stepIndex = 0
    const interval = setInterval(() => {
      this.currentStep = stepIndex
      stepIndex++
      
      if (stepIndex >= this.steps.length) {
        clearInterval(interval)
        setTimeout(() => {
          this.navigateToMain()
        }, 1000)
      }
    }, 1500)
  }

  build() {
    Stack() {
      // 背景
      Column() {
        Image($r('app.media.background'))
          .width('100%')
          .height('100%')
          .objectFit(ImageFit.Cover)
      }
      .width('100%')
      .height('100%')

      // 内容区域
      Column() {
        // Logo区域
        Column() {
          Image($r('app.media.foreground'))
            .width(120)
            .height(120)
            .borderRadius(60)
            .margin({ bottom: 20 })

          Text('证件管理')
            .fontSize(32)
            .fontWeight(FontWeight.Bold)
            .fontColor(Color.White)
            .margin({ bottom: 8 })

          Text('安全 · 高效 · 智能')
            .fontSize(16)
            .fontColor('#E0E0E0')
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .margin({ top: 100 })

        // 功能展示
        Column() {
          Text(this.steps[this.currentStep])
            .fontSize(24)
            .fontWeight(FontWeight.Medium)
            .fontColor(Color.White)
            .textAlign(TextAlign.Center)
            .margin({ bottom: 20 })

          // 功能图标
          Row() {
            ForEach(['📱', '🤖', '✏️', '🖨️'], (icon: string, index: number) => {
              Text(icon)
                .fontSize(32)
                .opacity(index === this.currentStep ? 1 : 0.3)
                .margin({ right: 20 })
                .animation({
                  duration: 300,
                  curve: Curve.EaseInOut
                })
            })
          }
          .justifyContent(FlexAlign.Center)
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)

        // 进度指示器
        Row() {
          ForEach(this.steps, (step: string, index: number) => {
            Circle()
              .width(8)
              .height(8)
              .fill(index === this.currentStep ? Color.White : '#80FFFFFF')
              .margin({ right: 8 })
              .animation({
                duration: 300,
                curve: Curve.EaseInOut
              })
          })
        }
        .justifyContent(FlexAlign.Center)
        .margin({ bottom: 50 })
      }
      .width('100%')
      .height('100%')
    }
    .width('100%')
    .height('100%')
  }

  private navigateToMain() {
    console.log('导航到主页面')
    // 这里应该使用路由导航到主页面
  }
} 