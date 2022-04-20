import com.nodename.utils.*;

class com.nodename.Delaunay.LR {
	public static var LEFT:LR = new LR(PrivateConstructorEnforcer, "left");
	public static var RIGHT:LR = new LR(PrivateConstructorEnforcer, "right");
	
	private var _name:String;
		
	public function LR(lock, name:String){
		_name = name;
	}
	
	public static function other(leftRight:LR):LR {
		return leftRight == LEFT ? RIGHT : LEFT;
	}
		
	public function toString():String {
		return _name;
	}
}