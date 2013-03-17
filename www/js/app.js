(function () { "use strict";
var HxOverrides = function() { }
HxOverrides.__name__ = true;
HxOverrides.iter = function(a) {
	return { cur : 0, arr : a, hasNext : function() {
		return this.cur < this.arr.length;
	}, next : function() {
		return this.arr[this.cur++];
	}};
}
var Std = function() { }
Std.__name__ = true;
Std.string = function(s) {
	return js.Boot.__string_rec(s,"");
}
var StringBuf = function() {
	this.b = "";
};
StringBuf.__name__ = true;
var haxe = {}
haxe.ds = {}
haxe.ds.IntMap = function() {
	this.h = { };
};
haxe.ds.IntMap.__name__ = true;
haxe.ds.IntMap.prototype = {
	toString: function() {
		var s = new StringBuf();
		s.b += "{";
		var it = this.keys();
		while( it.hasNext() ) {
			var i = it.next();
			s.b += Std.string(i);
			s.b += " => ";
			s.b += Std.string(Std.string(this.get(i)));
			if(it.hasNext()) s.b += ", ";
		}
		s.b += "}";
		return s.b;
	}
	,iterator: function() {
		return { ref : this.h, it : this.keys(), hasNext : function() {
			return this.it.hasNext();
		}, next : function() {
			var i = this.it.next();
			return this.ref[i];
		}};
	}
	,keys: function() {
		var a = [];
		for( var key in this.h ) {
		if(this.h.hasOwnProperty(key)) a.push(key | 0);
		}
		return HxOverrides.iter(a);
	}
	,remove: function(key) {
		if(!this.h.hasOwnProperty(key)) return false;
		delete(this.h[key]);
		return true;
	}
	,exists: function(key) {
		return this.h.hasOwnProperty(key);
	}
	,get: function(key) {
		return this.h[key];
	}
	,set: function(key,value) {
		this.h[key] = value;
	}
}
var js = {}
js.App = function() {
	this.opened = new haxe.ds.IntMap();
	this.opened.set(0,true);
	this.load();
};
js.App.__name__ = true;
js.App.J = function(t) {
	return new js.JQuery(t);
}
js.App.main = function() {
	js.Browser.window._ = new js.App();
}
js.App.prototype = {
	get: function(t) {
		return js.App.J("#_t" + t.id);
	}
	,editTask: function(t) {
		var td = this.get(t);
		if(td.hasClass("edit")) return;
		var tf = js.App.J("<input>");
		td.addClass("edit").append(tf);
		var onBlur = function(e) {
			tf.remove();
			if(e != null) t.text = tf.val();
			td.children("div.desc").text(t.text);
			td.removeClass("edit");
		};
		var onKey = function(k) {
			switch(k.keyCode) {
			case 27:
				onBlur(null);
				break;
			case 13:
				onBlur(k);
				break;
			default:
			}
		};
		tf.val(t.text);
		tf.blur(onBlur);
		tf.keydown(onKey);
		tf.focus();
	}
	,toggleTask: function(t) {
		var o = !this.opened.get(t.id);
		this.opened.set(t.id,o);
		var sub = this.get(t).parent().toggleClass("closed").children("ul.l");
		if(o) {
			sub.hide();
			sub.show(100);
		} else sub.hide(100);
	}
	,buildTask: function(t) {
		var ico = js.App.J("<div>").addClass("i");
		var desc = js.App.J("<div>").addClass("desc").text(t.text);
		var div = js.App.J("<div>").addClass("t").attr("id","_t" + t.id).addClass("p" + t.priority).append(ico).append(desc);
		var li = js.App.J("<li>").addClass("t").append(div);
		div.mouseover(function(_) {
			div.addClass("over");
		});
		div.mouseout(function(_) {
			div.removeClass("over");
		});
		if(t.subs.length > 0) {
			li.addClass("childs");
			if(!this.opened.get(t.id)) li.addClass("closed");
			li.append(this.buildChilds(t.subs));
			div.click((function(f,t1) {
				return function() {
					return f(t1);
				};
			})($bind(this,this.toggleTask),t));
		} else {
			li.addClass("nochilds");
			div.click((function(f1,t2) {
				return function() {
					return f1(t2);
				};
			})($bind(this,this.editTask),t));
		}
		return li;
	}
	,buildChilds: function(tl) {
		var ul = js.App.J("<ul>").addClass("l");
		var _g = 0;
		while(_g < tl.length) {
			var t = tl[_g];
			++_g;
			ul.append(this.buildTask(t));
		}
		return ul;
	}
	,display: function() {
		var b = this.buildChilds(this.root.subs);
		js.App.J("#tasks").append(b);
	}
	,load: function() {
		var id = 0;
		var make = function(t,subs) {
			return { id : id++, icon : 0, text : t, priority : 0, subs : subs == null?[]:subs};
		};
		this.root = make("(root)",[make("test"),make("another",[make("sub1",[make("a"),make("b"),make("c")]),make("sub2",[make("x"),make("y"),make("s")]),make("sub3")])]);
		this.display();
	}
}
js.Boot = function() { }
js.Boot.__name__ = true;
js.Boot.__string_rec = function(o,s) {
	if(o == null) return "null";
	if(s.length >= 5) return "<...>";
	var t = typeof(o);
	if(t == "function" && (o.__name__ || o.__ename__)) t = "object";
	switch(t) {
	case "object":
		if(o instanceof Array) {
			if(o.__enum__) {
				if(o.length == 2) return o[0];
				var str = o[0] + "(";
				s += "\t";
				var _g1 = 2, _g = o.length;
				while(_g1 < _g) {
					var i = _g1++;
					if(i != 2) str += "," + js.Boot.__string_rec(o[i],s); else str += js.Boot.__string_rec(o[i],s);
				}
				return str + ")";
			}
			var l = o.length;
			var i;
			var str = "[";
			s += "\t";
			var _g = 0;
			while(_g < l) {
				var i1 = _g++;
				str += (i1 > 0?",":"") + js.Boot.__string_rec(o[i1],s);
			}
			str += "]";
			return str;
		}
		var tostr;
		try {
			tostr = o.toString;
		} catch( e ) {
			return "???";
		}
		if(tostr != null && tostr != Object.toString) {
			var s2 = o.toString();
			if(s2 != "[object Object]") return s2;
		}
		var k = null;
		var str = "{\n";
		s += "\t";
		var hasp = o.hasOwnProperty != null;
		for( var k in o ) { ;
		if(hasp && !o.hasOwnProperty(k)) {
			continue;
		}
		if(k == "prototype" || k == "__class__" || k == "__super__" || k == "__interfaces__" || k == "__properties__") {
			continue;
		}
		if(str.length != 2) str += ", \n";
		str += s + k + " : " + js.Boot.__string_rec(o[k],s);
		}
		s = s.substring(1);
		str += "\n" + s + "}";
		return str;
	case "function":
		return "<function>";
	case "string":
		return o;
	default:
		return String(o);
	}
}
js.Browser = function() { }
js.Browser.__name__ = true;
function $iterator(o) { if( o instanceof Array ) return function() { return HxOverrides.iter(o); }; return typeof(o.iterator) == 'function' ? $bind(o,o.iterator) : o.iterator; };
var $_;
function $bind(o,m) { var f = function(){ return f.method.apply(f.scope, arguments); }; f.scope = o; f.method = m; return f; };
String.__name__ = true;
Array.__name__ = true;
var q = window.jQuery;
js.JQuery = q;
js.Browser.window = typeof window != "undefined" ? window : null;
js.App.main();
})();
