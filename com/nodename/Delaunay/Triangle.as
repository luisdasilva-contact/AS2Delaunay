class com.nodename.Delaunay.Triangle {
	private var _sites:Array;
	public function get sites():Array{
		return _sites;
	}
	
	public function Triangle(a:Site, b: Site, c: Site){
		_sites:Array = [a, b, c];
	}
	
	public function dispose():void {
		_sites.length = 0;
		_sites = null;
	}
}