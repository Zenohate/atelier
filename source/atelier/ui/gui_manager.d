module atelier.ui.gui_manager;

import std.conv: to;
import atelier.core, atelier.common, atelier.render;
import atelier.ui.gui_element, atelier.ui.gui_overlay;

private {
	bool _isGuiElementDebug = false;
    GuiElement[] _rootGuis;
    float _deltaTime;
}

//Public
void addRootGui(GuiElement widget) {
	_rootGuis ~= widget;
}

void removeRootGuis() {
	//_isChildGrabbed = false;
	_rootGuis.length = 0uL;
}

void setRootGuis(GuiElement[] widgets) {
	_rootGuis = widgets;
}

GuiElement[] getRootGuis() {
    return _rootGuis;
}

void setDebugGui(bool isDebug) {
	_isGuiElementDebug = isDebug;
}

//Internal
void updateGuiElements(float deltaTime) {
    _deltaTime = deltaTime;
    foreach(GuiElement widget; _rootGuis) {
        updateGuiElements(widget, null);
    }
}

void drawGuiElements() {
    foreach_reverse(GuiElement widget; _rootGuis) {
        drawGuiElements(widget);
    }
}

private {
    bool _hasClicked, _wasHoveredGuiElementAlreadyHovered;
    GuiElement _clickedGuiElement;
    GuiElement _focusedGuiElement;
    GuiElement _hoveredGuiElement;
    Canvas _canvas;
    Vec2f _clickedGuiElementEventPosition = Vec2f.zero;
    Vec2f _hoveredGuiElementEventPosition = Vec2f.zero;
    GuiElement[] _hookedGuis;
}

void handleGuiElementEvent(Event event) {
    if(isOverlay()) {
        processOverlayEvent(event);
    }

    _hasClicked = false;
    switch (event.type) with(EventType) {
    case MouseDown:
        dispatchMouseDownEvent(null, event.position);

        if(_hasClicked && _clickedGuiElement !is null) {
            _clickedGuiElement.isClicked = true;
            Event guiEvent = EventType.MouseDown;
            guiEvent.position = _clickedGuiElementEventPosition;
            _clickedGuiElement.onEvent(guiEvent);
        }
        break;
    case MouseUp:
        dispatchMouseUpEvent(null, event.position);
        break;
    case MouseUpdate:
        _hookedGuis.length = 0;
        dispatchMouseUpdateEvent(null, event.position);

        if(_hasClicked && _hoveredGuiElement !is null) {
            _hoveredGuiElement.isHovered = true;

            if(!_wasHoveredGuiElementAlreadyHovered)
                _hoveredGuiElement.onHover();

            //Compatibility
            Event guiEvent = EventType.MouseUpdate;
            guiEvent.position = _hoveredGuiElementEventPosition;
            _hoveredGuiElement.onEvent(guiEvent);
        }
        break;
    case MouseWheel:
        dispatchMouseWheelEvent(event.position);
        break;
    case Quit:
        dispatchQuitEvent(null);
        break;
    default:
        dispatchGenericEvents(null, event);
        break;
    }    
}

void updateGuiElements(GuiElement gui, GuiElement parent) {
    Vec2f coords = Vec2f.zero;

    //Calculate transitions
    if(gui._timer.isRunning) {
        gui._timer.update(_deltaTime);
        const float t = gui._targetState.easingFunction(gui._timer.time);
        gui._currentState.offset = lerp(
            gui._initState.offset,
            gui._targetState.offset,
            t
        );

        gui._currentState.scale = lerp(
            gui._initState.scale,
            gui._targetState.scale,
            t
        );

        gui._currentState.color = lerp(
            gui._initState.color,
            gui._targetState.color,
            t
        );

        gui._currentState.angle = lerp(
            gui._initState.angle,
            gui._targetState.angle,
            t
        );
    }

    //Calculate gui location
    const Vec2f offset = gui._position + (gui._size / 2f) + gui._currentState.offset;
    if(parent !is null) {
        if(parent.hasCanvas && parent.canvas !is null) {
            if(gui._alignX == GuiAlignX.Left)
                coords.x = offset.x;
            else if(gui._alignX == GuiAlignX.Right)
                coords.x = parent._size.x - offset.x;
            else
                coords.x = parent._size.x / 2f + gui._currentState.offset.x;

            if(gui._alignY == GuiAlignY.Top)
                coords.y = offset.y;
            else if(gui._alignY == GuiAlignY.Bottom)
                coords.y = parent._size.y - offset.y;
            else
                coords.y = parent._size.y / 2f + gui._currentState.offset.y;
        }
        else {
            if(gui._alignX == GuiAlignX.Left)
                coords.x = parent.origin.x + offset.x;
            else if(gui._alignX == GuiAlignX.Right)
                coords.x = parent.origin.x + parent._size.x - offset.x;
            else
                coords.x = parent.center.x + gui._currentState.offset.x;

            if(gui._alignY == GuiAlignY.Top)
                coords.y = parent.origin.y + offset.y;
            else if(gui._alignY == GuiAlignY.Bottom)
                coords.y = parent.origin.y + parent._size.y - offset.y;
            else
                coords.y = parent.center.y + gui._currentState.offset.y;
        }
    }
    else {
        if(gui._alignX == GuiAlignX.Left)
            coords.x = offset.x;
        else if(gui._alignX == GuiAlignX.Right)
            coords.x = screenWidth - offset.x;
        else
            coords.x = centerScreen.x + gui._currentState.offset.x;

        if(gui._alignY == GuiAlignY.Top)
            coords.y = offset.y;
        else if(gui._alignY == GuiAlignY.Bottom)
            coords.y = screenHeight - offset.y;
        else
            coords.y = centerScreen.y + gui._currentState.offset.y;
    }
    gui.setScreenCoords(coords);
    gui.update(_deltaTime);

    foreach(GuiElement child; gui.children) {
        updateGuiElements(child, gui);
    }
}

void drawGuiElements(GuiElement gui) {
    if(gui.hasCanvas && gui.canvas !is null) {
        auto canvas = gui.canvas;
        canvas.setColorMod(gui._currentState.color, Blend.AlphaBlending);
        pushCanvas(canvas, true);
        gui.draw();
        foreach(GuiElement child; gui.children) {
            drawGuiElements(child);
        }
        popCanvas();
        canvas.draw(gui._screenCoords);
        const auto origin = gui._origin;
        const auto center = gui._center;
        gui._origin = gui._screenCoords - gui._size / 2f;
        gui._center = gui._screenCoords;
        gui.drawOverlay();
        gui._origin = origin;
        gui._center = center;
        if(gui.isHovered && gui.hint !is null)
			openHintWindow(gui.hint);
    }
    else {
        gui.draw();
        foreach(GuiElement child; gui.children) {
            drawGuiElements(child);
        }
        gui.drawOverlay();
        if(gui.isHovered && gui.hint !is null)
			openHintWindow(gui.hint);
    }
    if(_isGuiElementDebug) {
        drawRect(gui.center - gui._size / 2f, gui._size,
            gui.children.length ? Color.blue : Color.green);
    }
}

private void dispatchMouseDownEvent(GuiElement gui, Vec2f cursorPosition) {
    auto children = (gui is null) ? _rootGuis : gui.children;
    bool hasCanvas;

    if(gui !is null) {
        if(gui.isInteractable && gui.isInside(cursorPosition)) {
            _clickedGuiElement = gui;

            if(gui.hasCanvas && gui.canvas !is null) {
                hasCanvas = true;
                pushCanvas(gui.canvas, false);
                cursorPosition = transformCanvasSpace(cursorPosition, gui._screenCoords);
            }

            _clickedGuiElementEventPosition = cursorPosition;
            _hasClicked = true;

            if(gui._hasEventHook) {
                Event guiEvent = EventType.MouseDown;
                guiEvent.position = cursorPosition;
                gui.onEvent(guiEvent);
            }
        }
        else
            return;
    }
    
    foreach(child; children)
        dispatchMouseDownEvent(child, cursorPosition);

    if(hasCanvas)
        popCanvas();
}

private void dispatchMouseUpEvent(GuiElement gui, Vec2f cursorPosition) {
    auto children = (gui is null) ? _rootGuis : gui.children;
    bool hasCanvas;

    if(gui !is null) {
        if(gui.isInteractable && gui.isInside(cursorPosition)) {
            if(gui.hasCanvas && gui.canvas !is null) {
                hasCanvas = true;
                pushCanvas(gui.canvas, false);
                cursorPosition = transformCanvasSpace(cursorPosition, gui._screenCoords);
            }

            if(gui._hasEventHook) {
                Event guiEvent = EventType.MouseUp;
                guiEvent.position = cursorPosition;
                gui.onEvent(guiEvent);
            }
        }
        else
            return;
    }
    
    foreach(child; children)
        dispatchMouseUpEvent(child, cursorPosition);

    if(hasCanvas)
        popCanvas();
    
    if(gui !is null && _clickedGuiElement == gui) {
        //The previous widget is now unfocused.
        if(_focusedGuiElement !is null) {
            _focusedGuiElement.hasFocus = false;
        }

        //The widget is now focused and receive the onSubmit event.
        _focusedGuiElement = _clickedGuiElement;
        _hasClicked = true;
        gui.hasFocus = true;
        gui.onSubmit();

        //Compatibility
        Event event = EventType.MouseUp;
        event.position = cursorPosition;
        gui.onEvent(event);
    }
    if(_clickedGuiElement !is null)
        _clickedGuiElement.isClicked = false;
}

private void dispatchMouseUpdateEvent(GuiElement gui, Vec2f cursorPosition) {
    auto children = (gui is null) ? _rootGuis : gui.children;
    bool hasCanvas, wasHovered;

    if(gui !is null) {
        wasHovered = gui.isHovered;
        gui.isHovered = false;
        if(gui.isInteractable && gui.isInside(cursorPosition)) {
            if(gui.hasCanvas && gui.canvas !is null) {
                hasCanvas = true;
                pushCanvas(gui.canvas, false);
                cursorPosition = transformCanvasSpace(cursorPosition, gui._screenCoords);
            }

            //Register gui
            _wasHoveredGuiElementAlreadyHovered = wasHovered;
            _hoveredGuiElement = gui;
            _hoveredGuiElementEventPosition = cursorPosition;
            _hasClicked = true;

            if(gui._hasEventHook) {
                Event guiEvent = EventType.MouseUpdate;
                guiEvent.position = cursorPosition;
                gui.onEvent(guiEvent);
                _hookedGuis ~= gui;
            }
        }
        else {
            void unHoverGuiElements(GuiElement gui) {
                gui.isHovered = false;
                foreach(child; gui.children)
                    unHoverGuiElements(child);
            }
            unHoverGuiElements(gui);
            return;
        }
    }
    
    foreach(child; children)
        dispatchMouseUpdateEvent(child, cursorPosition);

    if(hasCanvas)
        popCanvas();
}

private void dispatchMouseWheelEvent(Vec2f scroll) {
    Event scrollEvent = EventType.MouseWheel;
    scrollEvent.position = scroll;

    foreach(gui; _hookedGuis) {
        gui.onEvent(scrollEvent);
    }

    if(_clickedGuiElement !is null) {
        if(_clickedGuiElement.isClicked) {
            _clickedGuiElement.onEvent(scrollEvent);
            return;
        }
    }
    if(_hoveredGuiElement !is null) {
        _hoveredGuiElement.onEvent(scrollEvent);
        return;
    }
}

private void dispatchQuitEvent(GuiElement gui) {
    if(gui !is null) {
        foreach(GuiElement child; gui.children)
            dispatchQuitEvent(child);
        gui.onQuit();
    }
    else {
        foreach(GuiElement widget; _rootGuis)
            dispatchQuitEvent(widget);
    }
}

private void dispatchGenericEvents(GuiElement gui, Event event) {
    if(gui !is null) {
        gui.onEvent(event);
        foreach(GuiElement child; gui.children) {
            dispatchGenericEvents(child, event);
        }
    }
    else {
        foreach(GuiElement widget; _rootGuis) {
            dispatchGenericEvents(widget, event);
        }
    }
}
/*
private void handleGuiElementEvents(GuiElement gui) {
    switch (event.type) with(EventType) {
    case MouseDown:
        bool hasClickedGuiElement;
        foreach(uint id, GuiElement widget; _children) {
            widget.hasFocus = false;
            if(!widget.isInteractable)
                continue;

            if(!hasClickedGuiElement && widget.isInside(_isFrame ? transformCanvasSpace(event.position, _position) : event.position)) {
                widget.hasFocus = true;
                widget.isSelected = true;
                widget.isHovered = true;
                _isChildGrabbed = true;
                _idChildGrabbed = id;

                if(_isFrame)
                    event.position = transformCanvasSpace(event.position, _position);
                widget.onEvent(event);
                hasClickedGuiElement = true;
            }
        }

        if(!_isChildGrabbed && _isMovable) {
            _isGrabbed = true;
            _lastMousePos = event.position;
        }
        break;
    case MouseUp:
        if(_isChildGrabbed) {
            _isChildGrabbed = false;
            _children[_idChildGrabbed].isSelected = false;

            if(_isFrame)
                event.position = transformCanvasSpace(event.position, _position);
            _children[_idChildGrabbed].onEvent(event);
        }
        else {
            _isGrabbed = false;
        }
        break;
    case MouseUpdate:
        _isIterating = false; //Use mouse control
        Vec2f mousePosition = event.position;
        if(_isFrame)
            event.position = transformCanvasSpace(event.position, _position);

        _isChildHovered = false;
        foreach(uint id, GuiElement widget; _children) {
            if(isHovered) {
                widget.isHovered = widget.isInside(event.position);
                if(widget.isHovered && widget.isInteractable) {
                    _isChildHovered = true;
                    widget.onEvent(event);
                }
            }
            else
                widget.isHovered = false;
        }

        if(_isChildGrabbed && !_children[_idChildGrabbed].isHovered)
            _children[_idChildGrabbed].onEvent(event);
        else if(_isGrabbed && _isMovable) {
            Vec2f deltaPosition = (mousePosition - _lastMousePos);
            if(!_isFrame) {
                //Clamp the window in the screen
                if(isModal()) {
                    Vec2f halfSize = _size / 2f;
                    Vec2f clampedPosition = _position.clamp(halfSize, screenSize - halfSize);
                    deltaPosition += (clampedPosition - _position);
                }
                _position += deltaPosition;

                foreach(widget; _children)
                    widget.position = widget.position + deltaPosition;
            }
            else
                _position += deltaPosition;
            _lastMousePos = mousePosition;
        }
        break;
    case MouseWheel:
        foreach(uint id, GuiElement widget; _children) {
            if(widget.isHovered)
                widget.onEvent(event);
        }

        if(_isChildGrabbed && !_children[_idChildGrabbed].isHovered)
            _children[_idChildGrabbed].onEvent(event);
        break;
    default:
        foreach(GuiElement widget; _children)
            widget.onEvent(event);
        break;
    }
}*/