local SkeetUI = {}
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")

-- Удаление старого UI (удобно при перезапуске скрипта)
if CoreGui:FindFirstChild("SkeetUI") then
    CoreGui.SkeetUI:Destroy()
end

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
    local Window = {}
    Window.Tabs = {}
    Window.CurrentTab = nil

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "SkeetUI"
    ScreenGui.Parent = CoreGui
    ScreenGui.ResetOnSpawn = false

    -- Главное окно
    local MainBorder = Instance.new("Frame")
    MainBorder.Size = UDim2.new(0, 500, 0, 450)
    MainBorder.Position = UDim2.new(0.5, -250, 0.5, -225)
    MainBorder.BackgroundColor3 = Colors.OuterBorder
    MainBorder.BorderSizePixel = 0
    MainBorder.Parent = ScreenGui

    -- Драг (перемещение окна)
    local dragInput, dragStart, startPos
    MainBorder.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragStart = input.Position
            startPos = MainBorder.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragStart = nil end
            end)
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

    local MainFrame = Instance.new("Frame")
    MainFrame.Size = UDim2.new(1, -2, 1, -2)
    MainFrame.Position = UDim2.new(0, 1, 0, 1)
    MainFrame.BackgroundColor3 = Colors.Background
    MainFrame.BorderColor3 = Colors.InnerBorder
    MainFrame.BorderSizePixel = 1
    MainFrame.Parent = MainBorder

    -- Skeet Gradient Line
    local TopLine = Instance.new("Frame")
    TopLine.Size = UDim2.new(1, 0, 0, 2)
    TopLine.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    TopLine.BorderSizePixel = 0
    TopLine.Parent = MainFrame

    local Gradient = Instance.new("UIGradient")
    Gradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0.00, Color3.fromRGB(59, 175, 222)),
        ColorSequenceKeypoint.new(0.50, Color3.fromRGB(202, 70, 205)),
        ColorSequenceKeypoint.new(1.00, Color3.fromRGB(201, 227, 88))
    }
    Gradient.Parent = TopLine

    -- Контейнеры для вкладок и контента
    local TabContainer = Instance.new("Frame")
    TabContainer.Size = UDim2.new(1, -12, 0, 20)
    TabContainer.Position = UDim2.new(0, 6, 0, 8)
    TabContainer.BackgroundTransparency = 1
    TabContainer.Parent = MainFrame

    local TabLayout = Instance.new("UIListLayout")
    TabLayout.FillDirection = Enum.FillDirection.Horizontal
    TabLayout.SortOrder = Enum.SortOrder.LayoutOrder
    TabLayout.Padding = UDim.new(0, 2)
    TabLayout.Parent = TabContainer

    local ContentContainerOuter = Instance.new("Frame")
    ContentContainerOuter.Size = UDim2.new(1, -12, 1, -38)
    ContentContainerOuter.Position = UDim2.new(0, 6, 0, 32)
    ContentContainerOuter.BackgroundColor3 = Colors.OuterBorder
    ContentContainerOuter.BorderSizePixel = 0
    ContentContainerOuter.Parent = MainFrame

    local ContentContainer = Instance.new("Frame")
    ContentContainer.Size = UDim2.new(1, -2, 1, -2)
    ContentContainer.Position = UDim2.new(0, 1, 0, 1)
    ContentContainer.BackgroundColor3 = Colors.Background
    ContentContainer.BorderColor3 = Colors.InnerBorder
    ContentContainer.BorderSizePixel = 1
    ContentContainer.Parent = ContentContainerOuter

    -- Создание вкладки
    function Window:CreateTab(tabName)
        local Tab = {}
        
        local TabButton = Instance.new("TextButton")
        TabButton.Size = UDim2.new(0, 70, 1, 0)
        TabButton.BackgroundColor3 = Colors.Background
        TabButton.BorderColor3 = Colors.InnerBorder
        TabButton.BorderSizePixel = 1
        TabButton.Text = tabName
        TabButton.TextColor3 = Colors.TextDark
        TabButton.TextSize = 11
        TabButton.Font = Enum.Font.Code
        TabButton.Parent = TabContainer

        local TabPage = Instance.new("ScrollingFrame")
        TabPage.Size = UDim2.new(1, -10, 1, -10)
        TabPage.Position = UDim2.new(0, 5, 0, 5)
        TabPage.BackgroundTransparency = 1
        TabPage.ScrollBarThickness = 2
        TabPage.BorderSizePixel = 0
        TabPage.Visible = false
        TabPage.Parent = ContentContainer

        local PageLayout = Instance.new("UIListLayout")
        PageLayout.SortOrder = Enum.SortOrder.LayoutOrder
        PageLayout.Padding = UDim.new(0, 10)
        PageLayout.Parent = TabPage

        if not Window.CurrentTab then
            Window.CurrentTab = TabPage
            TabPage.Visible = true
            TabButton.TextColor3 = Colors.Text
        end

        TabButton.MouseButton1Click:Connect(function()
            for _, page in pairs(ContentContainer:GetChildren()) do
                if page:IsA("ScrollingFrame") then page.Visible = false end
            end
            for _, btn in pairs(TabContainer:GetChildren()) do
                if btn:IsA("TextButton") then btn.TextColor3 = Colors.TextDark end
            end
            TabPage.Visible = true
            TabButton.TextColor3 = Colors.Text
        end)

        -- Создание секции
        function Tab:CreateSection(sectionName)
            local Section = {}
            
            local SectionOuter = Instance.new("Frame")
            SectionOuter.Size = UDim2.new(1, -4, 0, 20)
            SectionOuter.BackgroundColor3 = Colors.OuterBorder
            SectionOuter.BorderSizePixel = 0
            SectionOuter.Parent = TabPage

            local SectionInner = Instance.new("Frame")
            SectionInner.Size = UDim2.new(1, -2, 1, -2)
            SectionInner.Position = UDim2.new(0, 1, 0, 1)
            SectionInner.BackgroundColor3 = Colors.InnerBackground
            SectionInner.BorderColor3 = Colors.InnerBorder
            SectionInner.BorderSizePixel = 1
            SectionInner.Parent = SectionOuter

            local SectionTitle = Instance.new("TextLabel")
            SectionTitle.Size = UDim2.new(1, -10, 0, 14)
            SectionTitle.Position = UDim2.new(0, 5, 0, -7)
            SectionTitle.BackgroundColor3 = Colors.Background
            SectionTitle.Text = " " .. sectionName .. " "
            SectionTitle.TextColor3 = Colors.Text
            SectionTitle.TextSize = 11
            SectionTitle.Font = Enum.Font.Code
            SectionTitle.AutomaticSize = Enum.AutomaticSize.X
            SectionTitle.Parent = SectionInner

            local SectionLayout = Instance.new("UIListLayout")
            SectionLayout.SortOrder = Enum.SortOrder.LayoutOrder
            SectionLayout.Padding = UDim.new(0, 8)
            SectionLayout.Parent = SectionInner

            local SectionPadding = Instance.new("UIPadding")
            SectionPadding.PaddingTop = UDim.new(0, 15)
            SectionPadding.PaddingLeft = UDim.new(0, 8)
            SectionPadding.PaddingRight = UDim.new(0, 8)
            SectionPadding.PaddingBottom = UDim.new(0, 8)
            SectionPadding.Parent = SectionInner

            SectionLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                SectionOuter.Size = UDim2.new(1, -4, 0, SectionLayout.AbsoluteContentSize.Y + 25)
                TabPage.CanvasSize = UDim2.new(0, 0, 0, PageLayout.AbsoluteContentSize.Y + 10)
            end)

            function Section:CreateToggle(text, callback)
                local toggled = false
                callback = callback or function() end

                local ToggleBtn = Instance.new("TextButton")
                ToggleBtn.Size = UDim2.new(1, 0, 0, 12)
                ToggleBtn.BackgroundTransparency = 1
                ToggleBtn.Text = ""
                ToggleBtn.Parent = SectionInner

                local BoxOuter = Instance.new("Frame")
                BoxOuter.Size = UDim2.new(0, 12, 0, 12)
                BoxOuter.BackgroundColor3 = Colors.OuterBorder
                BoxOuter.BorderSizePixel = 0
                BoxOuter.Parent = ToggleBtn

                local BoxInner = Instance.new("Frame")
                BoxInner.Size = UDim2.new(1, -2, 1, -2)
                BoxInner.Position = UDim2.new(0, 1, 0, 1)
                BoxInner.BackgroundColor3 = Colors.InnerBackground
                BoxInner.BorderColor3 = Colors.InnerBorder
                BoxInner.BorderSizePixel = 1
                BoxInner.Parent = BoxOuter

                local Label = Instance.new("TextLabel")
                Label.Size = UDim2.new(1, -20, 1, 0)
                Label.Position = UDim2.new(0, 20, 0, 0)
                Label.BackgroundTransparency = 1
                Label.Text = text
                Label.TextColor3 = Colors.Text
                Label.TextSize = 11
                Label.Font = Enum.Font.Code
                Label.TextXAlignment = Enum.TextXAlignment.Left
                Label.Parent = ToggleBtn

                ToggleBtn.MouseButton1Click:Connect(function()
                    toggled = not toggled
                    BoxInner.BackgroundColor3 = toggled and Colors.Accent or Colors.InnerBackground
                    callback(toggled)
                end)
            end

            function Section:CreateButton(text, callback)
                local BtnOuter = Instance.new("Frame")
                BtnOuter.Size = UDim2.new(1, 0, 0, 20)
                BtnOuter.BackgroundColor3 = Colors.OuterBorder
                BtnOuter.BorderSizePixel = 0
                BtnOuter.Parent = SectionInner

                local Button = Instance.new("TextButton")
                Button.Size = UDim2.new(1, -2, 1, -2)
                Button.Position = UDim2.new(0, 1, 0, 1)
                Button.BackgroundColor3 = Colors.InnerBackground
                Button.BorderColor3 = Colors.InnerBorder
                Button.BorderSizePixel = 1
                Button.Text = text
                Button.TextColor3 = Colors.Text
                Button.TextSize = 11
                Button.Font = Enum.Font.Code
                Button.Parent = BtnOuter

                Button.MouseButton1Click:Connect(function()
                    if callback then callback() end
                end)
            end

            function Section:CreateSlider(text, min, max, default, callback)
                local value = default or min
                local SliderFrame = Instance.new("Frame")
                SliderFrame.Size = UDim2.new(1, 0, 0, 30)
                SliderFrame.BackgroundTransparency = 1
                SliderFrame.Parent = SectionInner

                local Label = Instance.new("TextLabel")
                Label.Size = UDim2.new(1, 0, 0, 14)
                Label.BackgroundTransparency = 1
                Label.Text = text .. " : " .. tostring(value)
                Label.TextColor3 = Colors.Text
                Label.TextSize = 11
                Label.Font = Enum.Font.Code
                Label.TextXAlignment = Enum.TextXAlignment.Left
                Label.Parent = SliderFrame

                local SliderOuter = Instance.new("Frame")
                SliderOuter.Size = UDim2.new(1, 0, 0, 10)
                SliderOuter.Position = UDim2.new(0, 0, 0, 18)
                SliderOuter.BackgroundColor3 = Colors.OuterBorder
                SliderOuter.BorderSizePixel = 0
                SliderOuter.Parent = SliderFrame

                local SliderInner = Instance.new("TextButton")
                SliderInner.Size = UDim2.new(1, -2, 1, -2)
                SliderInner.Position = UDim2.new(0, 1, 0, 1)
                SliderInner.BackgroundColor3 = Colors.InnerBackground
                SliderInner.BorderColor3 = Colors.InnerBorder
                SliderInner.BorderSizePixel = 1
                SliderInner.Text = ""
                SliderInner.AutoButtonColor = false
                SliderInner.Parent = SliderOuter

                local Fill = Instance.new("Frame")
                Fill.Size = UDim2.new((value - min) / (max - min), 0, 1, 0)
                Fill.BackgroundColor3 = Colors.Accent
                Fill.BorderSizePixel = 0
                Fill.Parent = SliderInner

                local dragging = false
                SliderInner.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true end
                end)
                UserInputService.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
                end)
                UserInputService.InputChanged:Connect(function(input)
                    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                        local mouseX = input.Position.X
                        local sliderX = SliderInner.AbsolutePosition.X
                        local sliderSize = SliderInner.AbsoluteSize.X
                        local percentage = math.clamp((mouseX - sliderX) / sliderSize, 0, 1)
                        value = math.floor(min + (max - min) * percentage)
                        Fill.Size = UDim2.new(percentage, 0, 1, 0)
                        Label.Text = text .. " : " .. tostring(value)
                        callback(value)
                    end
                end)
            end

            function Section:CreateDropdown(text, options, callback)
                local DropdownFrame = Instance.new("Frame")
                DropdownFrame.Size = UDim2.new(1, 0, 0, 35)
                DropdownFrame.BackgroundTransparency = 1
                DropdownFrame.Parent = SectionInner

                local Label = Instance.new("TextLabel")
                Label.Size = UDim2.new(1, 0, 0, 14)
                Label.BackgroundTransparency = 1
                Label.Text = text
                Label.TextColor3 = Colors.Text
                Label.TextSize = 11
                Label.Font = Enum.Font.Code
                Label.TextXAlignment = Enum.TextXAlignment.Left
                Label.Parent = DropdownFrame

                local MainOuter = Instance.new("Frame")
                MainOuter.Size = UDim2.new(1, 0, 0, 20)
                MainOuter.Position = UDim2.new(0, 0, 0, 15)
                MainOuter.BackgroundColor3 = Colors.OuterBorder
                MainOuter.BorderSizePixel = 0
                MainOuter.Parent = DropdownFrame

                local MainBtn = Instance.new("TextButton")
                MainBtn.Size = UDim2.new(1, -2, 1, -2)
                MainBtn.Position = UDim2.new(0, 1, 0, 1)
                MainBtn.BackgroundColor3 = Colors.InnerBackground
                MainBtn.BorderColor3 = Colors.InnerBorder
                MainBtn.BorderSizePixel = 1
                MainBtn.Text = "  Select..."
                MainBtn.TextColor3 = Colors.Text
                MainBtn.TextSize = 11
                MainBtn.Font = Enum.Font.Code
                MainBtn.TextXAlignment = Enum.TextXAlignment.Left
                MainBtn.Parent = MainOuter

                local ListOuter = Instance.new("Frame")
                ListOuter.Size = UDim2.new(1, 0, 0, #options * 20 + 2)
                ListOuter.Position = UDim2.new(0, 0, 1, 1)
                ListOuter.BackgroundColor3 = Colors.OuterBorder
                ListOuter.BorderSizePixel = 0
                ListOuter.Visible = false
                ListOuter.ZIndex = 5
                ListOuter.Parent = MainOuter

                local ListInner = Instance.new("Frame")
                ListInner.Size = UDim2.new(1, -2, 1, -2)
                ListInner.Position = UDim2.new(0, 1, 0, 1)
                ListInner.BackgroundColor3 = Colors.InnerBackground
                ListInner.BorderColor3 = Colors.InnerBorder
                ListInner.BorderSizePixel = 1
                ListInner.ZIndex = 5
                ListInner.Parent = ListOuter

                local ListLayout = Instance.new("UIListLayout")
                ListLayout.Parent = ListInner

                MainBtn.MouseButton1Click:Connect(function()
                    ListOuter.Visible = not ListOuter.Visible
                end)

                for _, option in pairs(options) do
                    local OptBtn = Instance.new("TextButton")
                    OptBtn.Size = UDim2.new(1, 0, 0, 20)
                    OptBtn.BackgroundTransparency = 1
                    OptBtn.Text = "  " .. option
                    OptBtn.TextColor3 = Colors.TextDark
                    OptBtn.TextSize = 11
                    OptBtn.Font = Enum.Font.Code
                    OptBtn.TextXAlignment = Enum.TextXAlignment.Left
                    OptBtn.ZIndex = 6
                    OptBtn.Parent = ListInner

                    OptBtn.MouseButton1Click:Connect(function()
                        MainBtn.Text = "  " .. option
                        ListOuter.Visible = false
                        callback(option)
                    end)
                end
            end

            return Section
        end

        return Tab
    end

    return Window
end

return SkeetUI
