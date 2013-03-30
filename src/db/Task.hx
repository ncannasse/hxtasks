package db;
import sys.db.Types;

@:index(pid,done)
class Task extends sys.db.Object {

	public var id : SId;
	public var text : String;
	public var isGroup : Bool;
	public var priority : Int;
	public var done : Bool;
	public var order : SInt;
	
	@:relation(pid)
	public var parent : Null<Task>;

	public function canAccess( u : User ) {
		var shares = u.getShares();
		var cur = this;
		while( cur != null ) {
			if( shares.exists(cur.id) )
				return true;
			cur = cur.parent;
		}
		return false;
	}
	
}