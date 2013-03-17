package db;
import sys.db.Types;

class Task extends sys.db.Object {

	public var id : SId;
	public var text : String;
	public var isGroup : Bool;
	public var priority : Int;
	
	@:relation(pid)
	public var parent : Null<Task>;
	
}