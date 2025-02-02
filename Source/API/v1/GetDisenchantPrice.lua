function AuctionHouseHelper.API.v1.GetDisenchantPriceByItemID(callerID, itemID)
  AuctionHouseHelper.API.InternalVerifyID(callerID)

  if type(itemID) ~= "number" then
    AuctionHouseHelper.API.ComposeError(
      callerID,
      "Usage AuctionHouseHelper.API.v1.GetAuctionPriceByItemID(string, number)"
    )
  end

  local itemInfo = { GetItemInfo(itemID) }
  local itemLink = itemInfo[2]

  if itemLink ~= nil then
    return AuctionHouseHelper.Enchant.GetDisenchantAuctionPrice(itemLink, itemInfo)
  else
    return nil
  end
end

function AuctionHouseHelper.API.v1.GetDisenchantPriceByItemLink(callerID, itemLink)
  AuctionHouseHelper.API.InternalVerifyID(callerID)

  if type(itemLink) ~= "string" then
    AuctionHouseHelper.API.ComposeError(
      callerID,
      "Usage AuctionHouseHelper.API.v1.GetAuctionPriceByItemLink(string, string)"
    )
  end

  local itemInfo = { GetItemInfo(itemLink) }

  if #itemInfo > 0 then
    return AuctionHouseHelper.Enchant.GetDisenchantAuctionPrice(itemLink, itemInfo)
  else
    return nil
  end
end
