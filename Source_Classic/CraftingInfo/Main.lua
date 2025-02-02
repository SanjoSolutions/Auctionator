-- Add a button to the tradeskill frame to search the AH for the reagents.
-- The button will be hidden when the AH is closed.
-- The total price is shown in a FontString next to the button
local addedFunctionality = false
function AuctionHouseHelper.CraftingInfo.Initialize()
  if addedFunctionality then
    return
  end

  if TradeSkillFrame then
    addedFunctionality = true
    CreateFrame("Frame", "AuctionHouseHelperCraftingInfo", TradeSkillFrame, "AuctionHouseHelperCraftingInfoFrameTemplate");
  end
end

-- Get the associated item, spell level and spell equipped item class for an
-- enchant
local function EnchantLinkToData(enchantLink)
  return AuctionHouseHelper.CraftingInfo.EnchantSpellsToItemData[tonumber(enchantLink:match("enchant:(%d+)"))]
end

local function GetOutputName(callback)
  local recipeIndex = GetTradeSkillSelectionIndex()
  local outputLink = GetTradeSkillItemLink(recipeIndex)
  local itemID

  if outputLink then
    itemID = GetItemInfoInstant(outputLink)
  else -- Probably an enchant
    local data = EnchantLinkToData(GetTradeSkillRecipeLink(recipeIndex))
    if data == nil then
      callback(nil)
      return
    end
    itemID = data.itemID
  end

  if itemID == nil then
    callback(nil)
    return
  end

  local item = Item:CreateFromItemID(itemID)
  if item:IsItemEmpty() then
    callback(nil)
  else
    item:ContinueOnItemLoad(function()
      callback(item:GetItemName())
    end)
  end
end

function AuctionHouseHelper.CraftingInfo.DoTradeSkillReagentsSearch()
  GetOutputName(function(outputName)
    local items = {}
    if outputName then
      table.insert(items, outputName)
    end
    local recipeIndex = GetTradeSkillSelectionIndex()

    for reagentIndex = 1, GetTradeSkillNumReagents(recipeIndex) do
      local reagentName = GetTradeSkillReagentInfo(recipeIndex, reagentIndex)
      table.insert(items, reagentName)
    end

    AuctionHouseHelper.API.v1.MultiSearchExact(AUCTION_HOUSE_HELPER_L_REAGENT_SEARCH, items)
  end)
end

local function GetSkillReagentsTotal()
  local recipeIndex = GetTradeSkillSelectionIndex()

  local total = 0

  for reagentIndex = 1, GetTradeSkillNumReagents(recipeIndex) do
    local multiplier = select(3, GetTradeSkillReagentInfo(recipeIndex, reagentIndex))
    local link = GetTradeSkillReagentItemLink(recipeIndex, reagentIndex)
    if link ~= nil then
      local vendorPrice = AuctionHouseHelper.API.v1.GetVendorPriceByItemLink(AUCTION_HOUSE_HELPER_L_REAGENT_SEARCH, link)
      local auctionPrice = AuctionHouseHelper.API.v1.GetAuctionPriceByItemLink(AUCTION_HOUSE_HELPER_L_REAGENT_SEARCH, link)

      local unitPrice = vendorPrice or auctionPrice

      if unitPrice ~= nil then
        total = total + multiplier * unitPrice
      end
    end
  end

  return total
end

local function GetEnchantProfit()
  local toCraft = GetSkillReagentsTotal()

  local recipeIndex = GetTradeSkillSelectionIndex()
  local data = EnchantLinkToData(GetTradeSkillRecipeLink(recipeIndex))
  if data == nil then
    return nil
  end

  -- Determine which vellum for the item class of the enchanted item
  local vellumForClass = AuctionHouseHelper.CraftingInfo.EnchantVellums[data.itemClass]
  if vellumForClass == nil then
    return nil
  end

  -- Find the cheapest vellum that will work
  local vellumCost
  local anyMatch = false
  for vellumItemID, vellumLevel in pairs(vellumForClass) do
    if data.level <= vellumLevel then
      anyMatch = true
      local optionOnAH = AuctionHouseHelper.API.v1.GetAuctionPriceByItemID(AUCTION_HOUSE_HELPER_L_REAGENT_SEARCH, vellumItemID)
      if vellumCost == nil or (optionOnAH ~= nil and optionOnAH <= vellumCost) then
        AuctionHouseHelper.Debug.Message("CraftingInfo: Selecting vellum for enchant", vellumItemID)
        vellumCost = optionOnAH
      end
    end
  end

  -- Couldn't find a vellum for the level (so presumably not in the enchant data)
  if not anyMatch then
    return nil
  end

  vellumCost = vellumCost or 0

  local currentAH = AuctionHouseHelper.API.v1.GetAuctionPriceByItemID(AUCTION_HOUSE_HELPER_L_REAGENT_SEARCH, data.itemID)
  if currentAH == nil then
    currentAH = 0
  end

  return math.floor(currentAH * AuctionHouseHelper.Constants.AfterAHCut - vellumCost - toCraft)
end

local function GetAHProfit()
  local recipeIndex = GetTradeSkillSelectionIndex()

  if select(5, GetTradeSkillInfo(recipeIndex)) == ENSCRIBE then
    return GetEnchantProfit()
  end

  local recipeLink =  GetTradeSkillItemLink(recipeIndex)
  local minCount, maxCount = GetTradeSkillNumMade(recipeIndex)
  print('counts', minCount, maxCount)

  if recipeLink == nil or recipeLink:match("enchant:") then
    return nil
  end

  local currentAH = AuctionHouseHelper.API.v1.GetAuctionPriceByItemLink(AUCTION_HOUSE_HELPER_L_REAGENT_SEARCH, recipeLink)
  if currentAH == nil then
    currentAH = 0
  end
  local toCraft = GetSkillReagentsTotal()

  return math.floor(currentAH * minCount * AuctionHouseHelper.Constants.AfterAHCut - toCraft),
    math.floor(currentAH * maxCount * AuctionHouseHelper.Constants.AfterAHCut - toCraft)
end

local function CraftCostString()
  local price = WHITE_FONT_COLOR:WrapTextInColorCode(GetMoneyString(GetSkillReagentsTotal(), true))

  return AUCTION_HOUSE_HELPER_L_TO_CRAFT_COLON .. " " .. price
end

local function PriceString(price)
  local priceString
  if price >= 0 then
    priceString = WHITE_FONT_COLOR:WrapTextInColorCode(GetMoneyString(price, true))
  else
    priceString = RED_FONT_COLOR:WrapTextInColorCode("-" .. GetMoneyString(-price, true))
  end
  return priceString
end

local function ProfitString(minProfit, maxProfit)
  if minProfit == maxProfit then
    return AUCTION_HOUSE_HELPER_L_PROFIT_COLON .. " " .. PriceString(minProfit)
  else
    return AUCTION_HOUSE_HELPER_L_PROFIT_COLON .. " " .. PriceString(minProfit) .. " " .. AUCTION_HOUSE_HELPER_L_PROFIT_TO .. " " .. PriceString(maxProfit)
  end
end

function AuctionHouseHelper.CraftingInfo.GetInfoText()
  local result = ""
  local lines = 0
  if AuctionHouseHelper.Config.Get(AuctionHouseHelper.Config.Options.CRAFTING_INFO_SHOW_COST) then
    if lines > 0 then
      result = result .. "\n"
    end
    result = result .. CraftCostString()
    lines = lines + 1
  end

  if AuctionHouseHelper.Config.Get(AuctionHouseHelper.Config.Options.CRAFTING_INFO_SHOW_PROFIT) then
    local minProfit, maxProfit = GetAHProfit()

    if minProfit ~= nil then
      if lines > 0 then
        result = result .. "\n"
      end
      result = result .. ProfitString(minProfit, maxProfit)
      lines = lines + 1
    end
  end
  return result, lines
end
