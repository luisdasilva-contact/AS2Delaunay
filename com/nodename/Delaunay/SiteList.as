import com.nodename.geom.Circle;
import flash.display.BitmapData;
import flash.geom.Point;
import flash.geom.Rectangle;
import com.nodename.Delaunay.*;

class com.nodename.Delaunay.SiteList {
	private var _sites:Array;
	private var _currentIndex:Number;
	
	private var _sorted:Boolean;
	
	public function get sites(){
		return _sites;
	}
		
	public function SiteList() {
		_sites = new Array();
		_sorted = false;
	}
	
	public function dispose():Void {
		if (_sites) {
			for (var i = 0; i < _sites.length; i++){
				_sites[i].dispose();
			}
			_sites.length = 0;
			_sites = null;
		}
	}
	
	public function push(site:Site):Number {
		_sorted = false;
		
		return _sites.push(site);
	}
		
	public function get length():Number {
		return _sites.length;
	}
		
	public function next():Site	{
		if (_sorted == false) {
			throw new Error("SiteList::next():  sites have not been sorted");
		}
		if (_currentIndex < _sites.length) {
			return _sites[_currentIndex++];
		} else {
			return null;
		}
	}
	
	function getSitesBounds():Rectangle	{
		if (_sorted == false) {
			Site.sortSites(_sites);
			_currentIndex = 0;
			_sorted = true;
		}
		var xmin:Number, xmax:Number, ymin:Number, ymax:Number;
		if (_sites.length == 0)	{
			return new Rectangle(0, 0, 0, 0);
		}
		xmin = Number.MAX_VALUE;
		xmax = Number.MIN_VALUE;
		
		for (var i = 0; i < _sites.length; i++){
			if (_sites[i].x < xmin)	{
				xmin = _sites[i].x;
			}
			if (_sites[i].x > xmax)	{
				xmax = _sites[i].x;
			}
			
		}
		// here's where we assume that the sites have been sorted on y:
		ymin = _sites[0].y;
		ymax = _sites[_sites.length - 1].y;
		var rectToReturn:Rectangle = new Rectangle(xmin, ymin, xmax - xmin, ymax - ymin);
		
		
		return rectToReturn;
	}
	
	public function siteColors(referenceImage:BitmapData):Array {
		if (!referenceImage){referenceImage = null}
			var colors:Array = new Array();
			for (var i = 0; i < _sites.length; i++){
				colors.push(referenceImage ? referenceImage.getPixel(_sites[i].x, _sites[i].y) : _sites[i].color);
			}
			return colors;
		}

	public function siteCoords():Array {
		var coords:Array = new Array();
		for (var i = 0; i < _sites.length; i++){
			coords.push(_sites[i].coord);
		}
		return coords;
	}
	
	/**
		 * 
		 * @return the largest circle centered at each site that fits in its region;
		 * if the region is infinite, return a circle of radius 0.
		 * 
		 */
		public function circles():Array	{
			var circles:Array = new Array();
			for (var i = 0; i < _sites.length; i++){
				var radius:Number = 0;
				var nearestEdge:Edge = _sites[i].nearestEdge();
				!nearestEdge.isPartOfConvexHull() && (radius = nearestEdge.sitesDistance() * 0.5);
				circles.push(new Circle(_sites[i].x, _sites[i].y, radius));
			}
			return circles;
		}

		
		public function regions(plotBounds:Rectangle):Array {
			var regions:Array = new Array();
			for (var i = 0; i < _sites.length; i++){
				regions.push(_sites[i].region(plotBounds));
			}
			return regions;
		}

		/**
		 * @param proximityMap a BitmapData whose regions are filled with the site index values; see PlanePointsCanvas::fillRegions()
		 * @param x
		 * @param y
		 * @return coordinates of nearest Site to (x, y)
		 * 
		 */
		public function nearestSitePoint(proximityMap:BitmapData, x:Number, y:Number):Point	{
			var index:Number = proximityMap.getPixel(x, y);
			if (index > _sites.length - 1)	{
				return null;
			}
			return _sites[index].coord;
		}
	
	
}