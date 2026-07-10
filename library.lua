local SkeetUI = {}
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")

if CoreGui:FindFirstChild("SkeetUI") then CoreGui.SkeetUI:Destroy() end

local Colors = {
    Background = Color3.fromRGB(23, 23, 23),
    InnerBackground = Color3.fromRGB(30, 30, 30),
    OuterBorder = Color3.fromRGB(0, 0, 0),
    InnerBorder = Color3.fromRGB(45, 45, 45),
    Text = Color3.fromRGB(255, 255, 255),
    TextDark = Color3.fromRGB(150, 150, 150),
    Accent = Color3.fromRGB(143, 197, 8)
}

function SkeetUI:CreateWindow(titleText)
    local Window = {Tabs = {}, CurrentTab = nil}
    local ScreenGui = Instance.new("ScreenGui", CoreGui)
    ScreenGui.Name = "SkeetUI"
    ScreenGui.ResetOnSpawn = false

    local MainBorder = Instance.new("Frame", ScreenGui)
    MainBorder.Size = UDim2.new(0, 500, 0, 450)
    MainBorder.Position = UDim2.new(0.5, -250, 0.5, -225)
    MainBorder.BackgroundColor3 = Colors.OuterBorder
    MainBorder.BorderSizePixel = 0

    local dragInput, dragStart, startPos
    MainBorder.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragStart, startPos = input.Position, MainBorder.Position
            input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragStart = nil end end)
        end
    end)
    MainBorder.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then dragInput = input end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragStart then
            local delta = input.Position - dragStart
            MainBorder.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)

    local MainFrame = Instance.new("Frame", MainBorder)
    MainFrame.Size = UDim2.new(1, -2, 1, -2)
    MainFrame.Position = UDim2.new(0, 1, 0, 1)
    MainFrame.BackgroundColor3 = Colors.Background
    MainFrame.BorderColor3 = Colors.InnerBorder
    MainFrame.BorderSizePixel = 1

    local TopLine = Instance.new("Frame", MainFrame)
    TopLine.Size = UDim2.new(1, 0, 0, 2)
    TopLine.BorderSizePixel = 0
    local Gradient = Instance.new("UIGradient", TopLine)
    Gradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0.00, Color3.fromRGB(59, 175, 222)),
        ColorSequenceKeypoint.new(0.50, Color3.fromRGB(202, 70, 205)),
        ColorSequenceKeypoint.new(1.00, Color3.fromRGB(201, 227, 88))
    }

    local TabContainer = Instance.new("Frame", MainFrame)
    TabContainer.Size = UDim2.new(1, -12, 0, 20)
    TabContainer.Position = UDim2.new(0, 6, 0, 8)
    TabContainer.BackgroundTransparency = 1
    local TabLayout = Instance.new("UIListLayout", TabContainer)
    TabLayout.FillDirection = Enum.FillDirection.Horizontal
    TabLayout.Padding = UDim.new(0, 2)

    local ContentOuter = Instance.new("Frame", MainFrame)
    ContentOuter.Size = UDim2.new(1, -12, 1, -38)
    ContentOuter.Position = UDim2.new(0, 6, 0, 32)
    ContentOuter.BackgroundColor3 = Colors.OuterBorder
    ContentOuter.BorderSizePixel = 0

    local ContentInner = Instance.new("Frame", ContentOuter)
    ContentInner.Size = UDim2.new(1, -2, 1, -2)
    ContentInner.Position = UDim2.new(0, 1, 0, 1)
    ContentInner.BackgroundColor3 = Colors.Background
    ContentInner.BorderColor3 = Colors.InnerBorder
    ContentInner.BorderSizePixel = 1

    function Window:CreateTab(tabName)
        local Tab = {}
        local TabBtn = Instance.new("TextButton", TabContainer)
        TabBtn.Size = UDim2.new(0, 80, 1, 0)
        TabBtn.BackgroundColor3 = Colors.Background
        TabBtn.BorderColor3 = Colors.InnerBorder
        TabBtn.BorderSizePixel = 1
        TabBtn.Text = tabName
        TabBtn.TextColor3 = Colors.TextDark
        TabBtn.TextSize = 11
        TabBtn.Font = Enum.Font.Code

        local TabPage = Instance.new("ScrollingFrame", ContentInner)
        TabPage.Size = UDim2.new(1, -10, 1, -10)
        TabPage.Position = UDim2.new(0, 5, 0, 5)
        TabPage.BackgroundTransparency = 1
        TabPage.ScrollBarThickness = 2
        TabPage.BorderSizePixel = 0
        TabPage.Visible = false
        local PageLayout = Instance.new("UIListLayout", TabPage)
        PageLayout.Padding = UDim.new(0, 10)

        if not Window.CurrentTab then
            Window.CurrentTab = TabPage
            TabPage.Visible = true
            TabBtn.TextColor3 = Colors.Text
        end

        TabBtn.MouseButton1Click:Connect(function()
            for _, page in pairs(ContentInner:GetChildren()) do if page:IsA("ScrollingFrame") then page.Visible = false end end
            for _, btn in pairs(TabContainer:GetChildren()) do if btn:IsA("TextButton") then btn.TextColor3 = Colors.TextDark end end
            TabPage.Visible = true
            TabBtn.TextColor3 = Colors.Text
        end)

        function Tab:CreateSection(sectionName)
            local Section = {}
            local SectionOuter = Instance.new("Frame", TabPage)
            SectionOuter.Size = UDim2.new(1, -4, 0, 20)
            SectionOuter.BackgroundColor3 = Colors.OuterBorder
            SectionOuter.BorderSizePixel = 0

            local SectionInner = Instance.new("Frame", SectionOuter)
            SectionInner.Size = UDim2.new(1, -2, 1, -2)
            SectionInner.Position = UDim2.new(0, 1, 0, 1)
            SectionInner.BackgroundColor3 = Colors.InnerBackground
            SectionInner.BorderColor3 = Colors.InnerBorder
            SectionInner.BorderSizePixel = 1

            local Title = Instance.new("TextLabel", SectionInner)
            Title.Size = UDim2.new(1, -10, 0, 14)
            Title.Position = UDim2.new(0, 5, 0, -7)
            Title.BackgroundColor3 = Colors.Background
            Title.Text = " " .. sectionName .. " "
            Title.TextColor3 = Colors.Text
            Title.TextSize = 11
            Title.Font = Enum.Font.Code
            Title.AutomaticSize = Enum.AutomaticSize.X

            local Layout = Instance.new("UIListLayout", SectionInner)
            Layout.Padding = UDim.new(0, 8)
            local Pad = Instance.new("UIPadding", SectionInner)
            Pad.PaddingTop = UDim.new(0, 15)
            Pad.PaddingLeft = UDim.new(0, 8)
            Pad.PaddingRight = UDim.new(0, 8)
            Pad.PaddingBottom = UDim.new(0, 8)

            Layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                SectionOuter.Size = UDim2.new(1, -4, 0, Layout.AbsoluteContentSize.Y + 25)
                TabPage.CanvasSize = UDim2.new(0, 0, 0, PageLayout.AbsoluteContentSize.Y + 10)
            end)

            function Section:CreateToggle(text, cb)
                local toggled = false
                local Btn = Instance.new("TextButton", SectionInner)
                Btn.Size = UDim2.new(1, 0, 0, 12)
                Btn.BackgroundTransparency = 1
                Btn.Text = ""
                local Box = Instance.new("Frame", Btn)
                Box.Size = UDim2.new(0, 12, 0, 12)
                Box.BackgroundColor3 = Colors.OuterBorder
                local BoxIn = Instance.new("Frame", Box)
                BoxIn.Size = UDim2.new(1, -2, 1, -2)
                BoxIn.Position = UDim2.new(0, 1, 0, 1)
                BoxIn.BackgroundColor3 = Colors.InnerBackground
                local Lbl = Instance.new("TextLabel", Btn)
                Lbl.Size = UDim2.new(1, -20, 1, 0)
                Lbl.Position = UDim2.new(0, 20, 0, 0)
                Lbl.BackgroundTransparency = 1
                Lbl.Text = text
                Lbl.TextColor3 = Colors.Text
                Lbl.TextSize = 11
                Lbl.Font = Enum.Font.Code
                Lbl.TextXAlignment = Enum.TextXAlignment.Left
                Btn.MouseButton1Click:Connect(function()
                    toggled = not toggled
                    BoxIn.BackgroundColor3 = toggled and Colors.Accent or Colors.InnerBackground
                    if cb then cb(toggled) end
                end)
            end

            function Section:CreateSlider(text, min, max, def, cb)
                local val = def or min
                local Frame = Instance.new("Frame", SectionInner)
                Frame.Size = UDim2.new(1, 0, 0, 30)
                Frame.BackgroundTransparency = 1
                local Lbl = Instance.new("TextLabel", Frame)
                Lbl.Size = UDim2.new(1, 0, 0, 14)
                Lbl.BackgroundTransparency = 1
                Lbl.Text = text .. " : " .. val
                Lbl.TextColor3 = Colors.Text
                Lbl.TextSize = 11
                Lbl.Font = Enum.Font.Code
                Lbl.TextXAlignment = Enum.TextXAlignment.Left
                local SliderOut = Instance.new("Frame", Frame)
                SliderOut.Size = UDim2.new(1, 0, 0, 10)
                SliderOut.Position = UDim2.new(0, 0, 0, 18)
                SliderOut.BackgroundColor3 = Colors.OuterBorder
                local SliderIn = Instance.new("TextButton", SliderOut)
                SliderIn.Size = UDim2.new(1, -2, 1, -2)
                SliderIn.Position = UDim2.new(0, 1, 0, 1)
                SliderIn.BackgroundColor3 = Colors.InnerBackground
                SliderIn.Text = ""
                local Fill = Instance.new("Frame", SliderIn)
                Fill.Size = UDim2.new((val - min)/(max - min), 0, 1, 0)
                Fill.BackgroundColor3 = Colors.Accent
                Fill.BorderSizePixel = 0
                local drag = false
                SliderIn.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then drag = true end end)
                UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then drag = false end end)
                UserInputService.InputChanged:Connect(function(i)
                    if drag and i.UserInputType == Enum.UserInputType.MouseMovement then
                        local pct = math.clamp((i.Position.X - SliderIn.AbsolutePosition.X) / SliderIn.AbsoluteSize.X, 0, 1)
                        val = math.floor(min + (max - min) * pct)
                        Fill.Size = UDim2.new(pct, 0, 1, 0)
                        Lbl.Text = text .. " : " .. val
                        if cb then cb(val) end
                    end
                end)
            end

            function Section:CreateDropdown(text, opts, cb)
                local Frame = Instance.new("Frame", SectionInner)
                Frame.Size = UDim2.new(1, 0, 0, 35)
                Frame.BackgroundTransparency = 1
                local Lbl = Instance.new("TextLabel", Frame)
                Lbl.Size = UDim2.new(1, 0, 0, 14)
                Lbl.BackgroundTransparency = 1
                Lbl.Text = text
                Lbl.TextColor3 = Colors.Text
                Lbl.TextSize = 11
                Lbl.Font = Enum.Font.Code
                Lbl.TextXAlignment = Enum.TextXAlignment.Left
                
                local DropOut = Instance.new("Frame", Frame)
                DropOut.Size = UDim2.new(1, 0, 0, 20)
                DropOut.Position = UDim2.new(0, 0, 0, 15)
                DropOut.BackgroundColor3 = Colors.OuterBorder
                local MainBtn = Instance.new("TextButton", DropOut)
                MainBtn.Size = UDim2.new(1, -2, 1, -2)
                MainBtn.Position = UDim2.new(0, 1, 0, 1)
                MainBtn.BackgroundColor3 = Colors.InnerBackground
                MainBtn.Text = "  " .. tostring(opts[1])
                MainBtn.TextColor3 = Colors.Text
                MainBtn.TextSize = 11
                MainBtn.Font = Enum.Font.Code
                MainBtn.TextXAlignment = Enum.TextXAlignment.Left
                
                local ListOut = Instance.new("Frame", DropOut)
                ListOut.Size = UDim2.new(1, 0, 0, #opts * 20 + 2)
                ListOut.Position = UDim2.new(0, 0, 1, 1)
                ListOut.BackgroundColor3 = Colors.OuterBorder
                ListOut.Visible = false
                ListOut.ZIndex = 5
                local ListIn = Instance.new("Frame", ListOut)
                ListIn.Size = UDim2.new(1, -2, 1, -2)
                ListIn.Position = UDim2.new(0, 1, 0, 1)
                ListIn.BackgroundColor3 = Colors.InnerBackground
                ListIn.ZIndex = 5
                Instance.new("UIListLayout", ListIn)
                
                MainBtn.MouseButton1Click:Connect(function() ListOut.Visible = not ListOut.Visible end)
                for _, opt in pairs(opts) do
                    local OptBtn = Instance.new("TextButton", ListIn)
                    OptBtn.Size = UDim2.new(1, 0, 0, 20)
                    OptBtn.BackgroundTransparency = 1
                    OptBtn.Text = "  " .. opt
                    OptBtn.TextColor3 = Colors.TextDark
                    OptBtn.TextSize = 11
                    OptBtn.Font = Enum.Font.Code
                    OptBtn.TextXAlignment = Enum.TextXAlignment.Left
                    OptBtn.ZIndex = 6
                    OptBtn.MouseButton1Click:Connect(function()
                        MainBtn.Text = "  " .. opt
                        ListOut.Visible = false
                        if cb then cb(opt) end
                    end)
                end
            end

            function Section:CreateColorPicker(text, defaultColor, cb)
                local Frame = Instance.new("Frame", SectionInner)
                Frame.Size = UDim2.new(1, 0, 0, 20)
                Frame.BackgroundTransparency = 1
                
                local Lbl = Instance.new("TextLabel", Frame)
                Lbl.Size = UDim2.new(1, -30, 1, 0)
                Lbl.BackgroundTransparency = 1
                Lbl.Text = text
                Lbl.TextColor3 = Colors.Text
                Lbl.TextSize = 11
                Lbl.Font = Enum.Font.Code
                Lbl.TextXAlignment = Enum.TextXAlignment.Left
                
                local ColorBtnOut = Instance.new("Frame", Frame)
                ColorBtnOut.Size = UDim2.new(0, 30, 0, 14)
                ColorBtnOut.Position = UDim2.new(1, -30, 0, 3)
                ColorBtnOut.BackgroundColor3 = Colors.OuterBorder
                local ColorBtn = Instance.new("TextButton", ColorBtnOut)
                ColorBtn.Size = UDim2.new(1, -2, 1, -2)
                ColorBtn.Position = UDim2.new(0, 1, 0, 1)
                ColorBtn.BackgroundColor3 = defaultColor
                ColorBtn.Text = ""
                
                -- Inline RGB Sliders directly into the section automatically
                local r, g, b = defaultColor.R*255, defaultColor.G*255, defaultColor.B*255
                
                local function updateCol()
                    local c = Color3.fromRGB(r, g, b)
                    ColorBtn.BackgroundColor3 = c
                    if cb then cb(c) end
                end
                
                Section:CreateSlider(text.." R", 0, 255, r, function(v) r=v updateCol() end)
                Section:CreateSlider(text.." G", 0, 255, g, function(v) g=v updateCol() end)
                Section:CreateSlider(text.." B", 0, 255, b, function(v) b=v updateCol() end)
            end

            function Section:CreateButton(text, cb)
                local Out = Instance.new("Frame", SectionInner)
                Out.Size = UDim2.new(1, 0, 0, 20)
                Out.BackgroundColor3 = Colors.OuterBorder
                local Btn = Instance.new("TextButton", Out)
                Btn.Size = UDim2.new(1, -2, 1, -2)
                Btn.Position = UDim2.new(0, 1, 0, 1)
                Btn.BackgroundColor3 = Colors.InnerBackground
                Btn.Text = text
                Btn.TextColor3 = Colors.Text
                Btn.TextSize = 11
                Btn.Font = Enum.Font.Code
                Btn.MouseButton1Click:Connect(function() if cb then cb() end end)
            end
            return Section
        end
        return Tab
    end
    return Window
end
return SkeetUI
