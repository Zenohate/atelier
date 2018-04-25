/**
Grimoire
Copyright (c) 2017 Enalye

This software is provided 'as-is', without any express or implied warranty.
In no event will the authors be held liable for any damages arising
from the use of this software.

Permission is granted to anyone to use this software for any purpose,
including commercial applications, and to alter it and redistribute
it freely, subject to the following restrictions:

	1. The origin of this software must not be misrepresented;
	   you must not claim that you wrote the original software.
	   If you use this software in a product, an acknowledgment
	   in the product documentation would be appreciated but
	   is not required.

	2. Altered source versions must be plainly marked as such,
	   and must not be misrepresented as being the original software.

	3. This notice may not be removed or altered from any source distribution.
*/

module ui.colorpicker;

import core.all;
import render.all;
import common.all;

import ui.all;

class ColorViewer: Widget {
	Color color;

	this() {}

	override void onEvent(Event event) {}
	override void update(float deltaTime) {}
	override void draw() {
		drawFilledRect(_position - _size / 2f, _size, color);
	}
}

class ColorPicker: ModalWindow {
	private {
		DropDownList _blendList;
		Slider _redSlider, _blueSlider, _greenSlider, _alphaSlider;
		ColorViewer _viewer;
	}

	@property {
		Color color() const {
			return Color(_redSlider.value01, _blueSlider.value01,
				_greenSlider.value01, _alphaSlider.value01);
		}

		Blend blend() const {
			switch(_blendList.selected) {
			case 0:
				return Blend.AlphaBlending;
			case 1:
				return Blend.AdditiveBlending;
			case 2:
				return Blend.ModularBlending;
			case 3:
				return Blend.NoBlending;
			default:
				throw new Exception("Invalid kind of blending");
			}
		}
	}

	this(Color newColor = Color.white, Blend newBlend = Blend.AlphaBlending) {
		Slider makeSlider(VContainer container, string title) {
			auto slider = new HSlider;
			slider.min = 0;
			slider.min = 255;
			slider.step = 255;
			slider.size = Vec2f(255f, 10f);

			auto hc = new HContainer;
			hc.padding = Vec2f(10f, 0f);
			hc.addChild(new Label(title));
			hc.addChild(slider);
			container.addChild(hc);
			return slider;
		}

		auto container = new VContainer;
		container.padding = Vec2f(0f, 10f);
		_redSlider = makeSlider(container, "R");
		_blueSlider = makeSlider(container, "G");
		_greenSlider = makeSlider(container, "B");
		_alphaSlider = makeSlider(container, "A");

		_blendList = new DropDownList(Vec2f(200f, 25f), 4U);
		foreach(mode; [
			"Alpha Blending", "Additive Blending",
			"Modular Blending", "No Blending"])
			_blendList.addChild(new TextButton(mode));
		container.addChild(_blendList);

		switch(newBlend) with(Blend) {
		case AlphaBlending:
			_blendList.selected = 0U;
			break;
		case AdditiveBlending:
			_blendList.selected = 1U;
			break;
		case ModularBlending:
			_blendList.selected = 2U;
			break;
		case NoBlending:
			_blendList.selected = 3U;
			break;
		default:
			_blendList.selected = 0U;
		}

		_redSlider.value01 = newColor.r;
		_blueSlider.value01 = newColor.g;
		_greenSlider.value01 = newColor.b;
		_alphaSlider.value01 = newColor.a;

		_viewer = new ColorViewer;
		_viewer.size = Vec2f(100f, 100f);

		auto hc2 = new HContainer;
		hc2.padding = Vec2f(20f, 5f);
		hc2.addChild(container);
		hc2.addChild(_viewer);

		super("Couleur", hc2.size);
		layout.addChild(hc2);
	}

	override void update(float deltaTime) {
		super.update(deltaTime);
		_viewer.color = color();
	}
}