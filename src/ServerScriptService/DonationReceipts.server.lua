local DataStoreService = game:GetService("DataStoreService")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DONATION_PRODUCT_ID = 3598443222
local DONATION_AMOUNT_ROBUX = 1000
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
	if DONATION_PRODUCT_ID <= 0 or receiptInfo.ProductId ~= DONATION_PRODUCT_ID then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local success, total = pcall(function()
		return donationStore:IncrementAsync(DONATION_TOTAL_KEY, DONATION_AMOUNT_ROBUX)
	end)

	if not success then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	donationTotalValue.Value = total
	return Enum.ProductPurchaseDecision.PurchaseGranted
end
