AuctionHouseHelperDropDownMixin = {}

local LibDD = LibStub:GetLibrary("LibUIDropDownMenu-4.0")

local ARRAY_DELIMITER = ";"
local function splitStrArray(arrayString)
  return {strsplit(ARRAY_DELIMITER, arrayString)}
end

local function localizeArray(array)
  for index, itm in ipairs(array) do
    array[index] = AuctionHouseHelper.Locales.Apply(itm)
  end

  return array
end

function AuctionHouseHelperDropDownMixin:OnLoad()
  LibDD:Create_UIDropDownMenu(self.DropDown)

  if self.textString ~= nil and self.valuesString ~= nil then
    self:InitAgain(
      localizeArray(splitStrArray(self.textString)),
      splitStrArray(self.valuesString)
    )
  end

  if self.labelText ~= nil then
    self.Label:SetText(self.labelText)
  end
end

function AuctionHouseHelperDropDownMixin:InitAgain(lables, values)
  self.DropDown:Initialize(lables, values)
end

function AuctionHouseHelperDropDownMixin:SetValue(...)
  self.DropDown:SetValue(...)
end

function AuctionHouseHelperDropDownMixin:GetValue(...)
  return self.DropDown:GetValue(...)
end

AuctionHouseHelperDropDownInternalMixin = {}

function AuctionHouseHelperDropDownInternalMixin:Initialize(text, values)
  self.text = text
  self.values = values
  self.value = self.values[1]

  self:SetValue(self.value)

  LibDD:UIDropDownMenu_SetInitializeFunction(self, self.BlizzInitialize)

  LibDD:UIDropDownMenu_SetWidth(self, 150)
end

function AuctionHouseHelperDropDownInternalMixin:BlizzInitialize()
  local listEntry

  for index = 1, #self.text do
    listEntry = LibDD:UIDropDownMenu_CreateInfo()
    listEntry.notCheckable = true
    listEntry.text = self.text[index]
    listEntry.value = self.values[index]
    listEntry.func = function(entry)
      self:SetValue(entry.value)
    end

    LibDD:UIDropDownMenu_AddButton(listEntry)
  end

  self:SetValue(self.value)
end

function AuctionHouseHelperDropDownInternalMixin:GetValue()
  return self.value
end

function AuctionHouseHelperDropDownInternalMixin:SetValue(newValue)
  for index, value in ipairs(self.values) do
    if newValue == value then
      LibDD:UIDropDownMenu_SetText(self, self.text[index])
      break
    end
  end

  self.value = newValue
end
