class com.nodename.geom.Winding {
	public static var CLOCKWISE:Winding = new Winding("clockwise");
	public static var COUNTERCLOCKWISE:Winding = new Winding("counterclockwise");
	public static var NONE:Winding = new Winding("none");
		
	private var _name:String;
	
	public function Winding(lock, name:String)
	{
		_name = name;
	}
	
	public function toString():String {
		return _name;
	}

}
