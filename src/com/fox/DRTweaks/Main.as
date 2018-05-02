import com.Utils.Archive;
import com.fox.DRTweaks.Mod

class com.fox.DRTweaks.Main {
	static var s_app:Mod;
	
	public static function main(swfRoot:MovieClip):Void {
		s_app = new Mod(swfRoot);
		swfRoot.onLoad = Load;
		swfRoot.onUnload = Unload;
		swfRoot.OnModuleActivated = OnActivated;
		swfRoot.OnModuleDeactivated = OnDeactivated;
	}

	public function Main() { }
	public static function Load() {
		s_app.Load();
	}
	public static function Unload() {
		s_app.Unload();
	}
	public static function OnActivated(config: Archive):Void {
		s_app.Activate(config);
	}

	public static function OnDeactivated():Archive {
		return s_app.Deactivate();
	}
}