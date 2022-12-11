-- Add a info to the tradeskill frame for reagent prices
local addedFunctionality = false
function Auctionator.CraftingInfo.InitializeProfessionsFrame()
  if addedFunctionality then
    return
  end

  if ProfessionsFrame then
    addedFunctionality = true

    local craftingPageButton = CreateFrame("BUTTON", "AuctionatorCraftingInfoProfessionsFrame", ProfessionsFrame.CraftingPage.SchematicForm, "AuctionatorCraftingInfoProfessionsFrameTemplate");
    local ordersPageButton = CreateFrame("BUTTON", "AuctionatorCraftingInfoProfessionsOrderFrame", ProfessionsFrame.OrdersPage.OrderView.OrderDetails.SchematicForm, "AuctionatorCraftingInfoProfessionsFrameTemplate");
    ordersPageButton:SetDoNotShowProfit()
  end
end

function Auctionator.CraftingInfo.DoTradeSkillReagentsSearch(schematicForm)
  local recipeInfo = schematicForm:GetRecipeInfo()
  local recipeID = recipeInfo.recipeID
  local recipeLevel = schematicForm:GetCurrentRecipeLevel()

  local recipeSchematic = C_TradeSkillUI.GetRecipeSchematic(recipeID, false, recipeLevel)

  local transaction = schematicForm:GetTransaction()

  local searchTerms = {}

  local possibleItems = {}

  local continuableContainer = ContinuableContainer:Create()

  local outputLink = Auctionator.CraftingInfo.GetOutputItemLink(recipeID, recipeLevel, transaction:CreateOptionalCraftingReagentInfoTbl(), transaction:GetAllocationItemGUID())

  if outputLink then
    table.insert(possibleItems, outputLink)
    continuableContainer:AddContinuable(Item:CreateFromItemLink(outputLink))
  -- Special case, enchants don't include an output in the API, so we use a
  -- precomputed table to get the output
  elseif Auctionator.CraftingInfo.EnchantSpellsToItems[recipeID] then
    local itemID = Auctionator.CraftingInfo.EnchantSpellsToItems[recipeID][1]
    table.insert(possibleItems, itemID)
    continuableContainer:AddContinuable(Item:CreateFromItemID(itemID))
  else
    table.insert(searchTerms, recipeInfo.name)
  end

  -- Select all mandatory reagents
  for slotIndex, reagentSlotSchematic in ipairs(recipeSchematic.reagentSlotSchematics) do
    if reagentSlotSchematic.reagentType == Enum.CraftingReagentType.Basic and #reagentSlotSchematic.reagents > 0 then
      local itemID = reagentSlotSchematic.reagents[1].itemID
      if itemID ~= nil then
        continuableContainer:AddContinuable(Item:CreateFromItemID(itemID))

        table.insert(possibleItems, itemID)
      end
    end
  end

  -- Go through the items one by one and get their names
  local function OnItemInfoReady()
    for _, itemInfo in ipairs(possibleItems) do
      local name = GetItemInfo(itemInfo)
      table.insert(searchTerms, name)
    end

    Auctionator.API.v1.MultiSearchExact(AUCTIONATOR_L_REAGENT_SEARCH, searchTerms)
  end

  continuableContainer:ContinueOnLoad(OnItemInfoReady)
end

local function GetSkillReagentsTotal(schematicForm)
  local recipeInfo = schematicForm:GetRecipeInfo()
  local recipeID = recipeInfo.recipeID
  local recipeLevel = schematicForm:GetCurrentRecipeLevel()
  local transaction = schematicForm:GetTransaction()
  local recipeSchematic = C_TradeSkillUI.GetRecipeSchematic(recipeID, false, recipeLevel)

  return Auctionator.CraftingInfo.CalculateCraftCost(recipeSchematic, transaction)
end

local function CalculateProfitFromCosts(currentAH, toCraft, count)
  return math.floor(math.floor(currentAH * count * Auctionator.Constants.AfterAHCut - toCraft) / 100) * 100
end

local function GetEnchantProfit(schematicForm)
  local recipeID = schematicForm.recipeSchematic.recipeID
  local reagents = schematicForm:GetTransaction():CreateCraftingReagentInfoTbl()
  local allocationGUID = schematicForm:GetTransaction():GetAllocationItemGUID()


  local recipeLevel = schematicForm:GetCurrentRecipeLevel()
  local recipeInfo = C_TradeSkillUI.GetRecipeInfo(recipeID, recipeLevel)

  local possibleOutputItemIDs = Auctionator.CraftingInfo.EnchantSpellsToItems[recipeID] or {}
  local itemID

  -- For Dragonflight recipes determine the quality and then select the quality
  -- from the list of possible results.
  local recipeSchematic = C_TradeSkillUI.GetRecipeSchematic(recipeID, false, recipeLevel)
  if recipeSchematic ~= nil and recipeSchematic.hasCraftingOperationInfo then
    local operationInfo = C_TradeSkillUI.GetCraftingOperationInfo(recipeID, reagents, allocationGUID)
    if operationInfo ~= nil then
      itemID = Auctionator.CraftingInfo.GetItemIDByQuality(possibleOutputItemIDs, operationInfo.guaranteedCraftingQualityID)
    end
  end
  -- Not a dragonflight recipe, or has no quality data, so only one possible
  -- output
  if itemID == nil then
    itemID = possibleOutputItemIDs[1]
  end

  if itemID ~= nil then
    local currentAH = Auctionator.API.v1.GetAuctionPriceByItemID(AUCTIONATOR_L_REAGENT_SEARCH, itemID) or 0

    local vellumCost = Auctionator.API.v1.GetVendorPriceByItemID(AUCTIONATOR_L_REAGENT_SEARCH, Auctionator.Constants.EnchantingVellumID) or 0
    local toCraft = GetSkillReagentsTotal(schematicForm) + vellumCost

    local count = schematicForm.recipeSchematic.quantityMin

    return CalculateProfitFromCosts(currentAH, toCraft, count)
  else
    return nil
  end
end

local function GetAHProfit(schematicForm)
  local recipeInfo = schematicForm:GetRecipeInfo()

  if recipeInfo.isEnchantingRecipe then
    return GetEnchantProfit(schematicForm)

  else
    local recipeLink = Auctionator.CraftingInfo.GetOutputItemLink(
      recipeInfo.recipeID,
      schematicForm:GetCurrentRecipeLevel(),
      schematicForm:GetTransaction():CreateCraftingReagentInfoTbl(),
      schematicForm:GetTransaction():GetAllocationItemGUID()
    )

    if recipeLink ~= nil then
      local currentAH = Auctionator.API.v1.GetAuctionPriceByItemLink(AUCTIONATOR_L_REAGENT_SEARCH, recipeLink) or 0

      local toCraft = GetSkillReagentsTotal(schematicForm)

      local minCount = schematicForm.recipeSchematic.quantityMin
      local maxCount = schematicForm.recipeSchematic.quantityMax

      return CalculateProfitFromCosts(currentAH, toCraft, minCount),
        CalculateProfitFromCosts(currentAH, toCraft, maxCount)
    else
      return nil
    end
  end
end

local function CraftCostString(schematicForm)
  local price = WHITE_FONT_COLOR:WrapTextInColorCode(GetMoneyString(GetSkillReagentsTotal(schematicForm), true))

  return AUCTIONATOR_L_TO_CRAFT_COLON .. " " .. price
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
    return AUCTIONATOR_L_PROFIT_COLON .. " " .. PriceString(minProfit)
  else
    return AUCTIONATOR_L_PROFIT_COLON .. " " .. PriceString(minProfit) .. " " .. AUCTIONATOR_L_PROFIT_TO .. " " .. PriceString(maxProfit)
  end
end

function Auctionator.CraftingInfo.GetInfoText(schematicForm, showProfit)
  local result = ""
  local lines = 0
  if Auctionator.Config.Get(Auctionator.Config.Options.CRAFTING_INFO_SHOW_COST) then
    if lines > 0 then
      result = result .. "\n"
    end
    result = result .. CraftCostString(schematicForm)
    lines = lines + 1
  end

  if showProfit and Auctionator.Config.Get(Auctionator.Config.Options.CRAFTING_INFO_SHOW_PROFIT) then
    local minProfit, maxProfit = GetAHProfit(schematicForm)

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
