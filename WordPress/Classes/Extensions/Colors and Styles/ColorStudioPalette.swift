import Foundation

enum ColorStudioShade: UInt8 {
    case shade0 = 0
    case shade5 = 5
    case shade10 = 10
    case shade20 = 20
    case shade30 = 30
    case shade40 = 40
    case shade50 = 50
    case shade60 = 60
    case shade70 = 70
    case shade80 = 80
    case shade90 = 90
    case shade100 = 100
}

protocol ColorStudioPalette {
    static var colorTable: [ColorStudioShade: UIColor] { get }
    static var base: UIColor { get }
}

extension ColorStudioPalette {
    static func shade(_ shade: ColorStudioShade) -> UIColor {
        colorTable[shade]!
    }
}

struct CSColor {

    struct White {
        static let base = UIColor(red: 255, green: 255, blue: 255, alpha: 1)
    }

    struct Black {
        static let base = UIColor(red: 0, green: 0, blue: 0, alpha: 1)
    }

    struct Gray: ColorStudioPalette {
      static let colorTable: [ColorStudioShade: UIColor] = [
        .shade0: UIColor(red: 0.9647058823529412, green: 0.9686274509803922, blue: 0.9686274509803922, alpha: 1),
        .shade5: UIColor(red: 0.8627450980392157, green: 0.8627450980392157, blue: 0.8705882352941177, alpha: 1),
        .shade10: UIColor(red: 0.7647058823529411, green: 0.7686274509803922, blue: 0.7803921568627451, alpha: 1),
        .shade20: UIColor(red: 0.6549019607843137, green: 0.6666666666666666, blue: 0.6784313725490196, alpha: 1),
        .shade30: UIColor(red: 0.5490196078431373, green: 0.5607843137254902, blue: 0.5803921568627451, alpha: 1),
        .shade40: UIColor(red: 0.47058823529411764, green: 0.48627450980392156, blue: 0.5098039215686274, alpha: 1),
        .shade50: UIColor(red: 0.39215686274509803, green: 0.4117647058823529, blue: 0.4392156862745098, alpha: 1),
        .shade60: UIColor(red: 0.3137254901960784, green: 0.3411764705882353, blue: 0.3686274509803922, alpha: 1),
        .shade70: UIColor(red: 0.23529411764705882, green: 0.2627450980392157, blue: 0.2901960784313726, alpha: 1),
        .shade80: UIColor(red: 0.17254901960784313, green: 0.2, blue: 0.2196078431372549, alpha: 1),
        .shade90: UIColor(red: 0.11372549019607843, green: 0.13725490196078433, blue: 0.15294117647058825, alpha: 1),
        .shade100: UIColor(red: 0.06274509803921569, green: 0.08235294117647059, blue: 0.09019607843137255, alpha: 1),
      ]
      static let base = UIColor(red: 0.39215686274509803, green: 0.4117647058823529, blue: 0.4392156862745098, alpha: 1)
  }

    struct Blue: ColorStudioPalette {
      static let colorTable: [ColorStudioShade: UIColor] = [
        .shade0: UIColor(red: 0.9137254901960784, green: 0.9411764705882353, blue: 0.9607843137254902, alpha: 1),
        .shade5: UIColor(red: 0.7333333333333333, green: 0.8784313725490196, blue: 0.9803921568627451, alpha: 1),
        .shade10: UIColor(red: 0.5686274509803921, green: 0.792156862745098, blue: 0.9490196078431372, alpha: 1),
        .shade20: UIColor(red: 0.40784313725490196, green: 0.7019607843137254, blue: 0.9098039215686274, alpha: 1),
        .shade30: UIColor(red: 0.2235294117647059, green: 0.611764705882353, blue: 0.8901960784313725, alpha: 1),
        .shade40: UIColor(red: 0.08627450980392157, green: 0.5372549019607843, blue: 0.8588235294117647, alpha: 1),
        .shade50: UIColor(red: 0.023529411764705882, green: 0.4588235294117647, blue: 0.7686274509803922, alpha: 1),
        .shade60: UIColor(red: 0.0196078431372549, green: 0.36470588235294116, blue: 0.611764705882353, alpha: 1),
        .shade70: UIColor(red: 0.01568627450980392, green: 0.29411764705882354, blue: 0.47843137254901963, alpha: 1),
        .shade80: UIColor(red: 0.00784313725490196, green: 0.2235294117647059, blue: 0.3607843137254902, alpha: 1),
        .shade90: UIColor(red: 0.00392156862745098, green: 0.1568627450980392, blue: 0.23921568627450981, alpha: 1),
        .shade100: UIColor(red: 0, green: 0.08627450980392157, blue: 0.12941176470588237, alpha: 1),
      ]
      static let base = UIColor(red: 0.023529411764705882, green: 0.4588235294117647, blue: 0.7686274509803922, alpha: 1)
  }

    struct Purple: ColorStudioPalette {
      static let colorTable: [ColorStudioShade: UIColor] = [
        .shade0: UIColor(red: 0.9490196078431372, green: 0.9137254901960784, blue: 0.9294117647058824, alpha: 1),
        .shade5: UIColor(red: 0.9215686274509803, green: 0.807843137254902, blue: 0.8784313725490196, alpha: 1),
        .shade10: UIColor(red: 0.8901960784313725, green: 0.6862745098039216, blue: 0.8352941176470589, alpha: 1),
        .shade20: UIColor(red: 0.8313725490196079, green: 0.5607843137254902, blue: 0.7843137254901961, alpha: 1),
        .shade30: UIColor(red: 0.7686274509803922, green: 0.4588235294117647, blue: 0.7411764705882353, alpha: 1),
        .shade40: UIColor(red: 0.7019607843137254, green: 0.3686274509803922, blue: 0.6941176470588235, alpha: 1),
        .shade50: UIColor(red: 0.596078431372549, green: 0.2901960784313726, blue: 0.611764705882353, alpha: 1),
        .shade60: UIColor(red: 0.48627450980392156, green: 0.2235294117647059, blue: 0.5098039215686274, alpha: 1),
        .shade70: UIColor(red: 0.4, green: 0.17254901960784313, blue: 0.43137254901960786, alpha: 1),
        .shade80: UIColor(red: 0.30196078431372547, green: 0.12549019607843137, blue: 0.32941176470588235, alpha: 1),
        .shade90: UIColor(red: 0.20784313725490197, green: 0.08627450980392157, blue: 0.23137254901960785, alpha: 1),
        .shade100: UIColor(red: 0.11764705882352941, green: 0.047058823529411764, blue: 0.12941176470588237, alpha: 1),
      ]
      static let base = UIColor(red: 0.596078431372549, green: 0.2901960784313726, blue: 0.611764705882353, alpha: 1)
  }

    struct Pink: ColorStudioPalette {
      static let colorTable: [ColorStudioShade: UIColor] = [
        .shade0: UIColor(red: 0.9607843137254902, green: 0.9137254901960784, blue: 0.9294117647058824, alpha: 1),
        .shade5: UIColor(red: 0.9490196078431372, green: 0.807843137254902, blue: 0.8549019607843137, alpha: 1),
        .shade10: UIColor(red: 0.9686274509803922, green: 0.6588235294117647, blue: 0.7647058823529411, alpha: 1),
        .shade20: UIColor(red: 0.9490196078431372, green: 0.5137254901960784, blue: 0.6666666666666666, alpha: 1),
        .shade30: UIColor(red: 0.9215686274509803, green: 0.396078431372549, blue: 0.5803921568627451, alpha: 1),
        .shade40: UIColor(red: 0.8901960784313725, green: 0.2980392156862745, blue: 0.5176470588235295, alpha: 1),
        .shade50: UIColor(red: 0.788235294117647, green: 0.20784313725490197, blue: 0.43137254901960786, alpha: 1),
        .shade60: UIColor(red: 0.6705882352941176, green: 0.13725490196078433, blue: 0.35294117647058826, alpha: 1),
        .shade70: UIColor(red: 0.5490196078431373, green: 0.09019607843137255, blue: 0.28627450980392155, alpha: 1),
        .shade80: UIColor(red: 0.4392156862745098, green: 0.058823529411764705, blue: 0.23137254901960785, alpha: 1),
        .shade90: UIColor(red: 0.30980392156862746, green: 0.03529411764705882, blue: 0.16470588235294117, alpha: 1),
        .shade100: UIColor(red: 0.14901960784313725, green: 0.01568627450980392, blue: 0.08235294117647059, alpha: 1),
      ]
      static let base = UIColor(red: 0.788235294117647, green: 0.20784313725490197, blue: 0.43137254901960786, alpha: 1)
  }

    struct Red: ColorStudioPalette {
      static let colorTable: [ColorStudioShade: UIColor] = [
        .shade0: UIColor(red: 0.9686274509803922, green: 0.9215686274509803, blue: 0.9254901960784314, alpha: 1),
        .shade5: UIColor(red: 0.9803921568627451, green: 0.8117647058823529, blue: 0.8235294117647058, alpha: 1),
        .shade10: UIColor(red: 1, green: 0.6705882352941176, blue: 0.6862745098039216, alpha: 1),
        .shade20: UIColor(red: 1, green: 0.5019607843137255, blue: 0.5215686274509804, alpha: 1),
        .shade30: UIColor(red: 0.9725490196078431, green: 0.38823529411764707, blue: 0.40784313725490196, alpha: 1),
        .shade40: UIColor(red: 0.9019607843137255, green: 0.3137254901960784, blue: 0.32941176470588235, alpha: 1),
        .shade50: UIColor(red: 0.8392156862745098, green: 0.21176470588235294, blue: 0.2196078431372549, alpha: 1),
        .shade60: UIColor(red: 0.7019607843137254, green: 0.17647058823529413, blue: 0.1803921568627451, alpha: 1),
        .shade70: UIColor(red: 0.5411764705882353, green: 0.1411764705882353, blue: 0.1411764705882353, alpha: 1),
        .shade80: UIColor(red: 0.4117647058823529, green: 0.10980392156862745, blue: 0.10980392156862745, alpha: 1),
        .shade90: UIColor(red: 0.27058823529411763, green: 0.07450980392156863, blue: 0.07450980392156863, alpha: 1),
        .shade100: UIColor(red: 0.1411764705882353, green: 0.0392156862745098, blue: 0.0392156862745098, alpha: 1),
      ]
      static let base = UIColor(red: 0.8392156862745098, green: 0.21176470588235294, blue: 0.2196078431372549, alpha: 1)
  }

    struct Orange: ColorStudioPalette {
      static let colorTable: [ColorStudioShade: UIColor] = [
        .shade0: UIColor(red: 0.9607843137254902, green: 0.9254901960784314, blue: 0.9019607843137255, alpha: 1),
        .shade5: UIColor(red: 0.9686274509803922, green: 0.8627450980392157, blue: 0.7764705882352941, alpha: 1),
        .shade10: UIColor(red: 1, green: 0.7490196078431373, blue: 0.5254901960784314, alpha: 1),
        .shade20: UIColor(red: 0.9803921568627451, green: 0.6549019607843137, blue: 0.32941176470588235, alpha: 1),
        .shade30: UIColor(red: 0.9019607843137255, green: 0.5450980392156862, blue: 0.1568627450980392, alpha: 1),
        .shade40: UIColor(red: 0.8392156862745098, green: 0.4666666666666667, blue: 0.03529411764705882, alpha: 1),
        .shade50: UIColor(red: 0.6980392156862745, green: 0.3843137254901961, blue: 0, alpha: 1),
        .shade60: UIColor(red: 0.5411764705882353, green: 0.30196078431372547, blue: 0, alpha: 1),
        .shade70: UIColor(red: 0.4392156862745098, green: 0.25098039215686274, blue: 0, alpha: 1),
        .shade80: UIColor(red: 0.32941176470588235, green: 0.19215686274509805, blue: 0, alpha: 1),
        .shade90: UIColor(red: 0.21176470588235294, green: 0.12156862745098039, blue: 0, alpha: 1),
        .shade100: UIColor(red: 0.12156862745098039, green: 0.07058823529411765, blue: 0, alpha: 1),
      ]
      static let base = UIColor(red: 0.6980392156862745, green: 0.3843137254901961, blue: 0, alpha: 1)
  }

    struct Yellow: ColorStudioPalette {
      static let colorTable: [ColorStudioShade: UIColor] = [
        .shade0: UIColor(red: 0.9607843137254902, green: 0.9450980392156862, blue: 0.8823529411764706, alpha: 1),
        .shade5: UIColor(red: 0.9607843137254902, green: 0.9019607843137255, blue: 0.7019607843137254, alpha: 1),
        .shade10: UIColor(red: 0.9490196078431372, green: 0.8431372549019608, blue: 0.4196078431372549, alpha: 1),
        .shade20: UIColor(red: 0.9411764705882353, green: 0.788235294117647, blue: 0.18823529411764706, alpha: 1),
        .shade30: UIColor(red: 0.8705882352941177, green: 0.6941176470588235, blue: 0, alpha: 1),
        .shade40: UIColor(red: 0.7529411764705882, green: 0.5490196078431373, blue: 0, alpha: 1),
        .shade50: UIColor(red: 0.615686274509804, green: 0.43137254901960786, blue: 0, alpha: 1),
        .shade60: UIColor(red: 0.49019607843137253, green: 0.33725490196078434, blue: 0, alpha: 1),
        .shade70: UIColor(red: 0.403921568627451, green: 0.27450980392156865, blue: 0, alpha: 1),
        .shade80: UIColor(red: 0.30980392156862746, green: 0.20784313725490197, blue: 0, alpha: 1),
        .shade90: UIColor(red: 0.2, green: 0.13333333333333333, blue: 0, alpha: 1),
        .shade100: UIColor(red: 0.10980392156862745, green: 0.07450980392156863, blue: 0, alpha: 1),
      ]
      static let base = UIColor(red: 0.615686274509804, green: 0.43137254901960786, blue: 0, alpha: 1)
  }

    struct Green: ColorStudioPalette {
      static let colorTable: [ColorStudioShade: UIColor] = [
        .shade0: UIColor(red: 0.9019607843137255, green: 0.9490196078431372, blue: 0.9098039215686274, alpha: 1),
        .shade5: UIColor(red: 0.7215686274509804, green: 0.9019607843137255, blue: 0.7490196078431373, alpha: 1),
        .shade10: UIColor(red: 0.40784313725490196, green: 0.8705882352941177, blue: 0.5254901960784314, alpha: 1),
        .shade20: UIColor(red: 0.11764705882352941, green: 0.8196078431372549, blue: 0.35294117647058826, alpha: 1),
        .shade30: UIColor(red: 0, green: 0.7294117647058823, blue: 0.21568627450980393, alpha: 1),
        .shade40: UIColor(red: 0, green: 0.6392156862745098, blue: 0.16470588235294117, alpha: 1),
        .shade50: UIColor(red: 0, green: 0.5411764705882353, blue: 0.12549019607843137, alpha: 1),
        .shade60: UIColor(red: 0, green: 0.4392156862745098, blue: 0.09019607843137255, alpha: 1),
        .shade70: UIColor(red: 0, green: 0.3607843137254902, blue: 0.07058823529411765, alpha: 1),
        .shade80: UIColor(red: 0, green: 0.27058823529411763, blue: 0.047058823529411764, alpha: 1),
        .shade90: UIColor(red: 0, green: 0.18823529411764706, blue: 0.03137254901960784, alpha: 1),
        .shade100: UIColor(red: 0, green: 0.10980392156862745, blue: 0.0196078431372549, alpha: 1),
      ]
      static let base = UIColor(red: 0, green: 0.5411764705882353, blue: 0.12549019607843137, alpha: 1)
  }

    struct Celadon: ColorStudioPalette {
      static let colorTable: [ColorStudioShade: UIColor] = [
        .shade0: UIColor(red: 0.8941176470588236, green: 0.9490196078431372, blue: 0.9294117647058824, alpha: 1),
        .shade5: UIColor(red: 0.6549019607843137, green: 0.9098039215686274, blue: 0.8274509803921568, alpha: 1),
        .shade10: UIColor(red: 0.4, green: 0.8705882352941177, blue: 0.7254901960784313, alpha: 1),
        .shade20: UIColor(red: 0.19215686274509805, green: 0.8, blue: 0.6235294117647059, alpha: 1),
        .shade30: UIColor(red: 0.03529411764705882, green: 0.7098039215686275, blue: 0.5215686274509804, alpha: 1),
        .shade40: UIColor(red: 0, green: 0.6196078431372549, blue: 0.45098039215686275, alpha: 1),
        .shade50: UIColor(red: 0, green: 0.5294117647058824, blue: 0.38823529411764707, alpha: 1),
        .shade60: UIColor(red: 0, green: 0.4392156862745098, blue: 0.3254901960784314, alpha: 1),
        .shade70: UIColor(red: 0, green: 0.3607843137254902, blue: 0.26666666666666666, alpha: 1),
        .shade80: UIColor(red: 0, green: 0.27058823529411763, blue: 0.2, alpha: 1),
        .shade90: UIColor(red: 0, green: 0.18823529411764706, blue: 0.1411764705882353, alpha: 1),
        .shade100: UIColor(red: 0, green: 0.10980392156862745, blue: 0.08235294117647059, alpha: 1),
      ]
      static let base = UIColor(red: 0, green: 0.5294117647058824, blue: 0.38823529411764707, alpha: 1)
  }

    struct AutomatticBlue: ColorStudioPalette {
      static let colorTable: [ColorStudioShade: UIColor] = [
        .shade0: UIColor(red: 0.9215686274509803, green: 0.9568627450980393, blue: 0.9803921568627451, alpha: 1),
        .shade5: UIColor(red: 0.7686274509803922, green: 0.8862745098039215, blue: 0.9607843137254902, alpha: 1),
        .shade10: UIColor(red: 0.5333333333333333, green: 0.8, blue: 0.9490196078431372, alpha: 1),
        .shade20: UIColor(red: 0.35294117647058826, green: 0.7176470588235294, blue: 0.9098039215686274, alpha: 1),
        .shade30: UIColor(red: 0.1411764705882353, green: 0.6392156862745098, blue: 0.8784313725490196, alpha: 1),
        .shade40: UIColor(red: 0.0784313725490196, green: 0.5647058823529412, blue: 0.7803921568627451, alpha: 1),
        .shade50: UIColor(red: 0.00784313725490196, green: 0.4666666666666667, blue: 0.6588235294117647, alpha: 1),
        .shade60: UIColor(red: 0.011764705882352941, green: 0.3764705882352941, blue: 0.5215686274509804, alpha: 1),
        .shade70: UIColor(red: 0.00784313725490196, green: 0.3137254901960784, blue: 0.43137254901960786, alpha: 1),
        .shade80: UIColor(red: 0.00784313725490196, green: 0.2196078431372549, blue: 0.30196078431372547, alpha: 1),
        .shade90: UIColor(red: 0.00784313725490196, green: 0.1568627450980392, blue: 0.21176470588235294, alpha: 1),
        .shade100: UIColor(red: 0.00784313725490196, green: 0.10588235294117647, blue: 0.1411764705882353, alpha: 1),
      ]
      static let base = UIColor(red: 0.1411764705882353, green: 0.6392156862745098, blue: 0.8784313725490196, alpha: 1)
  }

    struct WordPressBlue: ColorStudioPalette {
      static let colorTable: [ColorStudioShade: UIColor] = [
        .shade0: UIColor(red: 0.984313725490196, green: 0.9882352941176471, blue: 0.996078431372549, alpha: 1),
        .shade5: UIColor(red: 0.9686274509803922, green: 0.9725490196078431, blue: 0.996078431372549, alpha: 1),
        .shade10: UIColor(red: 0.8392156862745098, green: 0.8666666666666667, blue: 0.9764705882352941, alpha: 1),
        .shade20: UIColor(red: 0.6784313725490196, green: 0.7294117647058823, blue: 0.9529411764705882, alpha: 1),
        .shade30: UIColor(red: 0.4823529411764706, green: 0.5647058823529412, blue: 1, alpha: 1),
        .shade40: UIColor(red: 0.32941176470588235, green: 0.43529411764705883, blue: 0.9529411764705882, alpha: 1),
        .shade50: UIColor(red: 0.2196078431372549, green: 0.34509803921568627, blue: 0.9137254901960784, alpha: 1),
        .shade60: UIColor(red: 0.16470588235294117, green: 0.27450980392156865, blue: 0.807843137254902, alpha: 1),
        .shade70: UIColor(red: 0.11372549019607843, green: 0.20784313725490197, blue: 0.7058823529411765, alpha: 1),
        .shade80: UIColor(red: 0.12156862745098039, green: 0.19607843137254902, blue: 0.5254901960784314, alpha: 1),
        .shade90: UIColor(red: 0.0784313725490196, green: 0.12941176470588237, blue: 0.35294117647058826, alpha: 1),
        .shade100: UIColor(red: 0.0392156862745098, green: 0.06666666666666667, blue: 0.17647058823529413, alpha: 1),
      ]
      static let base = UIColor(red: 0.2196078431372549, green: 0.34509803921568627, blue: 0.9137254901960784, alpha: 1)
  }

    struct SimplenoteBlue: ColorStudioPalette {
      static let colorTable: [ColorStudioShade: UIColor] = [
        .shade0: UIColor(red: 0.9137254901960784, green: 0.9254901960784314, blue: 0.9607843137254902, alpha: 1),
        .shade5: UIColor(red: 0.807843137254902, green: 0.8509803921568627, blue: 0.9490196078431372, alpha: 1),
        .shade10: UIColor(red: 0.6705882352941176, green: 0.7568627450980392, blue: 0.9607843137254902, alpha: 1),
        .shade20: UIColor(red: 0.5176470588235295, green: 0.6431372549019608, blue: 0.9411764705882353, alpha: 1),
        .shade30: UIColor(red: 0.3803921568627451, green: 0.5529411764705883, blue: 0.9490196078431372, alpha: 1),
        .shade40: UIColor(red: 0.27450980392156865, green: 0.47058823529411764, blue: 0.9215686274509803, alpha: 1),
        .shade50: UIColor(red: 0.2, green: 0.3803921568627451, blue: 0.8, alpha: 1),
        .shade60: UIColor(red: 0.11372549019607843, green: 0.30980392156862746, blue: 0.7686274509803922, alpha: 1),
        .shade70: UIColor(red: 0.06666666666666667, green: 0.24313725490196078, blue: 0.6784313725490196, alpha: 1),
        .shade80: UIColor(red: 0.050980392156862744, green: 0.1843137254901961, blue: 0.5215686274509804, alpha: 1),
        .shade90: UIColor(red: 0.03529411764705882, green: 0.12549019607843137, blue: 0.3607843137254902, alpha: 1),
        .shade100: UIColor(red: 0.0196078431372549, green: 0.06274509803921569, blue: 0.1803921568627451, alpha: 1),
      ]
      static let base = UIColor(red: 0.2, green: 0.3803921568627451, blue: 0.8, alpha: 1)
  }

    struct WooCommercePurple: ColorStudioPalette {
      static let colorTable: [ColorStudioShade: UIColor] = [
        .shade0: UIColor(red: 0.9686274509803922, green: 0.9294117647058824, blue: 0.9686274509803922, alpha: 1),
        .shade5: UIColor(red: 0.8980392156862745, green: 0.8117647058823529, blue: 0.9098039215686274, alpha: 1),
        .shade10: UIColor(red: 0.8392156862745098, green: 0.7058823529411765, blue: 0.8784313725490196, alpha: 1),
        .shade20: UIColor(red: 0.7803921568627451, green: 0.5725490196078431, blue: 0.8784313725490196, alpha: 1),
        .shade30: UIColor(red: 0.6862745098039216, green: 0.49019607843137253, blue: 0.8196078431372549, alpha: 1),
        .shade40: UIColor(red: 0.6039215686274509, green: 0.4117647058823529, blue: 0.7803921568627451, alpha: 1),
        .shade50: UIColor(red: 0.4980392156862745, green: 0.32941176470588235, blue: 0.7019607843137254, alpha: 1),
        .shade60: UIColor(red: 0.403921568627451, green: 0.2627450980392157, blue: 0.6, alpha: 1),
        .shade70: UIColor(red: 0.3254901960784314, green: 0.20784313725490197, blue: 0.5098039215686274, alpha: 1),
        .shade80: UIColor(red: 0.23529411764705882, green: 0.1568627450980392, blue: 0.3803921568627451, alpha: 1),
        .shade90: UIColor(red: 0.15294117647058825, green: 0.10588235294117647, blue: 0.23921568627450981, alpha: 1),
        .shade100: UIColor(red: 0.0784313725490196, green: 0.054901960784313725, blue: 0.12156862745098039, alpha: 1),
      ]
      static let base = UIColor(red: 0.4980392156862745, green: 0.32941176470588235, blue: 0.7019607843137254, alpha: 1)
  }

    struct JetpackGreen: ColorStudioPalette {
      static let colorTable: [ColorStudioShade: UIColor] = [
        .shade0: UIColor(red: 0.9411764705882353, green: 0.9490196078431372, blue: 0.9215686274509803, alpha: 1),
        .shade5: UIColor(red: 0.8156862745098039, green: 0.9019607843137255, blue: 0.7215686274509804, alpha: 1),
        .shade10: UIColor(red: 0.615686274509804, green: 0.8509803921568627, blue: 0.4666666666666667, alpha: 1),
        .shade20: UIColor(red: 0.39215686274509803, green: 0.792156862745098, blue: 0.2627450980392157, alpha: 1),
        .shade30: UIColor(red: 0.1843137254901961, green: 0.7058823529411765, blue: 0.12156862745098039, alpha: 1),
        .shade40: UIColor(red: 0.023529411764705882, green: 0.6196078431372549, blue: 0.03137254901960784, alpha: 1),
        .shade50: UIColor(red: 0, green: 0.5294117647058824, blue: 0.06274509803921569, alpha: 1),
        .shade60: UIColor(red: 0, green: 0.44313725490196076, blue: 0.09019607843137255, alpha: 1),
        .shade70: UIColor(red: 0, green: 0.3568627450980392, blue: 0.09411764705882353, alpha: 1),
        .shade80: UIColor(red: 0, green: 0.27058823529411763, blue: 0.08235294117647059, alpha: 1),
        .shade90: UIColor(red: 0, green: 0.18823529411764706, blue: 0.06274509803921569, alpha: 1),
        .shade100: UIColor(red: 0, green: 0.10980392156862745, blue: 0.03529411764705882, alpha: 1),
      ]
      static let base = UIColor(red: 0.023529411764705882, green: 0.6196078431372549, blue: 0.03137254901960784, alpha: 1)
  }
}
