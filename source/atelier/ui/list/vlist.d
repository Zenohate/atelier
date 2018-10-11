/**
    Vertical list

    Copyright: (c) Enalye 2017
    License: Zlib
    Authors: Enalye
*/

module atelier.ui.list.vlist;

import std.conv: to;

import atelier.core;
import atelier.render;
import atelier.common;

import atelier.ui;

private class ListContainer: WidgetGroup {
	public {
		View view;
		VLayout layout;
	}

	this(Vec2f size) {
		createGui(size);
	}

	override void onEvent(Event event) {
		pushView(view, false);
		super.onEvent(event);
		popView();
	}

	override void update(float deltaTime) {
		pushView(view, false);
		super.update(deltaTime);
		popView();
	}

	override void draw() {
		pushView(view, true);
		super.draw();
		popView();
		view.draw(_position);
	}

	protected void createGui(Vec2f newSize) {
		_isFrame = true;
		isLocked = true;
		layout = new VLayout;
		view = new View(to!Vec2u(newSize));
		view.position = Vec2f.zero;
		size(newSize);
		addChild(layout);
	}
}

class VList: WidgetGroup {
	protected {
		ListContainer _container;
		Slider _slider;
		Vec2f _lastMousePos = Vec2f.zero;
		float _layoutLength = 25f;
		uint _nbElements = 0u;
		uint _idElementSelected = 0u;
	}

	@property {
		uint selected() const { return _idElementSelected; }
		uint selected(uint id) {
			if(id > _nbElements)
				throw new Exception("VList: index out of bounds");
			_idElementSelected = id;
			return _idElementSelected;
		}

		float layoutLength() const { return _layoutLength; }
		float layoutLength(float length) {
			_layoutLength = length;
			_container.layout.size = Vec2f(_size.x, _layoutLength * _nbElements);
			return _layoutLength;
		}
	}

	this(Vec2f newSize) {
		isLocked = true;
		_slider = new VScrollbar;
		_container = new ListContainer(newSize);

		super.addChild(_slider);
		super.addChild(_container);

		size(newSize);
		position(Vec2f.zero);
	}

	override void onEvent(Event event) {
		super.onEvent(event);
		if(event.type == EventType.MouseDown || event.type == EventType.MouseUp || event.type == EventType.MouseUpdate) {
			if(_slider.isInside(event.position))
				_slider.onEvent(event);
			else if(event.type == EventType.MouseDown) {

				auto widgets = _container.layout.children;
				foreach(uint id, ref Widget widget; _container.layout.children) {
					widget.isValidated = false;
					if(widget.isHovered)
						_idElementSelected = id;
				}
				if(_idElementSelected < widgets.length)
					widgets[_idElementSelected].isValidated = true;
			}
		}

		if(!isOnInteractableWidget(_lastMousePos) && event.type == EventType.MouseWheel)
			_slider.onEvent(event);
	}

    override void onPosition() {
        auto offset = _size * (.5f - _anchor);
        _slider.position = _position - Vec2f((_size.x - _slider.size.x) / 2f, 0f) + offset;
        _container.position = _position + Vec2f(_slider.size.x / 2f, 0f) + offset;
    }

    override void onSize() {
        _slider.size = Vec2f(10f, _size.y);
        _container.layout.size = Vec2f(_size.x, _layoutLength * _nbElements);
        _container.size = Vec2f(_size.x - _slider.size.x, _size.y);
        _container.view.renderSize = _container.size.to!Vec2u;
        onPosition();
    }

	override void update(float deltaTime) {
		super.update(deltaTime);
		float min = _container.view.size.y / 2f;
		float max = _container.layout.size.y - _container.view.size.y / 2f;
		float exceedingHeight = _container.layout.size.y - _container.view.size.y;

		if(exceedingHeight < 0f) {
			_slider.max = 0;
			_slider.step = 0;
		}
		else {
			_slider.max = exceedingHeight / _layoutLength;
			_slider.step = to!uint(_slider.max);
		}
		_container.view.position = Vec2f(0f, lerp(min, max, _slider.offset));
	}

	override void addChild(Widget widget) {
		widget.isValidated = (_nbElements == 0u);

		_nbElements ++;
		_container.layout.size = Vec2f(size.x, _layoutLength * _nbElements);
		_container.layout.position = Vec2f(0f, _container.layout.size.y / 2f);
		_container.layout.addChild(widget);
	}

	override void removeChildren() {
		_nbElements = 0u;
		_idElementSelected = 0u;
		_container.layout.size = Vec2f(size.x, 0f);
		_container.layout.position = Vec2f.zero;
		_container.layout.removeChildren();
	}

	override void removeChild(uint id) {
		_container.layout.removeChild(id);
		_nbElements = _container.layout.getChildrenCount();
		_idElementSelected = 0u;
		_container.layout.size = Vec2f(size.x, _layoutLength * _nbElements);
		_container.layout.position = Vec2f(0f, _container.layout.size.y / 2f);
	}

	override int getChildrenCount() {
		return _container.layout.getChildrenCount();	
	}

	Widget[] getList() {
		return _container.layout.children;
	}
}

