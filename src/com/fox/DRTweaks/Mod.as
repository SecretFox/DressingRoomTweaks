/**
 * ...
 * @author fox
 */
import com.GameInterface.DistributedValue;
import com.GameInterface.DistributedValueBase;
import com.GameInterface.Game.CharacterBase;
import com.Utils.Archive;
import flash.geom.Point;
import com.fox.Utils.Common;
import mx.utils.Delegate;


class com.fox.DRTweaks.Mod {

	private var m_swfroot:MovieClip;
	private var DressingRoomDval:DistributedValue;
	private var DressingRoomLeftX:DistributedValue;
	private var DressingRoomLeftY:DistributedValue;
	private var DressingRoomRightX:DistributedValue;
	private var DressingRoomRightY:DistributedValue;
	private var m_DressingRoom:MovieClip;
	private var keyListener:Object;
	private var KeyPresstimeOut;
	
	public function Mod(root) {
		m_swfroot = root;
	}
	public function Load() {
		DressingRoomLeftX = DistributedValue.Create("DressingRoomLeftX");
		DressingRoomLeftY = DistributedValue.Create("DressingRoomLeftY");
		DressingRoomRightX = DistributedValue.Create("DressingRoomRightX");
		DressingRoomRightY = DistributedValue.Create("DressingRoomRightY");
		DressingRoomDval = DistributedValue.Create("dressingRoom_window");
		DressingRoomDval.SignalChanged.Connect(HookLayout, this);
	}
	public function Unload() {
		DressingRoomDval.SignalChanged.Disconnect(HookLayout, this);
		Key.removeListener(keyListener);
	}
	public function Activate(config:Archive){
		DressingRoomLeftX.SetValue(config.FindEntry("DressingRoomLeftX", 100));
		DressingRoomLeftY.SetValue(config.FindEntry("DressingRoomLeftY", undefined));
		DressingRoomRightX.SetValue(config.FindEntry("DressingRoomRightX", undefined));
		DressingRoomRightY.SetValue(config.FindEntry("DressingRoomRightY", undefined));
		HookLayout(DressingRoomDval);
	}
	public function Deactivate():Archive {
		var config:Archive = new Archive();
		config.AddEntry("DressingRoomLeftX",DressingRoomLeftX.GetValue());
		config.AddEntry("DressingRoomLeftY",DressingRoomLeftY.GetValue());
		config.AddEntry("DressingRoomRightX",DressingRoomRightX.GetValue());
		config.AddEntry("DressingRoomRightY",DressingRoomRightY.GetValue());
		return config
	}
	private function MoveLeft(){
		m_DressingRoom.m_LeftPanel.startDrag();
	}
	private function SaveLeft(){
		m_DressingRoom.m_LeftPanel.stopDrag();
		var pos:Point = Common.getOnScreen(m_DressingRoom.m_LeftPanel);
		m_DressingRoom.m_LeftPanel._x = pos.x;
		m_DressingRoom.m_LeftPanel._y = pos.y;
		DressingRoomLeftX.SetValue(pos.x);
		DressingRoomLeftY.SetValue(pos.y);
	}
	private function MoveRight(){
		m_DressingRoom.m_RightPanel.startDrag();
	}
	private function SaveRight(){
		m_DressingRoom.m_RightPanel.stopDrag();
		var pos:Point = Common.getOnScreen(m_DressingRoom.m_RightPanel);
		m_DressingRoom.m_RightPanel._x = pos.x;
		m_DressingRoom.m_RightPanel._y = pos.y;
		DressingRoomRightX.SetValue(pos.x);
		DressingRoomRightY.SetValue(pos.y);
	}
	private function KeyPressedBuffer(){
		clearTimeout(KeyPresstimeOut);
		KeyPresstimeOut = setTimeout(Delegate.create(this, KeyPressed), 100, Key.getCode());
	}
	private function KeyPressed(Keycode){
		//private var
		if (m_DressingRoom.m_RightPanel["m_CurrentMode"] == 0){
			var selected = m_DressingRoom.m_RightPanel["m_ColorPicker"]["m_ColorTileList"]["selectedIndex"];
			// up or down,previews first color
			if (Keycode == 40 || Keycode == 38){
				m_DressingRoom.m_RightPanel["ClearStickyPreview"]();
				m_DressingRoom.m_RightPanel["ClearPreview"]();
				m_DressingRoom.m_RightPanel["m_ColorPicker"]["m_ColorTileList"].dispatchEvent({
					type:"change",
					item:m_DressingRoom.m_RightPanel["m_ColorPicker"]["m_ColorTileList"]["dataProvider"][0]
				});
				m_DressingRoom.m_RightPanel["m_ColorPicker"]["m_ColorTileList"].dispatchEvent({
					type:"itemClick",
					item:m_DressingRoom.m_RightPanel["m_ColorPicker"]["m_ColorTileList"]["dataProvider"][0]
				});
				m_DressingRoom.m_RightPanel["m_ColorPicker"]["m_ColorTileList"]["selectedIndex"] = 0;
			}
			//right
			else if (Keycode == 39){
				var idx = selected + 1;
				if (!m_DressingRoom.m_RightPanel["m_ColorPicker"]["m_ColorTileList"]["dataProvider"][idx]){
					idx = 0
				}
				if(idx != selected){
					m_DressingRoom.m_RightPanel["m_ColorPicker"]["m_ColorTileList"]["selectedIndex"] = idx;
					m_DressingRoom.m_RightPanel["m_ColorPicker"]["m_ColorTileList"].dispatchEvent({
						type:"change",
						item:m_DressingRoom.m_RightPanel["m_ColorPicker"]["m_ColorTileList"]["dataProvider"][idx]
					});
					m_DressingRoom.m_RightPanel["m_ColorPicker"]["m_ColorTileList"].dispatchEvent({
						type:"itemClick",
						item:m_DressingRoom.m_RightPanel["m_ColorPicker"]["m_ColorTileList"]["dataProvider"][idx]
					})
				}
			}
			//left
			else if (Keycode == 37){
				var idx = selected -1;
				if (!m_DressingRoom.m_RightPanel["m_ColorPicker"]["m_ColorTileList"]["dataProvider"][idx]){
					idx = m_DressingRoom.m_RightPanel["m_ColorPicker"]["m_ColorTileList"]["dataProvider"].length-1;
				}
				if(idx != selected){
					m_DressingRoom.m_RightPanel["m_ColorPicker"]["m_ColorTileList"]["selectedIndex"] = idx;
					m_DressingRoom.m_RightPanel["m_ColorPicker"]["m_ColorTileList"].dispatchEvent({
						type:"change",
						item:m_DressingRoom.m_RightPanel["m_ColorPicker"]["m_ColorTileList"]["dataProvider"][idx]
					});
					m_DressingRoom.m_RightPanel["m_ColorPicker"]["m_ColorTileList"].dispatchEvent({
						type:"itemClick",
						item:m_DressingRoom.m_RightPanel["m_ColorPicker"]["m_ColorTileList"]["dataProvider"][idx]
					})
				}
			}
			//ESC
			else if (Keycode == 27){
				DressingRoomDval.SetValue(false);
			}
			//backspace
			else if (Keycode == 8){
				m_DressingRoom.m_RightPanel["ClearStickyPreview"]();
				m_DressingRoom.m_RightPanel["ClearPreview"]();
			}
			//Enter
			else if (Keycode == 13){
				m_DressingRoom.m_RightPanel["ConfirmSelection"]();
			}
			//Fixed vanity mode
			else if (Keycode == 86){
				CharacterBase.ToggleVanityMode(true);
			}
		}
	}
	
	private function HookLayout(dv:DistributedValue){
		if (dv.GetValue()){
			m_DressingRoom = _root.dressingroom;
			if (!m_DressingRoom.Layout || !m_DressingRoom.m_LeftPanel.m_Background || !m_DressingRoom.m_RightPanel.m_Background ){
				setTimeout(Delegate.create(this, HookLayout), 50, dv);
				return
			}
			keyListener = new Object();
			keyListener.onKeyDown = Delegate.create(this, KeyPressedBuffer);
			Key.addListener(keyListener);
			if (!m_DressingRoom._Layout){
				m_DressingRoom._Layout = m_DressingRoom.Layout;
				m_DressingRoom.Layout = function(){
					//not needed,but calling it in-case funcom adds to it
					this.m_DressingRoom._Layout();
					if (DistributedValueBase.GetDValue("DressingRoomLeftX")) this.m_LeftPanel._x = 	DistributedValueBase.GetDValue("DressingRoomLeftX");
					if (DistributedValueBase.GetDValue("DressingRoomLeftY")) this.m_LeftPanel._y = 	DistributedValueBase.GetDValue("DressingRoomLeftY");
					if (DistributedValueBase.GetDValue("DressingRoomRightX")) this.m_RightPanel._x = DistributedValueBase.GetDValue("DressingRoomRightX");
					if (DistributedValueBase.GetDValue("DressingRoomRightY")) this.m_RightPanel._y = DistributedValueBase.GetDValue("DressingRoomRightY");
				}
			}
			m_DressingRoom.Layout();
			// cant click what you cant see
			m_DressingRoom.m_LeftPanel.m_HeaderText._visible = false;

			m_DressingRoom.m_LeftPanel.m_Background.onPress = Delegate.create(this, MoveLeft);
			m_DressingRoom.m_LeftPanel.m_Background.onRelease = Delegate.create(this, SaveLeft);
			m_DressingRoom.m_LeftPanel.m_Background.onReleaseOutside = Delegate.create(this, SaveLeft);
			
			m_DressingRoom.m_RightPanel.m_Background.onPress = Delegate.create(this, MoveRight);
			m_DressingRoom.m_RightPanel.m_Background.onRelease = Delegate.create(this, SaveRight);
			m_DressingRoom.m_RightPanel.m_Background.onReleaseOutside = Delegate.create(this, SaveRight)
		}else{
			Key.removeListener(keyListener);
		}
	}
}