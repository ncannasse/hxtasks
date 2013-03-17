package js;

import Common;

class App {

	var root : Task;
	var opened : Map<Int,Bool>;
	var menu : JQuery;
	var lock : JQuery;
	
	public function new() {
		opened = new Map();
		opened.set(0, true);
		menu = J("#tmenu");
		lock = J("#lock");
		lock.remove();
		load();
	}
	
	function load() {
		var id = 0;
		function make(t,?subs) : Task {
			return {
				id : id++,
				icon : 0,
				text : t,
				priority : 0,
				subs : subs == null ? [] : subs,
			}
		}
		root = make("(root)",[
				make("test"),
				make("another", [
					make("sub1", [make("a"),make("b"),make("c")]),
					make("sub2", [make("x"),make("y"),make("s")]),
					make("sub3"),
				]),
			]);
		display();
	}
	
	function display() {
		var b = buildChilds(root.subs);
		J("#tasks").append(b);
	}
	
	function buildChilds( tl : Array<Task> ) : JQuery {
		var ul = J("<ul>").addClass("l");
		for( t in tl )
			ul.append(buildTask(t));
		return ul;
	}
	
	function buildTask( t : Task ) : JQuery {
		var ico = J("<div>").addClass("i");
		var desc = J("<div>").addClass("desc").text(t.text);
		var content = J("<div>").append(ico).append(desc);
		var div = J("<div>").addClass("t").attr("id", "_t" + t.id).addClass("p" + t.priority).append(content);
		var li = J("<li>").addClass("t").append(div);
		content.mouseover(function(_) div.addClass("over"));
		content.mouseout(function(_) div.removeClass("over"));
		if( t.subs.length > 0 ) {
			li.addClass("childs");
			if( !opened.get(t.id) )
				li.addClass("closed");
			li.append(buildChilds(t.subs));
			content.click(toggleTask.bind(t));
		} else {
			li.addClass("nochilds");
			content.click(editTask.bind(t));
		}
		content.bind("contextmenu", function(_) {
			showMenu(t);
			return false;
		});
		return li;
	}
	
	function showMenu( t : Task ) {
		var td = get(t);
		td.append(menu);
		lock.click(function(_) {
			menu.hide();
			lock.remove();
		});
		lock.bind("contextmenu", function(_) {
			lock.click();
			return false;
		});
		J("body").append(lock);
		menu.show(100);
	}
	
	function toggleTask( t : Task ) {
		var o = !opened.get(t.id);
		opened.set(t.id, o);
		var sub = get(t).parent().toggleClass("closed").children("ul.l");
		if( o ) {
			sub.hide();
			sub.show(100);
		} else
			sub.hide(100);
	}
	
	function editTask( t : Task ) {
		var td = get(t);
		if( td.hasClass("edit") )
			return;
		var tf = J("<input>");
		td.addClass("edit").append(tf);
		function onBlur(e) {
			tf.remove();
			if( e != null )
				t.text = tf.val();
			td.children("div.desc").text(t.text);
			td.removeClass("edit");
		}
		function onKey(k:JQuery.JqEvent) {
			switch( k.keyCode ) {
			case 27:
				onBlur(null);
			case 13:
				onBlur(k);
			default:
			}
		}
		tf.val(t.text);
		tf.blur(onBlur);
		tf.keydown(onKey);
		tf.focus();
	}
	
	function get( t : Task ) {
		return J("#_t" + t.id);
	}

	static function J(t:String) {
		return new JQuery(t);
	}
	
	static function main() {
		untyped Browser.window._ = new App();
	}
	
}