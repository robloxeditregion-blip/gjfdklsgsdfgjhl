--[[
    SkeetUI v2 — gamesense/skeet style UI library for Roblox
    Элементы: Checkbox (+keybind ПКМ), Slider, Dropdown, MultiDropdown,
    ColorPicker (SV + Hue), Keybind, Button, Textbox, Label
    Анимации: TweenService (hover, fill, open/close, fade)
    Открытие/закрытие меню: RightShift
]]

local SkeetUI = { flags = {} }

local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")
local CoreGui          = game:GetService("CoreGui")

if CoreGui:FindFirstChild("SkeetUI") then CoreGui.SkeetUI:Destroy() end

local Colors = {
    Background      = Color3.fromRGB(17, 17, 17),
    Groupbox        = Color3.fromRGB(17, 17, 17),
    Element         = Color3.fromRGB(35, 35, 35),
    ElementHover    = Color3.fromRGB(45, 45, 45),
    OuterBorder     = Color3.fromRGB(0, 0, 0),
    MidBorder       = Color3.fromRGB(60, 60, 60),
    InnerBorder     = Color3.fromRGB(40, 40, 40),
    Text            = Color3.fromRGB(205, 205, 205),
    TextDark        = Color3.fromRGB(110, 110, 110),
    TextActive      = Color3.fromRGB(255, 255, 255),
    Accent          = Color3.fromRGB(149, 184, 66), -- фирменный skeet-зелёный
}

local FONT, TEXTSIZE = Enum.Font.Code, 12
local TWEEN_FAST  = TweenInfo.new(0.10, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TWEEN_MED   = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

-- ============ helpers ============
local function Create(class, props, parent)
    local obj = Instance.new(class)
    for k, v in pairs(props) do obj[k] = v end
    if parent then obj.Parent = parent end
    return obj
end

local function Tween(obj, props, info)
    local t = TweenService:Create(obj, info or TWEEN_FAST, props)
    t:Play()
    return t
end

-- классическая skeet-рамка: чёрный -> серый -> чёрный -> контент
local function TripleBorder(parent, size, pos)
    local outer = Create("Frame", {
        Size = size, Position = pos,
        BackgroundColor3 = Colors.OuterBorder, BorderSizePixel = 0,
    }, parent)
    local mid = Create("Frame", {
        Size = UDim2.new(1, -2, 1, -2), Position = UDim2.new(0, 1, 0, 1),
        BackgroundColor3 = Colors.MidBorder, BorderSizePixel = 0,
    }, outer)
    local inner = Create("Frame", {
        Size = UDim2.new(1, -2, 1, -2), Position = UDim2.new(0, 1, 0, 1),
        BackgroundColor3 = Colors.OuterBorder, BorderSizePixel = 0,
    }, mid)
    local content = Create("Frame", {
        Size = UDim2.new(1, -2, 1, -2), Position = UDim2.new(0, 1, 0, 1),
        BackgroundColor3 = Colors.Background, BorderSizePixel = 0,
    }, inner)
    return outer, content
end

local function Label(parent, text, props)
    local l = Create("TextLabel", {
        BackgroundTransparency = 1, Text = text,
        TextColor3 = Colors.Text, TextSize = TEXTSIZE, Font = FONT,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, parent)
    for k, v in pairs(props or {}) do l[k] = v end
    return l
end

-- ============ window ============
function SkeetUI:CreateWindow(titleText)
    local Window = { Tabs = {}, CurrentTab = nil, Open = true }

    local ScreenGui = Create("ScreenGui", {
        Name = "SkeetUI", ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Global,
    }, CoreGui)

    -- слой для выпадающих списков/пикеров поверх всего
    local Overlay = Create("Frame", {
        Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, ZIndex = 100,
    }, ScreenGui)

    local Root, Main = TripleBorder(ScreenGui,
        UDim2.new(0, 560, 0, 480), UDim2.new(0.5, -280, 0.5, -240))

    -- лёгкий вертикальный градиент фона как у skeet
    Create("UIGradient", {
        Rotation = 90,
        Color = ColorSequence.new(Color3.fromRGB(25, 25, 25), Color3.fromRGB(12, 12, 12)),
    }, Main)

    -- фирменная градиентная полоса сверху
    local TopLine = Create("Frame", {
        Size = UDim2.new(1, 0, 0, 2), BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0, ZIndex = 2,
    }, Main)
    Create("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0.00, Color3.fromRGB(59, 175, 222)),
            ColorSequenceKeypoint.new(0.25, Color3.fromRGB(102, 211, 111)),
            ColorSequenceKeypoint.new(0.50, Color3.fromRGB(201, 227, 88)),
            ColorSequenceKeypoint.new(0.75, Color3.fromRGB(202, 70, 205)),
            ColorSequenceKeypoint.new(1.00, Color3.fromRGB(59, 175, 222)),
        }),
    }, TopLine)
    -- анимация переливания градиента
    task.spawn(function()
        local g = TopLine:FindFirstChildOfClass("UIGradient")
        while TopLine.Parent do
            g.Offset = Vector2.new((tick() * 0.15) % 1, 0)
            task.wait()
        end
    end)

    -- drag за верхнюю зону
    do
        local dragging, dragStart, startPos
        Main.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
            and input.Position.Y - Main.AbsolutePosition.Y < 30 then
                dragging, dragStart, startPos = true, input.Position, Root.Position
            end
        end)
        UserInputService.InputEnded:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
        end)
        UserInputService.InputChanged:Connect(function(i)
            if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
                local d = i.Position - dragStart
                Root.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X,
                                          startPos.Y.Scale, startPos.Y.Offset + d.Y)
            end
        end)
    end

    Label(Main, titleText or "skeet.cc", {
        Size = UDim2.new(0, 200, 0, 24), Position = UDim2.new(0, 10, 0, 4),
        TextColor3 = Colors.TextActive, ZIndex = 2,
    })

    -- вертикальная колонка табов слева (как у gamesense)
    local TabColumn = Create("Frame", {
        Size = UDim2.new(0, 76, 1, -34), Position = UDim2.new(0, 0, 0, 30),
        BackgroundColor3 = Color3.fromRGB(12, 12, 12), BorderSizePixel = 0,
    }, Main)
    Create("Frame", { -- разделитель
        Size = UDim2.new(0, 1, 1, 0), Position = UDim2.new(1, 0, 0, 0),
        BackgroundColor3 = Colors.MidBorder, BorderSizePixel = 0,
    }, TabColumn)
    local TabLayout = Create("UIListLayout", {
        Padding = UDim.new(0, 0), SortOrder = Enum.SortOrder.LayoutOrder,
    }, TabColumn)
    Create("UIPadding", { PaddingTop = UDim.new(0, 10) }, TabColumn)

    local ContentArea = Create("Frame", {
        Size = UDim2.new(1, -89, 1, -44), Position = UDim2.new(0, 83, 0, 36),
        BackgroundTransparency = 1,
    }, Main)

    -- открытие/закрытие меню
    UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if input.KeyCode == Enum.KeyCode.RightShift then
            Window.Open = not Window.Open
            Root.Visible = true
            if Window.Open then
                Root.Size = UDim2.new(0, 560, 0, 0)
                Tween(Root, { Size = UDim2.new(0, 560, 0, 480) }, TWEEN_MED)
            else
                Tween(Root, { Size = UDim2.new(0, 560, 0, 0) }, TWEEN_MED)
                    .Completed:Wait()
                Root.Visible = false
                Overlay.Visible = false
            end
        end
    end)

    -- ============ dropdown overlay manager ============
    local currentPopup
    local function ClosePopup()
        if currentPopup then currentPopup:Destroy() currentPopup = nil end
    end
    UserInputService.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 and currentPopup then
            local p, s = currentPopup.AbsolutePosition, currentPopup.AbsoluteSize
            local m = UserInputService:GetMouseLocation()
            if m.X < p.X or m.X > p.X + s.X or m.Y < p.Y or m.Y > p.Y + s.Y - 36 then
                task.wait() ClosePopup()
            end
        end
    end)

    -- ============ tabs ============
    function Window:CreateTab(tabName)
        local Tab = {}

        local TabBtn = Create("TextButton", {
            Size = UDim2.new(1, 0, 0, 34), BackgroundColor3 = Color3.fromRGB(12, 12, 12),
            BorderSizePixel = 0, Text = tabName, AutoButtonColor = false,
            TextColor3 = Colors.TextDark, TextSize = TEXTSIZE, Font = FONT,
        }, TabColumn)
        local ActiveBar = Create("Frame", {
            Size = UDim2.new(0, 2, 1, 0), BackgroundColor3 = Colors.Accent,
            BorderSizePixel = 0, BackgroundTransparency = 1,
        }, TabBtn)

        local TabPage = Create("Frame", {
            Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Visible = false,
        }, ContentArea)

        -- две колонки groupbox'ов
        local columns = {}
        for i = 1, 2 do
            local col = Create("ScrollingFrame", {
                Size = UDim2.new(0.5, -4, 1, 0),
                Position = UDim2.new((i - 1) * 0.5, (i - 1) * 4, 0, 0),
                BackgroundTransparency = 1, BorderSizePixel = 0,
                ScrollBarThickness = 2, ScrollBarImageColor3 = Colors.MidBorder,
                CanvasSize = UDim2.new(0, 0, 0, 0),
            }, TabPage)
            local lay = Create("UIListLayout", { Padding = UDim.new(0, 10) }, col)
            lay:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                col.CanvasSize = UDim2.new(0, 0, 0, lay.AbsoluteContentSize.Y + 10)
            end)
            columns[i] = col
        end

        local function Select()
            for _, p in pairs(ContentArea:GetChildren()) do p.Visible = false end
            for _, b in pairs(TabColumn:GetChildren()) do
                if b:IsA("TextButton") then
                    Tween(b, { TextColor3 = Colors.TextDark,
                               BackgroundColor3 = Color3.fromRGB(12, 12, 12) })
                    Tween(b:FindFirstChild("Frame"), { BackgroundTransparency = 1 })
                end
            end
            TabPage.Visible = true
            Tween(TabBtn, { TextColor3 = Colors.TextActive,
                            BackgroundColor3 = Colors.Background })
            Tween(ActiveBar, { BackgroundTransparency = 0 })
            Window.CurrentTab = TabPage
            ClosePopup()
        end

        TabBtn.MouseEnter:Connect(function()
            if Window.CurrentTab ~= TabPage then
                Tween(TabBtn, { TextColor3 = Colors.Text })
            end
        end)
        TabBtn.MouseLeave:Connect(function()
            if Window.CurrentTab ~= TabPage then
                Tween(TabBtn, { TextColor3 = Colors.TextDark })
            end
        end)
        TabBtn.MouseButton1Click:Connect(Select)
        if not Window.CurrentTab then Select() end

        -- ============ groupbox / section ============
        function Tab:CreateSection(sectionName, side) -- side: 1 = левая, 2 = правая
            local Section = {}
            local parentCol = columns[side == 2 and 2 or 1]

            local Outer, Inner = TripleBorder(parentCol,
                UDim2.new(1, -6, 0, 40), UDim2.new(0, 0, 0, 0))
            Inner.BackgroundColor3 = Colors.Groupbox
            Create("UIGradient", {
                Rotation = 90,
                Color = ColorSequence.new(Color3.fromRGB(24, 24, 24), Color3.fromRGB(14, 14, 14)),
            }, Inner)

            Label(Inner, " " .. sectionName .. " ", {
                Position = UDim2.new(0, 10, 0, -7), Size = UDim2.new(0, 10, 0, 13),
                AutomaticSize = Enum.AutomaticSize.X,
                BackgroundColor3 = Color3.fromRGB(24, 24, 24),
                BackgroundTransparency = 0, BorderSizePixel = 0, ZIndex = 3,
                TextColor3 = Colors.TextActive,
            })

            local Holder = Create("Frame", {
                Size = UDim2.new(1, -20, 1, -24), Position = UDim2.new(0, 10, 0, 16),
                BackgroundTransparency = 1,
            }, Inner)
            local Layout = Create("UIListLayout", {
                Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder,
            }, Holder)
            Layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                Outer.Size = UDim2.new(1, -6, 0, Layout.AbsoluteContentSize.Y + 30)
            end)

            -- ---------- checkbox (с кейбиндом по ПКМ) ----------
            function Section:AddCheckbox(text, default, cb)
                local state = default or false
                local bindKey, bindListening = nil, false
                SkeetUI.flags[text] = state

                local Row = Create("TextButton", {
                    Size = UDim2.new(1, 0, 0, 13), BackgroundTransparency = 1,
                    Text = "", AutoButtonColor = false,
                }, Holder)
                local BoxOut = Create("Frame", {
                    Size = UDim2.new(0, 9, 0, 9), Position = UDim2.new(0, 0, 0, 2),
                    BackgroundColor3 = Colors.OuterBorder, BorderSizePixel = 0,
                }, Row)
                local BoxIn = Create("Frame", {
                    Size = UDim2.new(1, -2, 1, -2), Position = UDim2.new(0, 1, 0, 1),
                    BackgroundColor3 = Colors.Element, BorderSizePixel = 0,
                }, BoxOut)
                Create("UIGradient", {
                    Rotation = 90,
                    Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(150, 150, 150)),
                }, BoxIn)
                local Lbl = Label(Row, text, {
                    Size = UDim2.new(1, -60, 1, 0), Position = UDim2.new(0, 16, 0, 0),
                })
                local BindLbl = Label(Row, "", {
                    Size = UDim2.new(0, 40, 1, 0), Position = UDim2.new(1, -40, 0, 0),
                    TextXAlignment = Enum.TextXAlignment.Right, TextColor3 = Colors.TextDark,
                })

                local function apply(fire)
                    Tween(BoxIn, { BackgroundColor3 = state and Colors.Accent or Colors.Element })
                    Tween(Lbl, { TextColor3 = state and Colors.TextActive or Colors.Text })
                    SkeetUI.flags[text] = state
                    if fire and cb then cb(state) end
                end

                Row.MouseEnter:Connect(function()
                    if not state then Tween(BoxIn, { BackgroundColor3 = Colors.ElementHover }) end
                end)
                Row.MouseLeave:Connect(function()
                    if not state then Tween(BoxIn, { BackgroundColor3 = Colors.Element }) end
                end)
                Row.MouseButton1Click:Connect(function()
                    state = not state
                    apply(true)
                end)
                -- ПКМ — назначить бинд
                Row.MouseButton2Click:Connect(function()
                    bindListening = true
                    BindLbl.Text = "[...]"
                end)
                UserInputService.InputBegan:Connect(function(input, gpe)
                    if bindListening and input.UserInputType == Enum.UserInputType.Keyboard then
                        bindKey = input.KeyCode ~= Enum.KeyCode.Escape and input.KeyCode or nil
                        BindLbl.Text = bindKey and ("[" .. bindKey.Name .. "]") or ""
                        bindListening = false
                    elseif not gpe and bindKey and input.KeyCode == bindKey then
                        state = not state
                        apply(true)
                    end
                end)
                apply(false)

                local api = {}
                function api:Set(v) state = v apply(true) end
                function api:Get() return state end
                return api
            end

            -- ---------- slider ----------
            function Section:AddSlider(text, min, max, default, suffix, cb)
                local val = math.clamp(default or min, min, max)
                suffix = suffix or ""
                SkeetUI.flags[text] = val

                local Frame = Create("Frame", {
                    Size = UDim2.new(1, 0, 0, 28), BackgroundTransparency = 1,
                }, Holder)
                local Lbl = Label(Frame, text, { Size = UDim2.new(1, 0, 0, 13) })
                local BarOut = Create("Frame", {
                    Size = UDim2.new(1, 0, 0, 9), Position = UDim2.new(0, 0, 0, 17),
                    BackgroundColor3 = Colors.OuterBorder, BorderSizePixel = 0,
                }, Frame)
                local BarIn = Create("Frame", {
                    Size = UDim2.new(1, -2, 1, -2), Position = UDim2.new(0, 1, 0, 1),
                    BackgroundColor3 = Colors.Element, BorderSizePixel = 0,
                    ClipsDescendants = true,
                }, BarOut)
                local Fill = Create("Frame", {
                    Size = UDim2.new((val - min) / (max - min), 0, 1, 0),
                    BackgroundColor3 = Colors.Accent, BorderSizePixel = 0,
                }, BarIn)
                Create("UIGradient", {
                    Rotation = 90,
                    Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(160, 160, 160)),
                }, Fill)
                local ValLbl = Create("TextLabel", {
                    Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1,
                    Text = tostring(val) .. suffix, TextColor3 = Colors.TextActive,
                    TextSize = 10, Font = FONT, ZIndex = 3,
                }, BarOut)

                local dragging = false
                local function update(x, fire)
                    local pct = math.clamp((x - BarIn.AbsolutePosition.X) / BarIn.AbsoluteSize.X, 0, 1)
                    val = math.floor((min + (max - min) * pct) + 0.5)
                    pct = (val - min) / (max - min)
                    Tween(Fill, { Size = UDim2.new(pct, 0, 1, 0) })
                    ValLbl.Text = tostring(val) .. suffix
                    SkeetUI.flags[text] = val
                    if fire and cb then cb(val) end
                end

                BarOut.InputBegan:Connect(function(i)
                    if i.UserInputType == Enum.UserInputType.MouseButton1 then
                        dragging = true
                        update(i.Position.X, true)
                    end
                end)
                UserInputService.InputEnded:Connect(function(i)
                    if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
                end)
                UserInputService.InputChanged:Connect(function(i)
                    if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
                        update(i.Position.X, true)
                    end
                end)

                local api = {}
                function api:Set(v)
                    val = math.clamp(v, min, max)
                    Tween(Fill, { Size = UDim2.new((val - min) / (max - min), 0, 1, 0) })
                    ValLbl.Text = tostring(val) .. suffix
                    if cb then cb(val) end
                end
                function api:Get() return val end
                return api
            end

            -- ---------- dropdown (общая база для single/multi) ----------
            local function BaseDropdown(text, opts, multi, default, cb)
                local selected = multi and (default or {}) or (default or opts[1])

                local Frame = Create("Frame", {
                    Size = UDim2.new(1, 0, 0, 34), BackgroundTransparency = 1,
                }, Holder)
                Label(Frame, text, { Size = UDim2.new(1, 0, 0, 13) })
                local BtnOut = Create("Frame", {
                    Size = UDim2.new(1, 0, 0, 18), Position = UDim2.new(0, 0, 0, 16),
                    BackgroundColor3 = Colors.OuterBorder, BorderSizePixel = 0,
                }, Frame)
                local Btn = Create("TextButton", {
                    Size = UDim2.new(1, -2, 1, -2), Position = UDim2.new(0, 1, 0, 1),
                    BackgroundColor3 = Colors.Element, BorderSizePixel = 0,
                    Text = "", AutoButtonColor = false,
                }, BtnOut)
                Create("UIGradient", {
                    Rotation = 90,
                    Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(180, 180, 180)),
                }, Btn)
                local SelLbl = Label(Btn, "", {
                    Size = UDim2.new(1, -24, 1, 0), Position = UDim2.new(0, 6, 0, 0),
                    TextTruncate = Enum.TextTruncate.AtEnd,
                })
                local Arrow = Label(Btn, "▼", {
                    Size = UDim2.new(0, 14, 1, 0), Position = UDim2.new(1, -16, 0, 0),
                    TextColor3 = Colors.TextDark, TextSize = 8,
                    TextXAlignment = Enum.TextXAlignment.Center,
                })

                local function refreshText()
                    if multi then
                        local t = {}
                        for _, o in ipairs(opts) do
                            if selected[o] then table.insert(t, o) end
                        end
                        SelLbl.Text = #t > 0 and table.concat(t, ", ") or "-"
                    else
                        SelLbl.Text = tostring(selected)
                    end
                end
                refreshText()

                Btn.MouseEnter:Connect(function() Tween(Btn, { BackgroundColor3 = Colors.ElementHover }) end)
                Btn.MouseLeave:Connect(function() Tween(Btn, { BackgroundColor3 = Colors.Element }) end)

                Btn.MouseButton1Click:Connect(function()
                    if currentPopup then ClosePopup() return end
                    Arrow.Text = "▲"
                    local absP, absS = BtnOut.AbsolutePosition, BtnOut.AbsoluteSize
                    local listH = math.min(#opts, 8) * 18 + 2

                    local Pop = Create("Frame", {
                        Position = UDim2.new(0, absP.X, 0, absP.Y + absS.Y + 1),
                        Size = UDim2.new(0, absS.X, 0, 0),
                        BackgroundColor3 = Colors.OuterBorder, BorderSizePixel = 0,
                        ClipsDescendants = true, ZIndex = 100,
                    }, Overlay)
                    Tween(Pop, { Size = UDim2.new(0, absS.X, 0, listH) }, TWEEN_MED)
                    Pop.Destroying:Connect(function() Arrow.Text = "▼" end)

                    local List = Create("ScrollingFrame", {
                        Size = UDim2.new(1, -2, 1, -2), Position = UDim2.new(0, 1, 0, 1),
                        BackgroundColor3 = Colors.Element, BorderSizePixel = 0,
                        ScrollBarThickness = 2, ZIndex = 100,
                        CanvasSize = UDim2.new(0, 0, 0, #opts * 18),
                    }, Pop)
                    Create("UIListLayout", {}, List)

                    for _, opt in ipairs(opts) do
                        local isSel = multi and selected[opt] or (selected == opt)
                        local OptBtn = Create("TextButton", {
                            Size = UDim2.new(1, 0, 0, 18), BackgroundColor3 = Colors.Element,
                            BorderSizePixel = 0, AutoButtonColor = false,
                            Text = "  " .. opt, TextSize = TEXTSIZE, Font = FONT,
                            TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 101,
                            TextColor3 = isSel and Colors.Accent or Colors.TextDark,
                        }, List)
                        OptBtn.MouseEnter:Connect(function()
                            Tween(OptBtn, { BackgroundColor3 = Colors.ElementHover })
                        end)
                        OptBtn.MouseLeave:Connect(function()
                            Tween(OptBtn, { BackgroundColor3 = Colors.Element })
                        end)
                        OptBtn.MouseButton1Click:Connect(function()
                            if multi then
                                selected[opt] = not selected[opt] or nil
                                OptBtn.TextColor3 = selected[opt] and Colors.Accent or Colors.TextDark
                                refreshText()
                                if cb then cb(selected) end
                            else
                                selected = opt
                                refreshText()
                                ClosePopup()
                                if cb then cb(opt) end
                            end
                            SkeetUI.flags[text] = selected
                        end)
                    end
                    currentPopup = Pop
                end)

                local api = {}
                function api:Get() return selected end
                function api:Set(v) selected = v refreshText() if cb then cb(v) end end
                return api
            end

            function Section:AddDropdown(text, opts, default, cb)
                return BaseDropdown(text, opts, false, default, cb)
            end
            function Section:AddMultiDropdown(text, opts, default, cb)
                return BaseDropdown(text, opts, true, default, cb)
            end

            -- ---------- color picker (SV-квадрат + hue) ----------
            function Section:AddColorPicker(text, defaultColor, cb)
                local h, s, v = (defaultColor or Colors.Accent):ToHSV()

                local Row = Create("Frame", {
                    Size = UDim2.new(1, 0, 0, 13), BackgroundTransparency = 1,
                }, Holder)
                Label(Row, text, { Size = UDim2.new(1, -32, 1, 0) })
                local SwOut = Create("Frame", {
                    Size = UDim2.new(0, 24, 0, 11), Position = UDim2.new(1, -24, 0, 1),
                    BackgroundColor3 = Colors.OuterBorder, BorderSizePixel = 0,
                }, Row)
                local Swatch = Create("TextButton", {
                    Size = UDim2.new(1, -2, 1, -2), Position = UDim2.new(0, 1, 0, 1),
                    BackgroundColor3 = Color3.fromHSV(h, s, v), BorderSizePixel = 0,
                    Text = "", AutoButtonColor = false,
                }, SwOut)
                Create("UIGradient", {
                    Rotation = 90,
                    Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(170, 170, 170)),
                }, Swatch)

                local function fire()
                    local c = Color3.fromHSV(h, s, v)
                    Swatch.BackgroundColor3 = c
                    SkeetUI.flags[text] = c
                    if cb then cb(c) end
                end

                Swatch.MouseButton1Click:Connect(function()
                    if currentPopup then ClosePopup() return end
                    local absP = SwOut.AbsolutePosition

                    local Pop = Create("Frame", {
                        Position = UDim2.new(0, absP.X - 150 + 24, 0, absP.Y + 14),
                        Size = UDim2.new(0, 150, 0, 0),
                        BackgroundColor3 = Colors.OuterBorder, BorderSizePixel = 0,
                        ClipsDescendants = true, ZIndex = 100,
                    }, Overlay)
                    Tween(Pop, { Size = UDim2.new(0, 150, 0, 132) }, TWEEN_MED)

                    local Inner = Create("Frame", {
                        Size = UDim2.new(1, -2, 1, -2), Position = UDim2.new(0, 1, 0, 1),
                        BackgroundColor3 = Colors.Background, BorderSizePixel = 0, ZIndex = 100,
                    }, Pop)

                    -- SV square
                    local SV = Create("TextButton", {
                        Size = UDim2.new(1, -12, 0, 100), Position = UDim2.new(0, 6, 0, 6),
                        BackgroundColor3 = Color3.fromHSV(h, 1, 1), BorderSizePixel = 0,
                        Text = "", AutoButtonColor = false, ZIndex = 101,
                    }, Inner)
                    local WhiteOv = Create("Frame", {
                        Size = UDim2.new(1, 0, 1, 0), BorderSizePixel = 0,
                        BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 102,
                    }, SV)
                    Create("UIGradient", {
                        Transparency = NumberSequence.new(0, 1),
                    }, WhiteOv)
                    local BlackOv = Create("Frame", {
                        Size = UDim2.new(1, 0, 1, 0), BorderSizePixel = 0,
                        BackgroundColor3 = Color3.new(0, 0, 0), ZIndex = 103,
                    }, SV)
                    Create("UIGradient", {
                        Rotation = 90, Transparency = NumberSequence.new(1, 0),
                    }, BlackOv)
                    local SVCursor = Create("Frame", {
                        Size = UDim2.new(0, 3, 0, 3), BorderSizePixel = 1,
                        BorderColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 1,
                        Position = UDim2.new(s, -1, 1 - v, -1), ZIndex = 104,
                    }, SV)

                    -- hue bar
                    local Hue = Create("TextButton", {
                        Size = UDim2.new(1, -12, 0, 12), Position = UDim2.new(0, 6, 0, 112),
                        BorderSizePixel = 0, Text = "", AutoButtonColor = false, ZIndex = 101,
                        BackgroundColor3 = Color3.new(1, 1, 1),
                    }, Inner)
                    local hueKeys = {}
                    for i = 0, 6 do
                        table.insert(hueKeys, ColorSequenceKeypoint.new(i / 6, Color3.fromHSV(i / 6, 1, 1)))
                    end
                    Create("UIGradient", { Color = ColorSequence.new(hueKeys) }, Hue)
                    local HueCursor = Create("Frame", {
                        Size = UDim2.new(0, 2, 1, 0), Position = UDim2.new(h, -1, 0, 0),
                        BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, ZIndex = 102,
                    }, Hue)

                    local dragSV, dragHue = false, false
                    SV.InputBegan:Connect(function(i)
                        if i.UserInputType == Enum.UserInputType.MouseButton1 then dragSV = true end
                    end)
                    Hue.InputBegan:Connect(function(i)
                        if i.UserInputType == Enum.UserInputType.MouseButton1 then dragHue = true end
                    end)
                    UserInputService.InputEnded:Connect(function(i)
                        if i.UserInputType == Enum.UserInputType.MouseButton1 then
                            dragSV, dragHue = false, false
                        end
                    end)
                    RunService.RenderStepped:Connect(function()
                        if not Pop.Parent then return end
                        local m = UserInputService:GetMouseLocation()
                        if dragSV then
                            s = math.clamp((m.X - SV.AbsolutePosition.X) / SV.AbsoluteSize.X, 0, 1)
                            v = 1 - math.clamp((m.Y - 36 - SV.AbsolutePosition.Y) / SV.AbsoluteSize.Y, 0, 1)
                            SVCursor.Position = UDim2.new(s, -1, 1 - v, -1)
                            fire()
                        elseif dragHue then
                            h = math.clamp((m.X - Hue.AbsolutePosition.X) / Hue.AbsoluteSize.X, 0, 1)
                            HueCursor.Position = UDim2.new(h, -1, 0, 0)
                            SV.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
                            fire()
                        end
                    end)

                    currentPopup = Pop
                end)

                local api = {}
                function api:Get() return Color3.fromHSV(h, s, v) end
                function api:Set(c) h, s, v = c:ToHSV() fire() end
                return api
            end

            -- ---------- keybind ----------
            function Section:AddKeybind(text, defaultKey, cb)
                local key, listening = defaultKey, false
                local Row = Create("Frame", {
                    Size = UDim2.new(1, 0, 0, 15), BackgroundTransparency = 1,
                }, Holder)
                Label(Row, text, { Size = UDim2.new(1, -60, 1, 0) })
                local BtnOut = Create("Frame", {
                    Size = UDim2.new(0, 54, 0, 15), Position = UDim2.new(1, -54, 0, 0),
                    BackgroundColor3 = Colors.OuterBorder, BorderSizePixel = 0,
                }, Row)
                local Btn = Create("TextButton", {
                    Size = UDim2.new(1, -2, 1, -2), Position = UDim2.new(0, 1, 0, 1),
                    BackgroundColor3 = Colors.Element, BorderSizePixel = 0,
                    Text = key and key.Name or "none", AutoButtonColor = false,
                    TextColor3 = Colors.TextDark, TextSize = 10, Font = FONT,
                }, BtnOut)
                Btn.MouseEnter:Connect(function() Tween(Btn, { BackgroundColor3 = Colors.ElementHover }) end)
                Btn.MouseLeave:Connect(function() Tween(Btn, { BackgroundColor3 = Colors.Element }) end)
                Btn.MouseButton1Click:Connect(function()
                    listening = true
                    Btn.Text = "..."
                    Tween(Btn, { TextColor3 = Colors.Accent })
                end)
                UserInputService.InputBegan:Connect(function(input, gpe)
                    if listening and input.UserInputType == Enum.UserInputType.Keyboard then
                        key = input.KeyCode ~= Enum.KeyCode.Escape and input.KeyCode or nil
                        Btn.Text = key and key.Name or "none"
                        Tween(Btn, { TextColor3 = Colors.TextDark })
                        listening = false
                    elseif not gpe and key and input.KeyCode == key then
                        if cb then cb(key) end
                    end
                end)
            end

            -- ---------- button ----------
            function Section:AddButton(text, cb)
                local Out = Create("Frame", {
                    Size = UDim2.new(1, 0, 0, 20), BackgroundColor3 = Colors.OuterBorder,
                    BorderSizePixel = 0,
                }, Holder)
                local Btn = Create("TextButton", {
                    Size = UDim2.new(1, -2, 1, -2), Position = UDim2.new(0, 1, 0, 1),
                    BackgroundColor3 = Colors.Element, BorderSizePixel = 0,
                    Text = text, TextColor3 = Colors.Text, TextSize = TEXTSIZE,
                    Font = FONT, AutoButtonColor = false,
                }, Out)
                Create("UIGradient", {
                    Rotation = 90,
                    Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(180, 180, 180)),
                }, Btn)
                Btn.MouseEnter:Connect(function() Tween(Btn, { BackgroundColor3 = Colors.ElementHover }) end)
                Btn.MouseLeave:Connect(function() Tween(Btn, { BackgroundColor3 = Colors.Element }) end)
                Btn.MouseButton1Down:Connect(function()
                    Tween(Btn, { BackgroundColor3 = Colors.Background })
                end)
                Btn.MouseButton1Click:Connect(function()
                    Tween(Btn, { BackgroundColor3 = Colors.ElementHover })
                    if cb then cb() end
                end)
            end

            -- ---------- textbox ----------
            function Section:AddTextbox(text, placeholder, cb)
                local Frame = Create("Frame", {
                    Size = UDim2.new(1, 0, 0, 34), BackgroundTransparency = 1,
                }, Holder)
                Label(Frame, text, { Size = UDim2.new(1, 0, 0, 13) })
                local Out = Create("Frame", {
                    Size = UDim2.new(1, 0, 0, 18), Position = UDim2.new(0, 0, 0, 16),
                    BackgroundColor3 = Colors.OuterBorder, BorderSizePixel = 0,
                }, Frame)
                local Box = Create("TextBox", {
                    Size = UDim2.new(1, -2, 1, -2), Position = UDim2.new(0, 1, 0, 1),
                    BackgroundColor3 = Colors.Element, BorderSizePixel = 0,
                    Text = "", PlaceholderText = placeholder or "...",
                    PlaceholderColor3 = Colors.TextDark, TextColor3 = Colors.Text,
                    TextSize = TEXTSIZE, Font = FONT, ClearTextOnFocus = false,
                    TextXAlignment = Enum.TextXAlignment.Left,
                }, Out)
                Create("UIPadding", { PaddingLeft = UDim.new(0, 6) }, Box)
                Box.Focused:Connect(function() Tween(Out, { BackgroundColor3 = Colors.Accent }) end)
                Box.FocusLost:Connect(function()
                    Tween(Out, { BackgroundColor3 = Colors.OuterBorder })
                    SkeetUI.flags[text] = Box.Text
                    if cb then cb(Box.Text) end
                end)
            end

            -- ---------- label ----------
            function Section:AddLabel(text)
                local l = Label(Holder, text, {
                    Size = UDim2.new(1, 0, 0, 13), TextColor3 = Colors.TextDark,
                })
                local api = {}
                function api:Set(t) l.Text = t end
                return api
            end

            return Section
        end
        return Tab
    end
    return Window
end

return SkeetUI
