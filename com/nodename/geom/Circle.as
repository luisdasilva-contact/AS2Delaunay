import flash.geom.Point;

class com.nodename.geom.Circle {
	
	public var center:Point;
	public var radius:Number;
	
	public function Circle(centerX:Number, centerY:Number, radius:Number)
	{
		this.center = new Point(centerX, centerY);
		this.radius = radius;
	}
	
	public function toString():String
	{
		return "Circle (center: " + center + "; radius: " + radius + ")";
	}	
}