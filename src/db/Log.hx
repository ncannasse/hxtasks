package db;
import sys.db.Types;

enum LogAction {
	TaskCreate;
	TaskRename;
	TaskMark;
	TaskPriority;
	TaskDelete;
	TaskGroup;
	TaskMoved;
	TaskOrder;
}

class Log extends sys.db.Object {

	public var id : SId;
	@:relation(uid)
	public var user : Null<User>;
	public var date : SDateTime;
	@:relation(tid)
	public var task : Null<Task>;
	
	public var action : SEnum<LogAction>;
	public var oldInt : Null<Int>;
	public var newInt : Null<Int>;
	public var oldString : Null<String>;
	public var newString : Null<String>;
	
}