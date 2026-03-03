// Native code order of calls:
// [Console] set size 30
// [Console] set textColor 16777215
// [Console] set textSize 16
// [Console] set historyTextColor 10066329
// [Console] Show
// -- OnMenuOpenClose happens around here
// [Console] SetCommandPrompt `--- `

package {
	import Shared.AS3.BSScrollingList;
	import Shared.IMenu;
	import flash.display.MovieClip;
	// import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.geom.Point;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.ui.Keyboard;
	import scaleform.gfx.Extensions;
	import scaleform.gfx.TextFieldEx;

	import fex.StupidINI;

	public class Console extends IMenu {
		public var BGSCodeObj:Object;
		public var Background:MovieClip;
		public var CommandEntry:TextField;
		public var CommandHistory:TextField;
		public var CurrentSelection:TextField;
		public var CommandPrompt_tf:TextField;

		private var PREVIOUS_COMMANDS:uint = 128;
		private var HistoryCharBufferSize:uint = 8192;
		private var Commands:Array;
		private var PreviousCommandOffset:int;
		private var CurrentSelectionYOffset:Number;
		private var OriginalWidth:Number;
		private var OriginalHeight:Number;
		private var Shown:Boolean;
		private var Animating:Boolean;
		private var Hiding:Boolean;

		// better console
		public var FirstExtraInfoPanel_mc:MovieClip;
		public var SecondExtraInfoPanel_mc:MovieClip;
		public var ThirdExtraInfoPanel_mc:MovieClip;
		public var InfoBox_tf:TextField;

		public static var showExtraInfoWindow:Boolean = false;

		// console history
		public var ConsoleHistoryObj:Object;
		public var CommandPromptEx_tf:TextField;
		private var togglePanelsKey:uint = Keyboard.F1;
		private var settings:StupidINI;

		private var defaultSettings:Object;

		public function Console() {
			trace("[Console:Constructor] created");
			Commands = new Array();
			super();
			BGSCodeObj = new Object();
			ConsoleHistoryObj = new Object();
			defaultSettings = new Object();

			Extensions.enabled = true;

			FirstExtraInfoPanel_mc.visible = SecondExtraInfoPanel_mc.visible = ThirdExtraInfoPanel_mc.visible = false;

			CurrentSelectionYOffset = Background.height + CurrentSelection.y;

			// this is always 1280x720 now
			OriginalHeight = stage.stageHeight;
			OriginalWidth = stage.stageWidth;

			PreviousCommandOffset = 0;
			Shown = false;
			Animating = false;
			Hiding = false;

			CommandEntry.defaultTextFormat = CommandEntry.getTextFormat();
			CommandEntry.text = "";
			TextFieldEx.setNoTranslate(CommandEntry, true);

			CurrentSelection.defaultTextFormat = CurrentSelection.getTextFormat();
			CurrentSelection.text = "";
			TextFieldEx.setNoTranslate(CurrentSelection, true);

			CommandHistory.defaultTextFormat = CommandHistory.getTextFormat();
			CommandHistory.text = "";
			TextFieldEx.setNoTranslate(CommandHistory, true);

			InfoBox_tf.defaultTextFormat = InfoBox_tf.getTextFormat();
			InfoBox_tf.text = "";
			TextFieldEx.setNoTranslate(InfoBox_tf, true);

			// stage.align = StageAlign.BOTTOM_LEFT; // ????????????????????????????????????????
			addEventListener(KeyboardEvent.KEY_UP, onKeyUp);
			addEventListener(Shared.AS3.BSScrollingList.SELECTION_CHANGE, onExtraInfoListSelectionChange);

			FirstExtraInfoPanel_mc.List_mc.ID = 1;
			SecondExtraInfoPanel_mc.List_mc.ID = 2;
			ThirdExtraInfoPanel_mc.List_mc.ID = 3;

			root.addEventListener("OnConsoleOpen", OnConsoleOpen);

			defaultSettings.Main = {
					Prompt: "$\>",
					TogglePanelsKey: "F1"
				};

			defaultSettings.Style = {
					ScreenPercent: "40",
					FontSize: "10",
					TitleFontSize: "12",
					InfoBoxFontSize: "12",
					FontColor: "#F3F3F3",
					SelectionColor: "#121212FF",
					SelectionBackgroundColor: "#F3F3F3FF",
					PromptFontColor: "#999999",
					HistoryFontColor: "#999999",
					InfoBoxFontColor: "#999999",
					TitleFontColor: "#F3F3F3"
				};

			settings = new StupidINI("ConsoleHistory", defaultSettings);
			settings.Load(Initialize);

			trace("[Console:Constructor] complete");
		}

		// public function onF4SEObjCreated(codeObject:Object):void
		// {
		// trace("[Console] onF4SEObjCreated");
		// }

		private function ColorToHex(color:uint):String {
			var hex:String = color.toString(16).toUpperCase();
			return "#" + hex;
		}

		private function Initialize():void {
			trace("[Console:INI] Settings:" + settings.Dump());

			var iniTogglePanelsKey:String = settings.GetString("Main", "TogglePanelsKey");
			if (iniTogglePanelsKey && Keyboard[iniTogglePanelsKey] is uint) {
				togglePanelsKey = Keyboard[iniTogglePanelsKey];
				trace("[Console:INI] TogglePanelsKey set to " + togglePanelsKey);
			}

			Redraw();
		}

		private function SetTextFormat(textField:TextField, size:Number, color:uint):void {
			var tf:TextFormat = textField.defaultTextFormat;
			tf.size = size;
			textField.setTextFormat(tf);
			textField.defaultTextFormat = tf;
			textField.textColor = color;
		}

		private function Redraw():void {
			var screenPercent:Number = settings.GetNumber("Style", "ScreenPercent");
			Background.height = OriginalHeight * (screenPercent / 100);

			var fontSize:Number = settings.GetNumber("Style", "FontSize");
			var titleFontSize:Number = settings.GetNumber("Style", "TitleFontSize");
			var infoBoxFontSize:Number = settings.GetNumber("Style", "InfoBoxFontSize");

			var fontColor:uint = settings.GetColor("Style", "FontColor");
			var titleFontColor:uint = settings.GetColor("Style", "TitleFontColor");
			var historyFontColor:uint = settings.GetColor("Style", "TitleFontColor");
			var selectionColor:uint = settings.GetColor("Style", "SelectionColor");
			var selectionBackgroundColor:uint = settings.GetColor("Style", "SelectionBackgroundColor");
			var infoBoxFontColor:uint = settings.GetColor("Style", "InfoBoxFontColor");

			CurrentSelection.y = CurrentSelectionYOffset - Background.height;
			CommandHistory.y = CurrentSelection.y + CurrentSelection.height;

			CommandHistory.height = CommandEntry.y - CommandHistory.y;

			// InfoBox

			SetTextFormat(InfoBox_tf, infoBoxFontSize, infoBoxFontColor);
			// InfoBox_tf.background = true;
			// InfoBox_tf.backgroundColor = 0xFF0000;

			var infoMaxTop:Number = -Background.height + 25;
			var infoMaxBottom:Number = -20;
			var infoMaxHeight:Number = infoMaxBottom - infoMaxTop;

			var infoTextHeight:Number = InfoBox_tf.textHeight + 5;

			trace("[Console:Redraw] infoTextHeight=" + infoTextHeight + " infoMaxHeight=" + infoMaxHeight + " backgroundHeight=" + Background.height);

			if (infoTextHeight > infoMaxHeight) {
				InfoBox_tf.y = infoMaxTop;
				InfoBox_tf.height = infoMaxHeight;
				TextFieldEx.setTextAutoSize(InfoBox_tf, TextFieldEx.TEXTAUTOSZ_FIT);
			} else {
				InfoBox_tf.height = infoTextHeight;
				InfoBox_tf.y = infoMaxTop + (infoMaxHeight - InfoBox_tf.height) / 2;
			}

			// End InfoBox

			SetTextFormat(CurrentSelection, titleFontSize, titleFontColor);
			SetTextFormat(CommandHistory, fontSize, historyFontColor);

			SetTextFormat(CommandEntry, fontSize, fontColor);
			TextFieldEx.setSelectionTextColor(CommandEntry, selectionColor);
			TextFieldEx.setSelectionBkgColor(CommandEntry, selectionBackgroundColor);

			SetCommandPromptEx(null, null);

			trace("[Console:Redraw] finish");

			// todo: right now those are fixed
			// FirstExtraInfoPanel_mc.y = SecondExtraInfoPanel_mc.y = ThirdExtraInfoPanel_mc.y = 10 - stageHeight;
			// FirstExtraInfoPanel_mc.height = SecondExtraInfoPanel_mc.height = ThirdExtraInfoPanel_mc.height = stageHeight - Background.height - 10;
		}

		private function ShowInfoPanels():void {
			FirstExtraInfoPanel_mc.visible = SecondExtraInfoPanel_mc.visible = ThirdExtraInfoPanel_mc.visible = false;
			FirstExtraInfoPanel_mc.List_mc.entryList = SecondExtraInfoPanel_mc.List_mc.entryList = ThirdExtraInfoPanel_mc.List_mc.entryList = null;
			var r:Object = root;
			// lint stuff
			if (showExtraInfoWindow && r.f4se && r.f4se.plugins && r.f4se.plugins.BetterConsole) {
				var resultArr:Array = r.f4se.plugins.BetterConsole.GetExtraData();
				if (resultArr is Array) {
					FirstExtraInfoPanel_mc.List_mc.selectedIndex = -1;
					FirstExtraInfoPanel_mc.List_mc.entryList = resultArr;
					FirstExtraInfoPanel_mc.visible = true;
				}
			}
			FirstExtraInfoPanel_mc.List_mc.InvalidateData();
			SecondExtraInfoPanel_mc.List_mc.InvalidateData();
			ThirdExtraInfoPanel_mc.List_mc.InvalidateData();
		}

		internal function onExtraInfoListSelectionChange(e:flash.events.Event):* {
			var list:ExtraInfoList = e.target as ExtraInfoList;
			var selectedIndex:* = null;
			var currentEntry:Object = null;
			var arrObj:* = null;

			if (list.ID == 1) {
				selectedIndex = FirstExtraInfoPanel_mc.List_mc.selectedIndex;
				currentEntry = FirstExtraInfoPanel_mc.List_mc.entryList[selectedIndex];
				if (currentEntry != null && currentEntry.hasOwnProperty("extraInfo")) {
					arrObj = currentEntry.extraInfo;
					if (arrObj is Array) {
						SecondExtraInfoPanel_mc.List_mc.entryList = arrObj;
						SecondExtraInfoPanel_mc.List_mc.selectedIndex = -1;
						SecondExtraInfoPanel_mc.List_mc.InvalidateData();
						SecondExtraInfoPanel_mc.visible = true;
					}
				} else {
					ThirdExtraInfoPanel_mc.visible = false;
					ThirdExtraInfoPanel_mc.List_mc.entryList = null;
					ThirdExtraInfoPanel_mc.List_mc.selectedIndex = -1;
					ThirdExtraInfoPanel_mc.List_mc.InvalidateData();
					SecondExtraInfoPanel_mc.visible = false;
					SecondExtraInfoPanel_mc.List_mc.entryList = null;
					SecondExtraInfoPanel_mc.List_mc.selectedIndex = -1;
					SecondExtraInfoPanel_mc.List_mc.InvalidateData();
				}
			} else if (list.ID == 2) {
				selectedIndex = SecondExtraInfoPanel_mc.List_mc.selectedIndex;
				currentEntry = SecondExtraInfoPanel_mc.List_mc.entryList[selectedIndex];
				if (currentEntry != null && currentEntry.hasOwnProperty("extraInfo")) {
					arrObj = currentEntry.extraInfo;
					if (arrObj is Array) {
						ThirdExtraInfoPanel_mc.List_mc.entryList = arrObj;
						ThirdExtraInfoPanel_mc.List_mc.selectedIndex = -1;
						ThirdExtraInfoPanel_mc.List_mc.InvalidateData();
						ThirdExtraInfoPanel_mc.visible = true;
					}
				} else {
					ThirdExtraInfoPanel_mc.visible = false;
					ThirdExtraInfoPanel_mc.List_mc.entryList = null;
					ThirdExtraInfoPanel_mc.List_mc.selectedIndex = -1;
					ThirdExtraInfoPanel_mc.List_mc.InvalidateData();
				}
			}
		}
		// API called by native code.
		public function canScrollMouse():Boolean {
			var point:* = localToGlobal(new flash.geom.Point(mouseX, mouseY));
			if (FirstExtraInfoPanel_mc.visible && FirstExtraInfoPanel_mc.background.hitTestPoint(point.x, point.y, false)) {
				return false;
			}
			if (SecondExtraInfoPanel_mc.visible && SecondExtraInfoPanel_mc.background.hitTestPoint(point.x, point.y, false)) {
				return false;
			}
			if (ThirdExtraInfoPanel_mc.visible && ThirdExtraInfoPanel_mc.background.hitTestPoint(point.x, point.y, false)) {
				return false;
			}
			return true;
		}

		public function OnConsoleOpen(param1:Event):void {
			ShowInfoPanels();
		}

		public function get shown():Boolean {
			return Shown && !Animating;
		}

		public function get hiding():Boolean {
			return Hiding;
		}

		public function set currentSelection(param1:String):* {
			CurrentSelection.text = param1;
			var r:Object = root; // lint stuff
			if (!r.f4se || !r.f4se.plugins || !r.f4se.plugins.BetterConsole) {
				return;
			}
			InfoBox_tf.text = "";

			var resultObj:Object = r.f4se.plugins.BetterConsole.GetBaseData();
			if (resultObj is Object) {
				var infoText:String = "";

				if (resultObj.hasOwnProperty("refName")) {
					infoText += "Name: '" + resultObj.refName + "'";
				} else {
					infoText += "No Name";
				}
				infoText += "\nType: " + resultObj.baseFormType;
				infoText += "\nRef ID: " + resultObj.refFormID;
				infoText += "\nBase ID: " + resultObj.baseFormID;
				infoText += "\nRef defined: " + resultObj.refDefineModName;
				infoText += "\nBase defined: " + resultObj.baseDefineModName;
				if (resultObj.hasOwnProperty("baseLastChangeModName")) {
					infoText += "\nLast Base Change: " + resultObj.baseLastChangeModName;
				}

				InfoBox_tf.text = infoText;
			}
			ShowInfoPanels();
		}

		// fn called from native
		public function set historyCharBufferSize(param1:uint):* {
			trace('[Console:NativeCall] set historyCharBufferSize ' + param1);
			HistoryCharBufferSize = param1;
		}

		// fn called from native, deined
		public function set historyTextColor(param1:uint):* {
			trace('[Console:NativeCall] set historyTextColor ' + param1);
		}

		// fn called from native, deined
		public function set textColor(param1:uint):* {
			trace('[Console:NativeCall] set textColor ' + param1);
		}

		// fn called from native, deined
		public function set textSize(bgsSize:uint):* {
			trace('[Console:NativeCall] set textSize ' + bgsSize);
		}

		// this is the first method the native code calls when showing the console
		public function set size(percent:Number):* {
			trace('[Console:NativeCall] set size ' + percent);
			// hack: native code somehow sets StageScaleMode.NO_SCALE
			// we simply reset it to SHOW_ALL, so it scales with resolution
			// this only happens once
			if (stage.scaleMode != StageScaleMode.SHOW_ALL) {
				stage.scaleMode = StageScaleMode.SHOW_ALL;
			}
		}

		public function Show():* {
			trace('[Console:NativeCall] Show');
			if (!Animating) {
				parent.y = OriginalHeight;

				(parent as MovieClip).gotoAndPlay("show_anim");
				stage.focus = CommandEntry;
				Animating = true;
				CommandEntry.setSelection(0, CommandEntry.length);
			}
		}

		public function ShowComplete():* {
			Shown = true;
			Animating = false;
		}

		public function Hide():* {
			trace('[Console:NativeCall] Hide');
			if (!Animating) {
				(parent as MovieClip).gotoAndPlay("hide_anim");
				stage.focus = null;
				Animating = true;
				Hiding = true;
			}
		}

		public function HideComplete():* {
			trace('[Console] HideComplete');
			Shown = false;
			Animating = false;
			Hiding = false;
			BGSCodeObj.onHideComplete();
		}

		public function Minimize():* {
			parent.y = OriginalHeight - CommandHistory.y;
		}

		public function PreviousCommand():* {
			if (PreviousCommandOffset < Commands.length) {
				PreviousCommandOffset++;
			}
			if (0 != Commands.length && 0 != PreviousCommandOffset) {
				CommandEntry.text = Commands[Commands.length - PreviousCommandOffset];
				CommandEntry.setSelection(CommandEntry.length, CommandEntry.length);
			}
		}

		public function NextCommand():* {
			if (PreviousCommandOffset > 1) {
				PreviousCommandOffset--;
			}
			if (0 != Commands.length && 0 != PreviousCommandOffset) {
				CommandEntry.text = Commands[Commands.length - PreviousCommandOffset];
				CommandEntry.setSelection(CommandEntry.length, CommandEntry.length);
			}
		}

		public function AddHistory(param1:String):* {
			CommandHistory.appendText(param1);
			if (CommandHistory.text.length > HistoryCharBufferSize) {
				CommandHistory.text = CommandHistory.text.substr(-HistoryCharBufferSize);
			}
			CommandHistory.scrollV = CommandHistory.maxScrollV;
		}

		public function SetHistorySize(size:uint):* {
			trace("[Console:SetHistorySize] " + size);
			PREVIOUS_COMMANDS = size;
		}

		public function AddCommandToHistory(param1:String):* {
			if (Commands.length >= PREVIOUS_COMMANDS) {
				Commands.shift();
			}
			Commands.push(param1);
		}

		public function ExecuteCommand(param1:String):* {
			try {
				BGSCodeObj.executeCommand(param1);
			}
			catch (e:Error) {}
			ResetCommandEntry();
		}

		// called from ConsoleHistory
		public function SetCommandPromptEx(user:String, path:String):void {
			if (!user) {
				user = "root";
			}

			if (!path) {
				path = "~";
			}

			var prompt:String = settings.GetString("Main", "Prompt");
			var fontSize:Number = settings.GetNumber("Style", "FontSize");
			var fontColor:uint = settings.GetColor("Style", "PromptFontColor");

			var promptHtml:String = prompt.replace(/\$User\b/g, user);

			promptHtml = promptHtml.replace(/\$Path\b/g, path);
			promptHtml = "<font size='" + fontSize + "' color='" + ColorToHex(fontColor) + "'>" + promptHtml + "</font>";

			trace("[Console] SetCommandPromptEx `" + promptHtml + "`");

			CommandPromptEx_tf.htmlText = promptHtml;

			var promptWidth:Number = CommandPromptEx_tf.getLineMetrics(0).width;

			CommandPromptEx_tf.width = promptWidth + 5;
			CommandEntry.x = CommandPromptEx_tf.x + CommandPromptEx_tf.width;
			CommandEntry.width = OriginalWidth - CommandEntry.x - 30;
		}

		// called by native code. denied.
		public function SetCommandPrompt(dashDashDashPrompt:String):* {
			trace("[Console:NativeCall] SetCommandPrompt `" + dashDashDashPrompt + "`");
			CommandPrompt_tf.text = dashDashDashPrompt;
		}

		public function ClearHistory():* {
			CommandHistory.text = "";
		}

		public function ResetCommandEntry():* {
			CommandEntry.text = "";
			PreviousCommandOffset = 0;
		}

		public function onKeyUp(param1:KeyboardEvent):* {
			var pageAmount:int = 0;
			var targetScroll:int = 0;

			if (param1.keyCode == Keyboard.ENTER || param1.keyCode == Keyboard.NUMPAD_ENTER) {
				if (CommandEntry.text == "clear") {
					ClearHistory();
					ResetCommandEntry();
				} else if (ConsoleHistoryObj.saveCommand) {
					// saveCommand calls AddCommandToHistory + ExecuteCommand
					ConsoleHistoryObj.saveCommand(CommandEntry.text);
				} else {
					AddCommandToHistory(CommandEntry.text);
					ExecuteCommand(CommandEntry.text);
				}
			} else if (param1.keyCode == Keyboard.PAGE_UP) {
				pageAmount = CommandHistory.bottomScrollV - CommandHistory.scrollV;
				targetScroll = CommandHistory.scrollV - pageAmount;
				CommandHistory.scrollV = targetScroll > 0 ? int(targetScroll) : 0;
			} else if (param1.keyCode == Keyboard.PAGE_DOWN) {
				pageAmount = CommandHistory.bottomScrollV - CommandHistory.scrollV;
				targetScroll = CommandHistory.scrollV + pageAmount;
				CommandHistory.scrollV = targetScroll <= CommandHistory.maxScrollV ? int(targetScroll) : int(CommandHistory.maxScrollV);
				// trace("page down key is pressed...");
			} else if (param1.keyCode == togglePanelsKey) {
				showExtraInfoWindow = !showExtraInfoWindow;
				ShowInfoPanels();
			}
		}
	}
}
