package {
	import Shared.AS3.BSScrollingListEntry;
	import Shared.AS3.BSScrollingList;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.filters.DropShadowFilter;
	import scaleform.gfx.*;
	import Shared.GlobalFunc;

	public class ExtraInfoListEntry extends BSScrollingListEntry {
		public var keyField:TextField;

		public var valueField:TextField;

		public function ExtraInfoListEntry() {
			super();
		}

		override public function SetEntryText(param1:Object, param2:String):* {
			var _loc4_:String = null;
			var _loc5_:String = null;
			if (param1 != null /*&& param1.hasOwnProperty("text")*/) {
				if (param2 == BSScrollingList.TEXT_OPTION_SHRINK_TO_FIT) {
					TextFieldEx.setTextAutoSize(textField, "shrink");
					TextFieldEx.setTextAutoSize(keyField, "shrink");
				} else if (param2 == BSScrollingList.TEXT_OPTION_MULTILINE) {
					textField.autoSize = TextFieldAutoSize.RIGHT;
					textField.multiline = false;
					textField.wordWrap = false;
					keyField.autoSize = textField.autoSize;
					keyField.multiline = textField.multiline;
					keyField.wordWrap = textField.wordWrap;
				}

				if (param1.hasOwnProperty("text") && param1.text != undefined) {
					GlobalFunc.SetText(this.textField, param1.text, true);
				} else {
					GlobalFunc.SetText(this.textField, " ", true);
				}

				if (param1.hasOwnProperty("key") && param1.key != undefined) {
					GlobalFunc.SetText(this.keyField, param1.key, true);
				} else {
					GlobalFunc.SetText(this.keyField, " ", true);
				}

				if (param1.hasOwnProperty("value") && param1.value != undefined) {
					GlobalFunc.SetText(this.valueField, param1.value, true);
				} else {
					GlobalFunc.SetText(this.valueField, " ", true);
				}
				var textColor:uint = !!selected ? 0x000000 : 0xFFFFFF;

				this.textField.textColor = textColor;
				this.keyField.textColor = textColor;
				this.valueField.textColor = textColor;

				var dropShadowFilter:DropShadowFilter = this.keyField.filters[0] as DropShadowFilter;
				dropShadowFilter.color = !!selected ? 0xFFFFFF : 0x000000;

				this.textField.filters = [dropShadowFilter];
				this.keyField.filters = [dropShadowFilter];
				this.valueField.filters = [dropShadowFilter];
			}
			var _loc3_:Number = NaN;
			if (this.border != null) {
				border.alpha = !!this.selected ? Number(Number(GlobalFunc.SELECTED_RECT_ALPHA)) : Number(Number(0));
				if (param2 == BSScrollingList.TEXT_OPTION_MULTILINE && textField.numLines > 1) {
					_loc3_ = this.textField.y - this.border.y;
					border.height = this.textField.textHeight + _loc3_ * 2 + 5;
				} else {
					this.border.height = this.ORIG_BORDER_HEIGHT;
				}
			}
			if (!param1.selected) {
				textField.alpha = param1.filterFlag == 2 ? Number(1) : Number(0.5);
			} else {
				textField.alpha = 1;
			}
			this.keyField.alpha = textField.alpha;
			this.valueField.alpha = textField.alpha;
		}
	}
}
