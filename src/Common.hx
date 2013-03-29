
typedef Task = {
	var id : Int;
	var text : String;
	var priority : Int;
	var subs : Null<Array<Task>>; // null = not a group
	var done : Bool;
}

enum Action<T> {
	Load : Action<Task>;
	Create( text : String, pid : Int ) : Action<Int>;
	Rename( id : Int, old : String, newText : String ) : Action<Bool>;
	Mark( id : Int, m : Bool ) : Action<Bool>;
}