local function SatisfiesLimit(value, limits)
  return (
      limits.min == nil or
      limits.min <= value
    ) and (
      limits.max == nil or
      limits.max >= value
    )
end

local ALL_FILTERS = {}

function ALL_FILTERS.itemLevel(resultWithKey, limits)
  local itemLevel = GetDetailedItemLevelInfo(resultWithKey.entries[1].itemLink)
  return SatisfiesLimit(itemLevel, limits)
end

function ALL_FILTERS.craftedLevel(resultWithKey, limits)
  if limits.min == nil and limits.max == nil then
    return true
  end

  local level = resultWithKey.entries[1].info[AuctionHouseHelper.Constants.AuctionItemInfo.Level]
  return SatisfiesLimit(level, limits)
end

function ALL_FILTERS.price(resultWithKey, limits)
  return SatisfiesLimit(resultWithKey.minPrice, limits)
end

function ALL_FILTERS.quality(resultWithKey, quality)
  return (select(AuctionHouseHelper.Constants.ITEM_INFO.RARITY, GetItemInfo(resultWithKey.entries[1].itemLink))) == quality
end

function AuctionHouseHelper.Search.CheckFilters(resultWithKey, filters)
  for filterName, limits in pairs(filters) do
    if not ALL_FILTERS[filterName](resultWithKey, limits) then
      return false
    end
  end
  return true
end
