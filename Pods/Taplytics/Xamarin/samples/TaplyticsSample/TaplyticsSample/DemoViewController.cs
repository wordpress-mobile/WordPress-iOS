using System;
using System.Drawing;
using MonoTouch.Foundation;
using MonoTouch.UIKit;

namespace TaplyticsSample
{
	public class DemoViewController : UIViewController
	{
		UIButton btnTaplytics;
		UITextField txtField;

		public DemoViewController () : base ()
		{
		}

		public DemoViewController (IntPtr handle) : base (handle)
		{			
		}

		public override void ViewDidLoad ()
		{
			base.ViewDidLoad ();

			View.BackgroundColor = UIColor.White;

			btnTaplytics = UIButton.FromType (UIButtonType.RoundedRect);
			btnTaplytics.Frame = new RectangleF (61, 171, 199, 30);
			btnTaplytics.SetTitle ("Change me on Taplytics.com", UIControlState.Normal);

			View.AddSubview (btnTaplytics);

			txtField = new UITextField (new RectangleF (20, 209, 280, 30));
			txtField.BorderStyle = UITextBorderStyle.RoundedRect;

			View.AddSubview (txtField);
		}
	}
}

