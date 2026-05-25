local DataStoreService = game:GetService("DataStoreService")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DONATION_PRODUCTS = {
	[3598501584] = 10,
	[3598501592] = 50,
	[3598501597] = 100,
	[3598501604] = 250,
	[3598443222] = 1000,
}
local DONATION_TOTAL_KEY = "DonationTotalRobux"

local donationStore = DataStoreService:GetDataStore("LifeGridDonations")

local donationTotalValue = Instance.new("IntValue")
donationTotalValue.Name = "DonationTotalRobux"
donationTotalValue.Value = 0
donationTotalValue.Parent = ReplicatedStorage

local function refreshDonationTotal()
	local success, total = pcall(function()
		return donationStore:GetAsync(DONATION_TOTAL_KEY)
	end)

	if success and typeof(total) == "number" then
		donationTotalValue.Value = total
	end
end

refreshDonationTotal()

MarketplaceService.ProcessReceipt = function(receiptInfo)
	local donationAmount = DONATION_PRODUCTS[receiptInfo.ProductId]
	if not donationAmount then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local success, total = pcall(function()
		return donationStore:IncrementAsync(DONATION_TOTAL_KEY, donationAmount)
	end)

	if not success then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	donationTotalValue.Value = total
	return Enum.ProductPurchaseDecision.PurchaseGranted
end
