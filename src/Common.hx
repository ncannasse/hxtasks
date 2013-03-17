
typedef Task = {
	var id : Int;
	var text : String;
	var priority : Int;
	var subs : Null<Array<Task>>; // null = not a group
}