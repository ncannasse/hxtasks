(function () { "use strict";
var HxOverrides = function() { }
HxOverrides.__name__ = true;
HxOverrides.remove = function(a,obj) {
	var i = 0;
	var l = a.length;
	while(i < l) {
		if(a[i] == obj) {
			a.splice(i,1);
			return true;
		}
		i++;
	}
	return false;
}
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
	this.menu = js.App.J("#tmenu");
	this.lock = js.App.J("#lock");
	this.lock.remove();
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
	,menuAction: function(cur,act,param) {
		if(act == null) return;
		this.lock.click();
		switch(act) {
		case "prio":
			cur.priority = param;
			this.display();
			break;
		case "add":
			if(cur.subs == null) cur = this.parents.get(cur.id);
			var tnew = { id : -++js.App.UID, text : "", priority : 0, subs : null};
			this.opened.set(cur.id,true);
			cur.subs.push(tnew);
			this.display();
			this.editTask(tnew);
			break;
		case "delete":
			HxOverrides.remove(this.parents.get(cur.id).subs,cur);
			this.opened.remove(cur.id);
			this.display();
			break;
		case "rename":
			this.editTask(cur);
			break;
		case "move":
			HxOverrides.remove(this.parents.get(cur.id).subs,cur);
			this.alls.get(param).subs.push(cur);
			this.display();
			break;
		default:
			js.Lib.alert("Unknown " + act);
		}
	}
	,editTask: function(t) {
		var _g = this;
		var td = this.get(t);
		if(td.hasClass("edit")) return;
		var tf = js.App.J("<input>");
		td.addClass("edit").append(tf);
		var onBlur = function(e) {
			tf.remove();
			if(e != null) t.text = tf.val();
			td.find("div.desc").text(t.text);
			td.removeClass("edit");
			if(t.text == "" || e == null && t.id < 0) {
				HxOverrides.remove(_g.parents.get(t.id).subs,t);
				_g.display();
			}
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
	,showMenu: function(t) {
		var _g = this;
		var td = this.get(t);
		this.lock.click(function(_) {
			_g.menu.hide();
			_g.lock.remove();
		});
		this.lock.bind("contextmenu",function(_) {
			_g.lock.click();
			return false;
		});
		js.App.J("body").append(this.lock);
		var buildMenu = (function($this) {
			var $r;
			var buildMenu1 = null;
			buildMenu1 = function(subs) {
				var ul = js.App.J("<ul>").addClass("dropdown-menu");
				var hasContent = false;
				var _g1 = 0;
				while(_g1 < subs.length) {
					var t2 = subs[_g1];
					++_g1;
					if(t == t2 || t2.subs == null) continue;
					hasContent = true;
					var sub = buildMenu1(t2.subs);
					var li = js.App.J("<li>").append(js.App.J("<a>").data("menu","move").data("id","" + t2.id).attr("href","#").text(t2.text)).append(sub);
					if(sub != null) li.addClass("dropdown-submenu");
					ul.append(li);
				}
				return hasContent?ul:null;
			};
			$r = buildMenu1;
			return $r;
		}(this));
		td.append(this.menu);
		var move = this.menu.find("#moveTargets");
		move.children("ul").remove();
		move.append(buildMenu(this.root.subs));
		this.menu.find("a").click(function(e) {
			_g.menuAction(t,$(this).data("menu"),$(this).data("id"));
			e.stopPropagation();
		});
		this.menu.show(100);
	}
	,buildTask: function(t,parent) {
		var _g = this;
		var ico = js.App.J("<div>").addClass("i");
		var desc = js.App.J("<div>").addClass("desc").text(t.text);
		var content = js.App.J("<div>").append(ico).append(desc);
		var div = js.App.J("<div>").addClass("t").attr("id","_t" + t.id).addClass("p" + t.priority).append(content);
		var li = js.App.J("<li>").addClass("t").append(div);
		this.alls.set(t.id,t);
		content.mouseover(function(_) {
			div.addClass("over");
		});
		content.mouseout(function(_) {
			div.removeClass("over");
		});
		if(t.subs != null) {
			li.addClass("childs");
			if(!this.opened.get(t.id)) li.addClass("closed");
			li.append(this.buildChilds(t.subs,t));
			content.click((function(f,t1) {
				return function() {
					return f(t1);
				};
			})($bind(this,this.toggleTask),t));
		} else {
			li.addClass("nochilds");
			content.click((function(f1,t2) {
				return function() {
					return f1(t2);
				};
			})($bind(this,this.editTask),t));
		}
		content.bind("contextmenu",function(_) {
			_g.showMenu(t);
			return false;
		});
		return li;
	}
	,buildChilds: function(tl,parent) {
		var ul = js.App.J("<ul>").addClass("l");
		var _g = 0;
		while(_g < tl.length) {
			var t = tl[_g];
			++_g;
			this.parents.set(t.id,parent);
			ul.append(this.buildTask(t,parent));
		}
		return ul;
	}
	,display: function() {
		this.alls = new haxe.ds.IntMap();
		this.parents = new haxe.ds.IntMap();
		this.alls.set(0,this.root);
		var b = this.buildChilds(this.root.subs,this.root);
		js.App.J("#tasks").html("").append(b);
	}
	,load: function() {
		var id = 0;
		var make = function(t,subs) {
			return { id : id++, text : t, priority : 0, subs : subs};
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
js.Lib = function() { }
js.Lib.__name__ = true;
js.Lib.alert = function(v) {
	alert(js.Boot.__string_rec(v,""));
}
function $iterator(o) { if( o instanceof Array ) return function() { return HxOverrides.iter(o); }; return typeof(o.iterator) == 'function' ? $bind(o,o.iterator) : o.iterator; };
var $_;
function $bind(o,m) { var f = function(){ return f.method.apply(f.scope, arguments); }; f.scope = o; f.method = m; return f; };
if(Array.prototype.indexOf) HxOverrides.remove = function(a,o) {
	var i = a.indexOf(o);
	if(i == -1) return false;
	a.splice(i,1);
	return true;
}; else null;
String.__name__ = true;
Array.__name__ = true;
var q = window.jQuery;
js.JQuery = q;
js.App.UID = 0;
js.Browser.window = typeof window != "undefined" ? window : null;
js.App.main();
})();
