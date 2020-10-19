/**
 * ...
 * @author fox
 */
import com.GameInterface.DistributedValue;
import com.GameInterface.DistributedValueBase;
import com.GameInterface.DressingRoom;
import com.GameInterface.DressingRoomNode;
import com.GameInterface.Game.Character;
import com.GameInterface.Game.CharacterBase;
import com.Utils.Archive;
import com.Utils.Colors;
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
	private var DRTweaks_keyboard:DistributedValue;
	private var DRTweaks_DisableIdleAnimations:DistributedValue;
	private var m_DressingRoom:MovieClip;
	private var keyListener:Object;
	private var focusListener:Object;
	private var KeyPresstimeOut;
	private var m_colorCheckbox:MovieClip;
	private var m_trashCheckbox:MovieClip;
	
	private var OwnedOnly:Boolean;
	private var ShowTrash:Boolean;
	private var Favorites:Array;
	private var Trash:Array;
	
	public function Mod(root) {
		m_swfroot = root;
		keyListener = new Object();
		keyListener.onKeyDown = Delegate.create(this, KeyPressedBuffer);
		DressingRoomLeftX = DistributedValue.Create("DressingRoomLeftX");
		DressingRoomLeftY = DistributedValue.Create("DressingRoomLeftY");
		DressingRoomRightX = DistributedValue.Create("DressingRoomRightX");
		DressingRoomRightY = DistributedValue.Create("DressingRoomRightY");
		DressingRoomDval = DistributedValue.Create("dressingRoom_window");
		DRTweaks_keyboard = DistributedValue.Create("DRTweaks_keyboard");
		DRTweaks_DisableIdleAnimations = DistributedValue.Create("DRTweaks_DisableIdleAnimations");
		focusListener = new Object();
		focusListener.onSetFocus = Delegate.create(this, FocusChanged);
	}
	public function Load() {
		DressingRoomDval.SignalChanged.Connect(HookLayout, this);
	}
	public function Unload() {
		DressingRoomDval.SignalChanged.Disconnect(HookLayout, this);
		Key.removeListener(keyListener);
		Selection.removeListener(focusListener);
	}
	public function Activate(config:Archive){
		DressingRoomLeftX.SetValue(config.FindEntry("DressingRoomLeftX", 100));
		DressingRoomLeftY.SetValue(config.FindEntry("DressingRoomLeftY", undefined));
		DressingRoomRightX.SetValue(config.FindEntry("DressingRoomRightX", undefined));
		DressingRoomRightY.SetValue(config.FindEntry("DressingRoomRightY", undefined));
		DRTweaks_keyboard.SetValue(config.FindEntry("DRTweaks_keyboard", true));
		DRTweaks_DisableIdleAnimations.SetValue(config.FindEntry("DRTweaks_DisableIdleAnimations", true));
		OwnedOnly = Boolean(config.FindEntry("OwnedOnly", true));
		ShowTrash = Boolean(config.FindEntry("TrashHidden", false));
		Favorites = config.FindEntryArray("Favorites");
		if (!Favorites) Favorites = new Array();
		Trash = config.FindEntryArray("Trash");
		if (!Trash) Trash = new Array();
		
		HookLayout(DressingRoomDval);
	}
	public function Deactivate():Archive {
		var config:Archive = new Archive();
		config.AddEntry("DressingRoomLeftX",DressingRoomLeftX.GetValue());
		config.AddEntry("DressingRoomLeftY",DressingRoomLeftY.GetValue());
		config.AddEntry("DressingRoomRightX",DressingRoomRightX.GetValue());
		config.AddEntry("DressingRoomRightY", DressingRoomRightY.GetValue());
		config.AddEntry("DRTweaks_keyboard", DRTweaks_keyboard.GetValue());
		config.AddEntry("DRTweaks_DisableIdleAnimations", DRTweaks_DisableIdleAnimations.GetValue());
		config.AddEntry("OwnedOnly", OwnedOnly);
		config.AddEntry("TrashHidden", ShowTrash);
		for (var i in Favorites){
			config.AddEntry("Favorites",Favorites[i]);
		}
		for (var i in Trash){
			config.AddEntry("Trash",Trash[i]);
		}
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

	private function FindNextOwned(Entries:Array, direction, idx){
		var retVal:Number = idx;
		if (direction > 0){
			for (var i:Number = 0; i < Entries.length; i++){
				var pos = i + idx;
				if (!Entries[pos]) pos -= Entries.length;
				if (DressingRoom.NodeOwned(Entries[pos].m_NodeId)) return pos;
 			}
		}else{
			for (var i:Number = 0; i < Entries.length; i++){
				var pos = idx-i;
				if (!Entries[pos]) pos += Entries.length;
				if (DressingRoom.NodeOwned(Entries[pos].m_NodeId)) return pos;
 			}
		}
		return undefined
	}
	
	private function inArray(id:Number, array:Array){
		for (var i in array) if (array[i] == id) return i;
	}

	// Tint
	private function PopulateCategoryList(idx:Boolean){
		m_DressingRoom.m_LeftPanel.m_CategoryList.removeEventListener("change", this, "OnItemSelected");
		var filteredArray:Array = m_DressingRoom.m_LeftPanel.FilterCategoryArray(m_DressingRoom.m_LeftPanel.m_CategoryArray);
		filteredArray.sort(m_DressingRoom.m_LeftPanel.nodeCompare);
		
		var DelList:Array = new Array();
		var FavList:Array = new Array();
		var SpliceList:Array = new Array();
		for (var i = 0; i < filteredArray.length;i++ ){
			if (inArray(filteredArray[i].m_NodeId, Favorites) != undefined){
				var entry = filteredArray[i]
				SpliceList.push(i);
				FavList.push(entry);
				
			}
			else if (inArray(filteredArray[i].m_NodeId, Trash) != undefined){
				var entry = filteredArray[i]
				SpliceList.push(i);
				DelList.push(entry);
			}
		}
		for (var i in SpliceList){
			filteredArray.splice(SpliceList[i],1);
		}
		filteredArray = FavList.concat(filteredArray);
		if (ShowTrash){
			filteredArray = filteredArray.concat(DelList);
		}
		
		m_DressingRoom.m_LeftPanel.m_CategoryList.dataProvider = filteredArray;
		m_DressingRoom.m_LeftPanel.m_CategoryList.invalidateData();
		m_DressingRoom.m_LeftPanel.m_CategoryList.addEventListener("change", m_DressingRoom.m_LeftPanel, "OnCategorySelected");
		//scrolls to start unless user just presses trash/fav button
		if(!idx) m_DressingRoom.m_LeftPanel.m_CategoryList.selectedIndex = 0;
		m_DressingRoom.m_LeftPanel.OnCategorySelected();
		m_DressingRoom.m_LeftPanel.m_CategoryList.addEventListener("itemPress", this, "ItemPressed");
		setIcons();
		//sets preview if user had clicked on trash/fav
		if (idx){
			KeyPressed(40);
		}
	}
	
	private function ItemPressed(clip:MovieClip){
		var clicked;
		//Favorite and remove from trash
		if (clip.renderer.fav.hitTest(_root._xmouse, _root._ymouse)){
			var found = inArray(clip.renderer.data.m_NodeId, Favorites);
			//already favorited,remove from favorites
			if (found != undefined){
				Favorites.splice(found,1);
			}
			//add to favorites
			else{
				Favorites.push(clip.renderer.data.m_NodeId);
				//remove from trash
				found = inArray(clip.renderer.data.m_NodeId, Trash);
				if (found != undefined) Trash.splice(found,1);
			}
			clicked = "fav";
		}
		//Trash and remove from favorites
		if (clip.renderer.trash.hitTest(_root._xmouse, _root._ymouse)){
			var found = inArray(clip.renderer.data.m_NodeId, Trash);
			if (found != undefined){
				Trash.splice(found, 1);
			}
			else{
				Trash.push(clip.renderer.data.m_NodeId);
				found = inArray(clip.renderer.data.m_NodeId, Favorites);
				if (found != undefined) Favorites.splice(found,1);
			}
			clicked = "trash";
		}
		//redraw
		if (clicked){
			PopulateCategoryList(true);
		}else{
			setTimeout(Delegate.create(this, KeyPressed), 200, 40);
			SetFocus();
		}
	}
	private function KeyPressedBuffer(){
		clearTimeout(KeyPresstimeOut);
		//setTimeout appears to make character less naked when scrolling fast
		KeyPresstimeOut = setTimeout(Delegate.create(this, KeyPressed), 100, Key.getCode(),Key.isDown(Key.CONTROL));
	}
	private function KeyPressed(Keycode, Control){
		if (Control && (Keycode == 40 || Keycode == 38)){
			var idx = 0;
			for (var i:Number = 0; i < m_DressingRoom.m_LeftPanel["m_TabArray"].length; i++){
				if (m_DressingRoom.m_LeftPanel["m_TabGroup"].selectedButton == m_DressingRoom.m_LeftPanel["m_TabArray"][i]){
					if (Keycode == 40){
						idx = i+1;
						if (!m_DressingRoom.m_LeftPanel["m_TabArray"][idx]){
							return
						}
					}else{
						idx = i-1;
						if (!m_DressingRoom.m_LeftPanel["m_TabArray"][idx]){
							return
						}
					}
					m_DressingRoom.m_LeftPanel["m_TabGroup"].setSelectedButton(m_DressingRoom.m_LeftPanel["m_TabArray"][idx]);
					break
				}
			}
			return
		}
		var Modevariable:String;
		var ListVariable:String;
		if (m_DressingRoom.m_RightPanel["m_CurrentMode"] == 0){
			Modevariable = "m_ColorPicker"
			ListVariable = "m_ColorTileList"
		}else if (m_DressingRoom.m_RightPanel["m_CurrentMode"] == 1 || m_DressingRoom.m_RightPanel["m_CurrentMode"] == m_DressingRoom.m_RightPanel.WEAPON_SKINS || m_DressingRoom.m_RightPanel["m_CurrentMode"] == m_DressingRoom.m_RightPanel.BUNDLES){
			Modevariable = "m_ItemSelector"
			ListVariable = "m_ItemList"
		}
		var selected = m_DressingRoom.m_RightPanel[Modevariable][ListVariable]["_selectedIndex"];
		// up or down,previews first color
		if (Keycode == 40 || Keycode == 38){
			m_DressingRoom.m_RightPanel["ClearStickyPreview"]();
			m_DressingRoom.m_RightPanel["ClearPreview"]();
			var idx = 0;
			if(!OwnedOnly){
				if (!DressingRoom.NodeOwned(m_DressingRoom.m_RightPanel[Modevariable][ListVariable]["dataProvider"][idx].m_NodeId)){
					idx = FindNextOwned(m_DressingRoom.m_RightPanel[Modevariable][ListVariable]["dataProvider"], 1, idx);
					if (idx == undefined) return;
				}
			}
			m_DressingRoom.m_RightPanel[Modevariable][ListVariable].dispatchEvent({
				type:"change",
				item:m_DressingRoom.m_RightPanel[Modevariable][ListVariable]["dataProvider"][idx]
			});
			m_DressingRoom.m_RightPanel[Modevariable][ListVariable].dispatchEvent({
				type:"itemClick",
				item:m_DressingRoom.m_RightPanel[Modevariable][ListVariable]["dataProvider"][idx]
			});
			m_DressingRoom.m_RightPanel[Modevariable][ListVariable]["selectedIndex"] = idx;
		}
		//right
		else if (Keycode == 39){
			var idx = selected + 1;
			if (!m_DressingRoom.m_RightPanel[Modevariable][ListVariable]["dataProvider"][idx]){
				idx = 0
			}
			if(!OwnedOnly){
				if (!DressingRoom.NodeOwned(m_DressingRoom.m_RightPanel[Modevariable][ListVariable]["dataProvider"][idx].m_NodeId)){
					idx = FindNextOwned(m_DressingRoom.m_RightPanel[Modevariable][ListVariable]["dataProvider"], 1, idx);
					if (idx == undefined) return;
				}
			}
			if(idx != selected){
				m_DressingRoom.m_RightPanel[Modevariable][ListVariable]["selectedIndex"] = idx;
				m_DressingRoom.m_RightPanel[Modevariable][ListVariable].dispatchEvent({
					type:"change",
					item:m_DressingRoom.m_RightPanel[Modevariable][ListVariable]["dataProvider"][idx]
				});
				m_DressingRoom.m_RightPanel[Modevariable][ListVariable].dispatchEvent({
					type:"itemClick",
					item:m_DressingRoom.m_RightPanel[Modevariable][ListVariable]["dataProvider"][idx]
				})
			}
		}
		//left
		else if (Keycode == 37){
			var idx = selected -1;
			if (!m_DressingRoom.m_RightPanel[Modevariable][ListVariable]["dataProvider"][idx]){
				idx = m_DressingRoom.m_RightPanel[Modevariable][ListVariable]["dataProvider"].length-1;
			}
			if(!OwnedOnly){
				if (!DressingRoom.NodeOwned(m_DressingRoom.m_RightPanel[Modevariable][ListVariable]["dataProvider"][idx].m_NodeId)){
					idx = FindNextOwned(m_DressingRoom.m_RightPanel[Modevariable][ListVariable]["dataProvider"], -1, idx);
					if (idx == undefined) return;
				}
			}
			if(idx != selected){
				m_DressingRoom.m_RightPanel[Modevariable][ListVariable]["selectedIndex"] = idx;
				m_DressingRoom.m_RightPanel[Modevariable][ListVariable].dispatchEvent({
					type:"change",
					item:m_DressingRoom.m_RightPanel[Modevariable][ListVariable]["dataProvider"][idx]
				});
				m_DressingRoom.m_RightPanel[Modevariable][ListVariable].dispatchEvent({
					type:"itemClick",
					item:m_DressingRoom.m_RightPanel[Modevariable][ListVariable]["dataProvider"][idx]
				})
			}
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
		// ESC,W,S,A,D Close window
		else if (Keycode == 27 || Keycode == 87 || Keycode == 83 || Keycode == 65 || Keycode == 68){
			m_DressingRoom.m_RightPanel["ClearStickyPreview"]();
			m_DressingRoom.m_RightPanel["ClearPreview"]();
			DressingRoomDval.SetValue(false);
		}
		/*
		 * Delete button and Favorite buttons?
		else if (Keycode == 46){
			
		}
		*/
	}
	
	// Color Trash/Fav icons on scroll.
	private function setIcons(){
		for (var i in _root.dressingroom.m_LeftPanel.m_CategoryList.container){
			var renderer = _root.dressingroom.m_LeftPanel.m_CategoryList.container[i];
			if (renderer == _root.dressingroom.m_LeftPanel.m_CategoryList.container._scrollBar) continue;
			Colors.ApplyColor(renderer.fav, 0x959595);
			Colors.ApplyColor(renderer.trash, 0x959595);
			var node:DressingRoomNode = renderer.data;
			if (inArray(node.m_NodeId, Favorites) != undefined){
				Colors.ApplyColor(renderer.fav, 0xBDB402);
			}
			if (inArray(node.m_NodeId, Trash) != undefined){
				Colors.ApplyColor(renderer.trash, 0xBF0000);
			}
		}
	}
	
	private function HookLayout(dv:DistributedValue){
		if (dv.GetValue()){
			m_DressingRoom = _root.dressingroom;
			if (!m_DressingRoom["m_LeftPanel"]["initialized"] || !m_DressingRoom["m_RightPanel"]["initialized"]){
				setTimeout(Delegate.create(this, HookLayout), 50, dv);
				return
			}
			// it should be enough to just position them when opened, but hooking the layout function ensures they always stays in the right position.
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
				m_DressingRoom.Layout();
			}
			//creates the list, with fav -> unordered -> trash order
			if (!m_DressingRoom.m_LeftPanel._PopulateCategoryList){
				m_DressingRoom.m_LeftPanel._PopulateCategoryList = m_DressingRoom.m_LeftPanel.PopulateCategoryList;
				m_DressingRoom.m_LeftPanel.PopulateCategoryList = Delegate.create(this, PopulateCategoryList);
			}
			m_DressingRoom.m_LeftPanel.RemoveFocus = undefined;
			
			// Trash/Fav button creation
			if (!_global.com.fox.DRTweaks.Hooked){
				_global.GUI.DressingRoom.CategoryListItemRenderer.prototype.onLoadComplete = function(target:MovieClip){
					if (target._name == "trash"){
						target._width = 12;
						target._height = 16;
						var xClip:MovieClip = this.m_PromoIcon || this.m_Owned;
						target._x = xClip._x - 46;
						target._y = this.m_Owned._y;
					}
					else{
						target._width = 18;
						target._height = 18;
						var xClip:MovieClip = this.m_PromoIcon ||  this.m_Owned;
						target._x = xClip._x - 28;
						target._y = this.m_Owned._y;
					}
				}
				var f:Function = function(data:DressingRoomNode) {
					arguments.callee.base.apply(this, arguments);
					if (data && !this.trash){
						var mcLoader:MovieClipLoader = new MovieClipLoader();
						var container = this.createEmptyMovieClip("trash", this.getNextHighestDepth());
						var container2 = this.createEmptyMovieClip("fav", this.getNextHighestDepth());
						var path = "DRTweaks\\trash.png";
						var path2 = "DRTweaks\\fav.png";
						var resizer:Object = new Object();
						mcLoader.addListener(this);
						mcLoader.loadClip(path, container);
						mcLoader.loadClip(path2, container2);
					}
					else{
						this.onLoadComplete(this.trash);
						this.onLoadComplete(this.fav);
					}
				}
				f.base = _global.GUI.DressingRoom.CategoryListItemRenderer.prototype.setData;
				_global.GUI.DressingRoom.CategoryListItemRenderer.prototype.setData = f;

				m_DressingRoom.m_LeftPanel.m_CategoryList.addEventListener("itemPress", this, "ItemPressed");
				m_DressingRoom.m_LeftPanel.m_CategoryList._scrollBar.addEventListener("scroll", this, "setIcons");
				
				_global.com.fox.DRTweaks.Hooked = true;
			}
			
			// Repostions panels on screen, in case of resolution change
			var newPos:Point = Common.getOnScreen(m_DressingRoom.m_LeftPanel);
			m_DressingRoom.m_LeftPanel._x = newPos.x;
			m_DressingRoom.m_LeftPanel._y = newPos.y;
			DressingRoomLeftX.SetValue(newPos.x);
			DressingRoomLeftY.SetValue(newPos.y);
			
			newPos = Common.getOnScreen(m_DressingRoom.m_RightPanel);
			m_DressingRoom.m_RightPanel._x = newPos.x;
			m_DressingRoom.m_RightPanel._y = newPos.y;
			DressingRoomRightX.SetValue(newPos.x);
			DressingRoomRightY.SetValue(newPos.y);
			
			// Drag&Save
			m_DressingRoom.m_LeftPanel.m_Background.onPress = Delegate.create(this, MoveLeft);
			m_DressingRoom.m_LeftPanel.m_Background.onRelease = Delegate.create(this, SaveLeft);
			m_DressingRoom.m_LeftPanel.m_Background.onReleaseOutside = Delegate.create(this, SaveLeft);
			
			m_DressingRoom.m_RightPanel.m_Background.onPress = Delegate.create(this, MoveRight);
			m_DressingRoom.m_RightPanel.m_Background.onRelease = Delegate.create(this, SaveRight);
			m_DressingRoom.m_RightPanel.m_Background.onReleaseOutside = Delegate.create(this, SaveRight);
			
			// cant click what you cant see, makes it easier to drag the left panel.
			m_DressingRoom.m_LeftPanel.m_HeaderText._visible = false;
			PopulateCategoryList();
			
			//positioning
			var container:MovieClip = m_DressingRoom.m_LeftPanel.createEmptyMovieClip("DRTweaks", m_DressingRoom.m_LeftPanel.getNextHighestDepth());
			var x = m_DressingRoom.m_LeftPanel.m_UnownedCheckBox._x - 100;
			var y = m_DressingRoom.m_LeftPanel.m_UnownedCheckBox._y;
			var label:TextField = m_DressingRoom.m_LeftPanel.m_UnownedFilterText;
			var format = label.getTextFormat();
			
			//hide trash checkbox
			m_trashCheckbox = container.attachMovie("CheckBoxNoneLabel", "m_TrashBox", container.getNextHighestDepth(), {_x:x+100, _y:m_DressingRoom.m_LeftPanel.m_Background._y-10 + m_DressingRoom.m_LeftPanel.m_Background._height });
			m_trashCheckbox._width = m_DressingRoom.m_LeftPanel.m_UnownedCheckBox._width;
			m_trashCheckbox._height = m_DressingRoom.m_LeftPanel.m_UnownedCheckBox._height;
			m_trashCheckbox.addEventListener("click", this, "TrashChanged");
			m_trashCheckbox.selected = ShowTrash;
			// label
			var trashField:TextField = container.createTextField("m_TrashField", container.getNextHighestDepth(), x+100, m_DressingRoom.m_LeftPanel.m_Background._y + m_DressingRoom.m_LeftPanel.m_Background._height-5, label._width, label._height);
			trashField.autoSize = "left";
			trashField.setNewTextFormat(format);
			trashField.setTextFormat(format);
			trashField.embedFonts = true;
			trashField.text = "Show hidden:";
			trashField._x -= trashField._width;
			
			// Key listener and color checkbox
			if(DRTweaks_keyboard.GetValue()){
				//Color Checkbox
				m_colorCheckbox = container.attachMovie("CheckBoxNoneLabel", "m_ownedColorCheckbox",container.getNextHighestDepth(), {_x:x, _y:y});
				m_colorCheckbox._width = m_DressingRoom.m_LeftPanel.m_UnownedCheckBox._width;
				m_colorCheckbox._height = m_DressingRoom.m_LeftPanel.m_UnownedCheckBox._height;
				m_colorCheckbox.addEventListener("click", this, "OwnedChanged");
				m_colorCheckbox.selected = OwnedOnly;
				
				var TxtField:TextField 	= container.createTextField("m_ownedColor", container.getNextHighestDepth(), x, label._y, label._width, label._height);
				TxtField.autoSize = "left";
				TxtField.setNewTextFormat(format);
				TxtField.setTextFormat(format)
				TxtField.embedFonts = true;
				TxtField.text = "Unowned Colours:"
				TxtField._x -= TxtField._width;
				m_DressingRoom.m_LeftPanel.m_Background._height += 20;
				
				// these make sure that the scrollbar is set to focus when needed.
				Selection.addListener(focusListener);
				Selection.setFocus(m_DressingRoom.m_LeftPanel.m_CategoryList);
				m_DressingRoom.m_LeftPanel["m_TabGroup"].addEventListener("change", this, "SetFocus");
				SetIdle();
			}
		}else{
			Key.removeListener(keyListener);
			Selection.removeListener(focusListener);
		}
	}
	
	//disables idle animations, Base Animation appears to reset when player moves, so no need to set it back.
	private function SetIdle(){
		if (DRTweaks_DisableIdleAnimations.GetValue()) Character.GetClientCharacter().SetBaseAnim("normal_idle");
	}
	
	private function SetFocus(){
		Selection.setFocus(m_DressingRoom.m_LeftPanel.m_CategoryList);
	}

	private function GetFullPath(clip:MovieClip){
		var FullPath:Array = new Array(clip._name);
		var parentClip:MovieClip = clip;
		while (parentClip != undefined){
			parentClip = parentClip._parent;
			if(parentClip) FullPath.push(parentClip._name)
		}
		FullPath.reverse();
		return FullPath.join(".");
	}
	// hacky af
	// should set the m_CategoryList active when player finishes searching, or clicks any left/right panel component
	private function FocusChanged(oldFocus:MovieClip, newFocus:MovieClip){
		Key.removeListener(keyListener);
		if (newFocus._name == "m_SearchText") return;
		if (oldFocus._name == "m_SearchText"){
			setTimeout(Delegate.create(this, SetFocus), 5);
			return
		}
		if (newFocus._name == "m_CategoryList"){
			Key.addListener(keyListener);
			return
		}

		var Fullpath = GetFullPath(newFocus);
		if (!Fullpath) return;
		if (Fullpath.indexOf("m_RightPanel") > 0 || Fullpath.indexOf("m_LeftPanel") > 0){
			Key.addListener(keyListener);
			setTimeout(Delegate.create(this, SetFocus), 5);
		}
	}
	private function OwnedChanged(event){
		OwnedOnly = m_colorCheckbox.selected;
	}
	private function TrashChanged(event){
		ShowTrash = m_trashCheckbox.selected;
		PopulateCategoryList();
	}
}