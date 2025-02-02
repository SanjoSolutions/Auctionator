AuctionHouseHelperSellingBagFrameMixin = {}

local FAVOURITE = -1

function AuctionHouseHelperSellingBagFrameMixin:OnLoad()
  AuctionHouseHelper.Debug.Message("AuctionHouseHelperSellingBagFrameMixin:OnLoad()")
  self.allShowing = true

  self.orderedClassIds = {
    FAVOURITE,
  }
  self.frameMap = {
    [FAVOURITE] = self.ScrollBox.ItemListingFrame.Favourites
  }

  self.frameMap[FAVOURITE]:Init()

  local prevFrame = self.frameMap[FAVOURITE]

  for _, classID in ipairs(AuctionHouseHelper.Constants.ValidItemClassIDs) do
    table.insert(self.orderedClassIds, classID)

    local frame = CreateFrame(
      "FRAME", nil, self.ScrollBox.ItemListingFrame, "AuctionHouseHelperBagClassListing"
    )
    frame:Init(classID)
    frame:SetPoint("TOPLEFT", prevFrame, "BOTTOMLEFT")
    frame:SetPoint("RIGHT", self.ScrollBox.ItemListingFrame)

    self.frameMap[classID] = frame
    prevFrame = frame
  end

  self:SetWidth(self.frameMap[FAVOURITE]:GetRowWidth())

  -- Used to preserve scroll position relative to top when contents change
  self.ScrollBox.ItemListingFrame.OnSettingDirty = function(listing)
    listing.oldHeight = listing:GetHeight() -- Used to get absolute offset from top
  end

  self.ScrollBox.ItemListingFrame.OnCleaned = function(listing)
    local oldOffset = self.ScrollBox:GetDerivedScrollOffset()

    self.ScrollBox:FullUpdate(ScrollBoxConstants.UpdateImmediately);

    self.ScrollBox:SetScrollTargetOffset(oldOffset)
  end

  local view = CreateScrollBoxLinearView()
  view:SetPanExtent(50)
  ScrollUtil.InitScrollBoxWithScrollBar(self.ScrollBox, self.ScrollBar, view);
end

function AuctionHouseHelperSellingBagFrameMixin:Init(dataProvider)
  self.dataProvider = dataProvider

  self.dataProvider:SetOnUpdateCallback(function()
    self:Refresh()
  end)
  self.dataProvider:SetOnSearchEndedCallback(function()
    self:Refresh()
  end)

  self:Refresh()
end

function AuctionHouseHelperSellingBagFrameMixin:Refresh()
  AuctionHouseHelper.Debug.Message("AuctionHouseHelperSellingBagFrameMixin:Refresh()")

  self:AggregateItemsByClass()
  self:SetupFavourites()
  self:Update()
end

function AuctionHouseHelperSellingBagFrameMixin:AggregateItemsByClass()
  self.items = {}

  for _, classID in ipairs(AuctionHouseHelper.Constants.ValidItemClassIDs) do
    self.items[classID] = {}
  end

  local bagItemCount = self.dataProvider:GetCount()
  local entry

  for index = 1, bagItemCount do
    entry = self.dataProvider:GetEntryAt(index)

    if self.items[entry.classId] ~= nil then
      table.insert(self.items[entry.classId], entry)
    else
      AuctionHouseHelper.Debug.Message("AuctionHouseHelperSellingBagFrameMixin:AggregateItemsByClass Missing item class table", entry.classId)
    end
  end
end

function AuctionHouseHelperSellingBagFrameMixin:SetupFavourites()
  local bagItemCount = self.dataProvider:GetCount()
  local entry

  self.items[FAVOURITE] = {}
  local seenKeys = {}

  for index = 1, bagItemCount do
    entry = self.dataProvider:GetEntryAt(index)
    if AuctionHouseHelper.Selling.IsFavourite(entry) then
      seenKeys[AuctionHouseHelper.Selling.UniqueBagKey(entry)] = true
      table.insert(self.items[FAVOURITE], CopyTable(entry))
    end
  end

  if AuctionHouseHelper.Config.Get(AuctionHouseHelper.Config.Options.SELLING_MISSING_FAVOURITES) then
    local moreFavourites = AuctionHouseHelper.Selling.GetAllFavourites()

    --Make favourite order independent of the order that the favourites were
    --added.
    table.sort(moreFavourites, function(left, right)
      return AuctionHouseHelper.Selling.UniqueBagKey(left) < AuctionHouseHelper.Selling.UniqueBagKey(right)
    end)

    for _, fav in ipairs(moreFavourites) do
      if seenKeys[AuctionHouseHelper.Selling.UniqueBagKey(fav)] == nil then
        table.insert(self.items[FAVOURITE], CopyTable(fav))
      end
    end
  end
end

function AuctionHouseHelperSellingBagFrameMixin:Update()
  AuctionHouseHelper.Debug.Message("AuctionHouseHelperSellingBagFrameMixin:Update()")
  self.ScrollBox.ItemListingFrame.oldHeight = self.ScrollBox.ItemListingFrame:GetHeight()

  local lastItem = nil

  for _, classId in ipairs(self.orderedClassIds) do
    local frame = self.frameMap[classId]
    local items = self.items[classId]
    frame:Reset()

    local classItems = {}

    for _, item in ipairs(items) do
      if item.auctionable then
        table.insert(classItems, item)
        if lastItem then
          lastItem.nextItem = item
        end
        lastItem = item
      end
    end

    frame:AddItems(classItems)
  end

  self.ScrollBox.ItemListingFrame:OnSettingDirty()
  self.ScrollBox.ItemListingFrame:MarkDirty()
end
