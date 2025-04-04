import { BrowserProvider, JsonRpcProvider, Contract, formatUnits } from "ethers";

const RPC_URL = process.env.REACT_APP_BASE_RPC_URL;

const provider = new JsonRpcProvider(RPC_URL);

// Get contract instance with read-only access (no signer)
export const getMarketPoolcbBTC_ReadOnly = async () => {
    return new Contract(MarketcbBTC_ADDRESS, MarketcbBTCABI, provider);
};

// Smart contract details
const CollateralPool_ADDRESS = "0xEB58cFa1aE786015EE3AA211CcCC7C387aE81999";
const CollateralPoolABI = [
	{
		"inputs": [
			{
				"internalType": "address",
				"name": "_collateralToken",
				"type": "address"
			},
			{
				"internalType": "uint256",
				"name": "_collateralTokenDecimals",
				"type": "uint256"
			},
			{
				"internalType": "address",
				"name": "_main",
				"type": "address"
			}
		],
		"stateMutability": "nonpayable",
		"type": "constructor"
	},
	{
		"anonymous": false,
		"inputs": [
			{
				"indexed": true,
				"internalType": "address",
				"name": "user",
				"type": "address"
			},
			{
				"indexed": false,
				"internalType": "uint256",
				"name": "amount",
				"type": "uint256"
			}
		],
		"name": "CollateralDeposited",
		"type": "event"
	},
	{
		"anonymous": false,
		"inputs": [
			{
				"indexed": true,
				"internalType": "address",
				"name": "user",
				"type": "address"
			},
			{
				"indexed": false,
				"internalType": "uint256",
				"name": "amount",
				"type": "uint256"
			}
		],
		"name": "CollateralWithdrawn",
		"type": "event"
	},
	{
		"anonymous": false,
		"inputs": [
			{
				"indexed": true,
				"internalType": "address",
				"name": "liquidator",
				"type": "address"
			},
			{
				"indexed": true,
				"internalType": "address",
				"name": "user",
				"type": "address"
			},
			{
				"indexed": false,
				"internalType": "uint256",
				"name": "penalty",
				"type": "uint256"
			}
		],
		"name": "ContractLiquidated",
		"type": "event"
	},
	{
		"anonymous": false,
		"inputs": [
			{
				"indexed": true,
				"internalType": "address",
				"name": "user",
				"type": "address"
			},
			{
				"indexed": false,
				"internalType": "uint256",
				"name": "index",
				"type": "uint256"
			},
			{
				"indexed": false,
				"internalType": "uint256",
				"name": "id",
				"type": "uint256"
			},
			{
				"indexed": false,
				"internalType": "uint256",
				"name": "amount",
				"type": "uint256"
			}
		],
		"name": "RewardsClaimed",
		"type": "event"
	},
	{
		"inputs": [
			{
				"internalType": "address",
				"name": "_user",
				"type": "address"
			}
		],
		"name": "balanceOf",
		"outputs": [
			{
				"internalType": "uint256",
				"name": "",
				"type": "uint256"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "address",
				"name": "_user",
				"type": "address"
			},
			{
				"internalType": "uint256",
				"name": "_rent",
				"type": "uint256"
			}
		],
		"name": "canOpenContract",
		"outputs": [
			{
				"internalType": "bool",
				"name": "",
				"type": "bool"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "uint256",
				"name": "_index",
				"type": "uint256"
			},
			{
				"internalType": "uint256",
				"name": "_id",
				"type": "uint256"
			}
		],
		"name": "claimRewards",
		"outputs": [
			{
				"internalType": "uint256",
				"name": "",
				"type": "uint256"
			}
		],
		"stateMutability": "nonpayable",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "uint256",
				"name": "_amount",
				"type": "uint256"
			}
		],
		"name": "depositCollateral",
		"outputs": [],
		"stateMutability": "nonpayable",
		"type": "function"
	},
	{
		"inputs": [],
		"name": "getCollateralToken",
		"outputs": [
			{
				"internalType": "address",
				"name": "",
				"type": "address"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [],
		"name": "getMain",
		"outputs": [
			{
				"internalType": "address",
				"name": "",
				"type": "address"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "uint256",
				"name": "_index",
				"type": "uint256"
			},
			{
				"internalType": "uint256",
				"name": "_id",
				"type": "uint256"
			}
		],
		"name": "getRewardsForLp",
		"outputs": [
			{
				"internalType": "uint256",
				"name": "",
				"type": "uint256"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "address",
				"name": "_user",
				"type": "address"
			}
		],
		"name": "getUserFees",
		"outputs": [
			{
				"internalType": "uint256",
				"name": "",
				"type": "uint256"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "address",
				"name": "_user",
				"type": "address"
			}
		],
		"name": "getUserInfos",
		"outputs": [
			{
				"components": [
					{
						"internalType": "uint256",
						"name": "collateral",
						"type": "uint256"
					},
					{
						"internalType": "uint256",
						"name": "rent",
						"type": "uint256"
					},
					{
						"internalType": "uint256",
						"name": "lastUpdate",
						"type": "uint256"
					}
				],
				"internalType": "struct CollateralPool.UserInfos",
				"name": "",
				"type": "tuple"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "address",
				"name": "_user",
				"type": "address"
			},
			{
				"internalType": "uint256",
				"name": "_index",
				"type": "uint256"
			},
			{
				"internalType": "uint256",
				"name": "_id",
				"type": "uint256"
			}
		],
		"name": "liquidateContract",
		"outputs": [
			{
				"internalType": "uint256",
				"name": "",
				"type": "uint256"
			}
		],
		"stateMutability": "nonpayable",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "address",
				"name": "_user",
				"type": "address"
			}
		],
		"name": "needLiquidation",
		"outputs": [
			{
				"internalType": "bool",
				"name": "",
				"type": "bool"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "address",
				"name": "_user",
				"type": "address"
			},
			{
				"internalType": "bool",
				"name": "_isAdding",
				"type": "bool"
			},
			{
				"internalType": "uint256",
				"name": "_rent",
				"type": "uint256"
			},
			{
				"internalType": "uint256",
				"name": "_lastUpdate",
				"type": "uint256"
			}
		],
		"name": "updateUserInfos",
		"outputs": [],
		"stateMutability": "nonpayable",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "uint256",
				"name": "_amount",
				"type": "uint256"
			}
		],
		"name": "withdrawCollateral",
		"outputs": [],
		"stateMutability": "nonpayable",
		"type": "function"
	}
];

const ProtocolInfos_ADDRESS = "0x7CF8cE3287987d89BcD89C79A6B728184589288F";
const ProtocolInfosABI = [
	{
		"inputs": [
			{
				"internalType": "address",
				"name": "_main",
				"type": "address"
			}
		],
		"stateMutability": "nonpayable",
		"type": "constructor"
	},
	{
		"inputs": [],
		"name": "getAllLps",
		"outputs": [
			{
				"internalType": "address[]",
				"name": "",
				"type": "address[]"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [],
		"name": "getAllUsers",
		"outputs": [
			{
				"internalType": "address[]",
				"name": "",
				"type": "address[]"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [],
		"name": "getCollateralPoolBalanceDetail",
		"outputs": [
			{
				"components": [
					{
						"internalType": "uint256",
						"name": "CollateralToken",
						"type": "uint256"
					},
					{
						"internalType": "uint256",
						"name": "UsersBalance",
						"type": "uint256"
					},
					{
						"internalType": "uint256",
						"name": "LpsBalance",
						"type": "uint256"
					}
				],
				"internalType": "struct ProtocolInfos.CpBalanceDetail",
				"name": "",
				"type": "tuple"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [],
		"name": "getLpsCount",
		"outputs": [
			{
				"internalType": "uint256",
				"name": "",
				"type": "uint256"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "uint256",
				"name": "_index",
				"type": "uint256"
			}
		],
		"name": "getMarketActiveStrikes",
		"outputs": [
			{
				"internalType": "uint256[]",
				"name": "",
				"type": "uint256[]"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "uint256",
				"name": "_index",
				"type": "uint256"
			}
		],
		"name": "getMarketAssetPrice",
		"outputs": [
			{
				"internalType": "uint256",
				"name": "",
				"type": "uint256"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "uint256",
				"name": "_index",
				"type": "uint256"
			}
		],
		"name": "getMarketAvailableLiquidation",
		"outputs": [
			{
				"internalType": "address[]",
				"name": "",
				"type": "address[]"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "uint256",
				"name": "_index",
				"type": "uint256"
			}
		],
		"name": "getMarketBalanceDetail",
		"outputs": [
			{
				"components": [
					{
						"internalType": "uint256",
						"name": "tokenA",
						"type": "uint256"
					},
					{
						"internalType": "uint256",
						"name": "tokenAProvided",
						"type": "uint256"
					},
					{
						"internalType": "uint256",
						"name": "tokenAFromPut",
						"type": "uint256"
					},
					{
						"internalType": "uint256",
						"name": "tokenB",
						"type": "uint256"
					},
					{
						"internalType": "uint256",
						"name": "tokenBProvided",
						"type": "uint256"
					},
					{
						"internalType": "uint256",
						"name": "tokenBFromCall",
						"type": "uint256"
					}
				],
				"internalType": "struct ProtocolInfos.MpBalanceDetail",
				"name": "",
				"type": "tuple"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "uint256",
				"name": "_index",
				"type": "uint256"
			}
		],
		"name": "getMarketLiquidityProvided",
		"outputs": [
			{
				"internalType": "uint256[2]",
				"name": "",
				"type": "uint256[2]"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "uint256",
				"name": "_index",
				"type": "uint256"
			}
		],
		"name": "getMarketOpenInterest",
		"outputs": [
			{
				"internalType": "uint256[2]",
				"name": "",
				"type": "uint256[2]"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "address",
				"name": "_lp",
				"type": "address"
			}
		],
		"name": "getTotalRewardsForLP",
		"outputs": [
			{
				"internalType": "uint256",
				"name": "",
				"type": "uint256"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [],
		"name": "getUsersCount",
		"outputs": [
			{
				"internalType": "uint256",
				"name": "",
				"type": "uint256"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "uint256",
				"name": "_x",
				"type": "uint256"
			},
			{
				"internalType": "uint256[]",
				"name": "_array",
				"type": "uint256[]"
			}
		],
		"name": "isPartOf",
		"outputs": [
			{
				"internalType": "bool",
				"name": "",
				"type": "bool"
			}
		],
		"stateMutability": "pure",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "address",
				"name": "_x",
				"type": "address"
			},
			{
				"internalType": "address[]",
				"name": "_array",
				"type": "address[]"
			}
		],
		"name": "isPartOf",
		"outputs": [
			{
				"internalType": "bool",
				"name": "",
				"type": "bool"
			}
		],
		"stateMutability": "pure",
		"type": "function"
	}
];

const UserInfos_ADDRESS = "0x460017144d3510701eF15BBbda6Cf1195354BcEd";
const UserInfosABI = [
	{
		"inputs": [
			{
				"internalType": "address",
				"name": "_main",
				"type": "address"
			}
		],
		"stateMutability": "nonpayable",
		"type": "constructor"
	},
	{
		"inputs": [
			{
				"internalType": "uint256",
				"name": "_index",
				"type": "uint256"
			},
			{
				"internalType": "address",
				"name": "_user",
				"type": "address"
			}
		],
		"name": "GetUserContractsForMarket",
		"outputs": [
			{
				"components": [
					{
						"internalType": "uint256",
						"name": "ID",
						"type": "uint256"
					},
					{
						"internalType": "bool",
						"name": "isCall",
						"type": "bool"
					},
					{
						"internalType": "uint256",
						"name": "strike",
						"type": "uint256"
					},
					{
						"internalType": "uint256",
						"name": "amount",
						"type": "uint256"
					},
					{
						"internalType": "uint256",
						"name": "rent",
						"type": "uint256"
					},
					{
						"internalType": "uint256",
						"name": "start",
						"type": "uint256"
					},
					{
						"internalType": "uint256",
						"name": "spent",
						"type": "uint256"
					},
					{
						"internalType": "bool",
						"name": "isITM",
						"type": "bool"
					},
					{
						"internalType": "uint256",
						"name": "earnings",
						"type": "uint256"
					}
				],
				"internalType": "struct UserInfos.UserContract[]",
				"name": "",
				"type": "tuple[]"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "uint256",
				"name": "_index",
				"type": "uint256"
			},
			{
				"internalType": "address",
				"name": "_user",
				"type": "address"
			},
			{
				"internalType": "uint256",
				"name": "_strike",
				"type": "uint256"
			}
		],
		"name": "GetUserLpAmountsForStrikeForMarket",
		"outputs": [
			{
				"internalType": "uint256[]",
				"name": "",
				"type": "uint256[]"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "uint256",
				"name": "_index",
				"type": "uint256"
			},
			{
				"internalType": "address",
				"name": "_user",
				"type": "address"
			}
		],
		"name": "GetUserLpInfosListForMarket",
		"outputs": [
			{
				"components": [
					{
						"internalType": "bool",
						"name": "isCall",
						"type": "bool"
					},
					{
						"internalType": "uint256",
						"name": "strike",
						"type": "uint256"
					},
					{
						"internalType": "uint256",
						"name": "amount",
						"type": "uint256"
					},
					{
						"internalType": "uint256",
						"name": "start",
						"type": "uint256"
					},
					{
						"internalType": "uint256",
						"name": "lastClaim",
						"type": "uint256"
					}
				],
				"internalType": "struct IMarketPool.LpInfos[]",
				"name": "",
				"type": "tuple[]"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "uint256",
				"name": "_index",
				"type": "uint256"
			},
			{
				"internalType": "address",
				"name": "_user",
				"type": "address"
			}
		],
		"name": "GetUserLpStrikesForMarket",
		"outputs": [
			{
				"internalType": "uint256[]",
				"name": "",
				"type": "uint256[]"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "address",
				"name": "_user",
				"type": "address"
			}
		],
		"name": "GetUserLps",
		"outputs": [
			{
				"components": [
					{
						"internalType": "uint256",
						"name": "index",
						"type": "uint256"
					},
					{
						"internalType": "uint256",
						"name": "ID",
						"type": "uint256"
					},
					{
						"internalType": "bool",
						"name": "isCall",
						"type": "bool"
					},
					{
						"internalType": "uint256",
						"name": "strike",
						"type": "uint256"
					},
					{
						"internalType": "uint256",
						"name": "amount",
						"type": "uint256"
					},
					{
						"internalType": "uint256",
						"name": "start",
						"type": "uint256"
					},
					{
						"internalType": "uint256",
						"name": "lastClaim",
						"type": "uint256"
					},
					{
						"internalType": "bool",
						"name": "isITM",
						"type": "bool"
					},
					{
						"internalType": "uint256",
						"name": "value",
						"type": "uint256"
					},
					{
						"internalType": "uint256",
						"name": "withdrawableTokenA",
						"type": "uint256"
					},
					{
						"internalType": "uint256",
						"name": "withdrawableTokenB",
						"type": "uint256"
					}
				],
				"internalType": "struct UserInfos.UserLp[]",
				"name": "",
				"type": "tuple[]"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "uint256",
				"name": "_index",
				"type": "uint256"
			},
			{
				"internalType": "uint256",
				"name": "_id",
				"type": "uint256"
			}
		],
		"name": "GetWithdrawableForLPForMaket",
		"outputs": [
			{
				"internalType": "uint256",
				"name": "",
				"type": "uint256"
			},
			{
				"internalType": "uint256",
				"name": "",
				"type": "uint256"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "address",
				"name": "_lp",
				"type": "address"
			}
		],
		"name": "getEstimatedYearlyEarningsForLP",
		"outputs": [
			{
				"internalType": "uint256",
				"name": "",
				"type": "uint256"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "uint256",
				"name": "_index",
				"type": "uint256"
			}
		],
		"name": "getMarketAssetPrice",
		"outputs": [
			{
				"internalType": "uint256",
				"name": "",
				"type": "uint256"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "address",
				"name": "_lp",
				"type": "address"
			}
		],
		"name": "getTotalOpenInterestForLP",
		"outputs": [
			{
				"internalType": "uint256",
				"name": "",
				"type": "uint256"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "address",
				"name": "_lp",
				"type": "address"
			}
		],
		"name": "getTotalRewardsForLP",
		"outputs": [
			{
				"internalType": "uint256",
				"name": "",
				"type": "uint256"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "uint256",
				"name": "_index",
				"type": "uint256"
			},
			{
				"internalType": "address",
				"name": "_user",
				"type": "address"
			}
		],
		"name": "getUserLpInfosForMarket",
		"outputs": [
			{
				"components": [
					{
						"internalType": "uint256",
						"name": "callProvided",
						"type": "uint256"
					},
					{
						"internalType": "uint256",
						"name": "callUsed",
						"type": "uint256"
					},
					{
						"internalType": "uint256",
						"name": "callUsedITM",
						"type": "uint256"
					},
					{
						"internalType": "uint256",
						"name": "callAvailable",
						"type": "uint256"
					},
					{
						"internalType": "uint256",
						"name": "callReturned",
						"type": "uint256"
					},
					{
						"internalType": "uint256",
						"name": "putProvided",
						"type": "uint256"
					},
					{
						"internalType": "uint256",
						"name": "putUsed",
						"type": "uint256"
					},
					{
						"internalType": "uint256",
						"name": "putUsedITM",
						"type": "uint256"
					},
					{
						"internalType": "uint256",
						"name": "putAvailable",
						"type": "uint256"
					},
					{
						"internalType": "uint256",
						"name": "putReturned",
						"type": "uint256"
					}
				],
				"internalType": "struct UserInfos.UserLpInfos",
				"name": "",
				"type": "tuple"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "uint256",
				"name": "_x",
				"type": "uint256"
			},
			{
				"internalType": "uint256[]",
				"name": "_array",
				"type": "uint256[]"
			}
		],
		"name": "isPartOf",
		"outputs": [
			{
				"internalType": "bool",
				"name": "",
				"type": "bool"
			}
		],
		"stateMutability": "pure",
		"type": "function"
	}
];

const UserHelper_ADDRESS = "0x68b2E8E513070aE55C6dBb70e373d30d26A16793";
const UserHelperABI = [
	{
		"inputs": [],
		"name": "claimAllAutoReplaceRewards",
		"outputs": [],
		"stateMutability": "nonpayable",
		"type": "function"
	},
	{
		"inputs": [],
		"name": "claimAllNonAutoReplaceRewards",
		"outputs": [],
		"stateMutability": "nonpayable",
		"type": "function"
	},
	{
		"inputs": [],
		"name": "claimAllRewards",
		"outputs": [],
		"stateMutability": "nonpayable",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "address",
				"name": "_main",
				"type": "address"
			},
			{
				"internalType": "address",
				"name": "_autoReplacer",
				"type": "address"
			}
		],
		"stateMutability": "nonpayable",
		"type": "constructor"
	}
];

const MarketcbBTC_ADDRESS = "0x5B95565D8A88Bbc7aE8b4aE0403BD847BeF59f8c";
const MarketcbBTCABI = [
	{
		"inputs": [
			{
				"internalType": "address",
				"name": "_main",
				"type": "address"
			},
			{
				"internalType": "address",
				"name": "_tokenA",
				"type": "address"
			},
			{
				"internalType": "uint8",
				"name": "_tokenADecimals",
				"type": "uint8"
			},
			{
				"internalType": "address",
				"name": "_tokenB",
				"type": "address"
			},
			{
				"internalType": "uint8",
				"name": "_tokenBDecimals",
				"type": "uint8"
			},
			{
				"internalType": "address",
				"name": "_pricefeed",
				"type": "address"
			},
			{
				"internalType": "uint256",
				"name": "_pricefeedDecimal",
				"type": "uint256"
			},
			{
				"internalType": "uint256",
				"name": "_intervalLength",
				"type": "uint256"
			},
			{
				"internalType": "uint256",
				"name": "_range",
				"type": "uint256"
			},
			{
				"internalType": "uint256",
				"name": "_yield",
				"type": "uint256"
			}
		],
		"stateMutability": "nonpayable",
		"type": "constructor"
	},
	{
		"anonymous": false,
		"inputs": [
			{
				"indexed": true,
				"internalType": "address",
				"name": "user",
				"type": "address"
			},
			{
				"indexed": false,
				"internalType": "uint256",
				"name": "contractId",
				"type": "uint256"
			},
			{
				"indexed": false,
				"internalType": "uint256",
				"name": "amount",
				"type": "uint256"
			}
		],
		"name": "ContractClosed",
		"type": "event"
	},
	{
		"anonymous": false,
		"inputs": [
			{
				"indexed": true,
				"internalType": "address",
				"name": "user",
				"type": "address"
			},
			{
				"indexed": false,
				"internalType": "bool",
				"name": "isCall",
				"type": "bool"
			},
			{
				"indexed": false,
				"internalType": "uint256",
				"name": "amount",
				"type": "uint256"
			},
			{
				"indexed": false,
				"internalType": "uint256",
				"name": "strike",
				"type": "uint256"
			},
			{
				"indexed": false,
				"internalType": "uint256",
				"name": "contractId",
				"type": "uint256"
			}
		],
		"name": "ContractOpened",
		"type": "event"
	},
	{
		"anonymous": false,
		"inputs": [
			{
				"indexed": true,
				"internalType": "address",
				"name": "user",
				"type": "address"
			},
			{
				"indexed": false,
				"internalType": "bool",
				"name": "isCall",
				"type": "bool"
			},
			{
				"indexed": false,
				"internalType": "uint256",
				"name": "amount",
				"type": "uint256"
			},
			{
				"indexed": false,
				"internalType": "uint256",
				"name": "strike",
				"type": "uint256"
			},
			{
				"indexed": false,
				"internalType": "uint256",
				"name": "lpId",
				"type": "uint256"
			}
		],
		"name": "Deposit",
		"type": "event"
	},
	{
		"anonymous": false,
		"inputs": [
			{
				"indexed": true,
				"internalType": "address",
				"name": "user",
				"type": "address"
			},
			{
				"indexed": false,
				"internalType": "uint256",
				"name": "lpId",
				"type": "uint256"
			},
			{
				"indexed": false,
				"internalType": "uint256",
				"name": "amountA",
				"type": "uint256"
			},
			{
				"indexed": false,
				"internalType": "uint256",
				"name": "amountB",
				"type": "uint256"
			}
		],
		"name": "Withdraw",
		"type": "event"
	},
	{
		"inputs": [
			{
				"internalType": "uint256",
				"name": "_id",
				"type": "uint256"
			}
		],
		"name": "claimRewards",
		"outputs": [
			{
				"internalType": "uint256",
				"name": "",
				"type": "uint256"
			}
		],
		"stateMutability": "nonpayable",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "uint256",
				"name": "_id",
				"type": "uint256"
			}
		],
		"name": "closeContract",
		"outputs": [],
		"stateMutability": "nonpayable",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "bool",
				"name": "_isCall",
				"type": "bool"
			},
			{
				"internalType": "uint256",
				"name": "_amount",
				"type": "uint256"
			}
		],
		"name": "deposit",
		"outputs": [
			{
				"internalType": "uint256",
				"name": "",
				"type": "uint256"
			}
		],
		"stateMutability": "nonpayable",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "uint256",
				"name": "_id",
				"type": "uint256"
			}
		],
		"name": "getContractInfos",
		"outputs": [
			{
				"components": [
					{
						"internalType": "bool",
						"name": "isCall",
						"type": "bool"
					},
					{
						"internalType": "uint256",
						"name": "strike",
						"type": "uint256"
					},
					{
						"internalType": "uint256",
						"name": "amount",
						"type": "uint256"
					},
					{
						"internalType": "uint256",
						"name": "rent",
						"type": "uint256"
					},
					{
						"internalType": "uint256",
						"name": "start",
						"type": "uint256"
					}
				],
				"internalType": "struct MarketPool.ContractInfos",
				"name": "",
				"type": "tuple"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [],
		"name": "getERC721_Contract",
		"outputs": [
			{
				"internalType": "address",
				"name": "",
				"type": "address"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [],
		"name": "getERC721_LP",
		"outputs": [
			{
				"internalType": "address",
				"name": "",
				"type": "address"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [],
		"name": "getIntervalLength",
		"outputs": [
			{
				"internalType": "uint256",
				"name": "",
				"type": "uint256"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [],
		"name": "getIntervals",
		"outputs": [
			{
				"internalType": "uint256[]",
				"name": "",
				"type": "uint256[]"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "uint256",
				"name": "_id",
				"type": "uint256"
			}
		],
		"name": "getLpInfos",
		"outputs": [
			{
				"components": [
					{
						"internalType": "bool",
						"name": "isCall",
						"type": "bool"
					},
					{
						"internalType": "uint256",
						"name": "strike",
						"type": "uint256"
					},
					{
						"internalType": "uint256",
						"name": "amount",
						"type": "uint256"
					},
					{
						"internalType": "uint256",
						"name": "start",
						"type": "uint256"
					},
					{
						"internalType": "uint256",
						"name": "lastClaim",
						"type": "uint256"
					}
				],
				"internalType": "struct MarketPool.LpInfos",
				"name": "",
				"type": "tuple"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [],
		"name": "getMain",
		"outputs": [
			{
				"internalType": "address",
				"name": "",
				"type": "address"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [],
		"name": "getPrice",
		"outputs": [
			{
				"internalType": "uint256",
				"name": "",
				"type": "uint256"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [],
		"name": "getPriceFeed",
		"outputs": [
			{
				"internalType": "address",
				"name": "",
				"type": "address"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [],
		"name": "getRange",
		"outputs": [
			{
				"internalType": "uint256",
				"name": "",
				"type": "uint256"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "uint256",
				"name": "_id",
				"type": "uint256"
			}
		],
		"name": "getRewards",
		"outputs": [
			{
				"internalType": "uint256",
				"name": "",
				"type": "uint256"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "uint256",
				"name": "_strike",
				"type": "uint256"
			},
			{
				"internalType": "uint256",
				"name": "_index",
				"type": "uint256"
			}
		],
		"name": "getStrikeHistory",
		"outputs": [
			{
				"components": [
					{
						"internalType": "uint256",
						"name": "callLP",
						"type": "uint256"
					},
					{
						"internalType": "uint256",
						"name": "callLU",
						"type": "uint256"
					},
					{
						"internalType": "uint256",
						"name": "callLR",
						"type": "uint256"
					},
					{
						"internalType": "uint256",
						"name": "putLP",
						"type": "uint256"
					},
					{
						"internalType": "uint256",
						"name": "putLU",
						"type": "uint256"
					},
					{
						"internalType": "uint256",
						"name": "putLR",
						"type": "uint256"
					},
					{
						"internalType": "uint256",
						"name": "updateCount",
						"type": "uint256"
					},
					{
						"internalType": "uint256",
						"name": "updated",
						"type": "uint256"
					}
				],
				"internalType": "struct MarketPool.StrikeInfos",
				"name": "",
				"type": "tuple"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "uint256",
				"name": "_strike",
				"type": "uint256"
			}
		],
		"name": "getStrikeInfos",
		"outputs": [
			{
				"components": [
					{
						"internalType": "uint256",
						"name": "callLP",
						"type": "uint256"
					},
					{
						"internalType": "uint256",
						"name": "callLU",
						"type": "uint256"
					},
					{
						"internalType": "uint256",
						"name": "callLR",
						"type": "uint256"
					},
					{
						"internalType": "uint256",
						"name": "putLP",
						"type": "uint256"
					},
					{
						"internalType": "uint256",
						"name": "putLU",
						"type": "uint256"
					},
					{
						"internalType": "uint256",
						"name": "putLR",
						"type": "uint256"
					},
					{
						"internalType": "uint256",
						"name": "updateCount",
						"type": "uint256"
					},
					{
						"internalType": "uint256",
						"name": "updated",
						"type": "uint256"
					}
				],
				"internalType": "struct MarketPool.StrikeInfos",
				"name": "",
				"type": "tuple"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [],
		"name": "getTokenA",
		"outputs": [
			{
				"internalType": "address",
				"name": "",
				"type": "address"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [],
		"name": "getTokenB",
		"outputs": [
			{
				"internalType": "address",
				"name": "",
				"type": "address"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [],
		"name": "getYield",
		"outputs": [
			{
				"internalType": "uint256",
				"name": "",
				"type": "uint256"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "uint256",
				"name": "_id",
				"type": "uint256"
			}
		],
		"name": "liquidateContract",
		"outputs": [],
		"stateMutability": "nonpayable",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "bool",
				"name": "_isCall",
				"type": "bool"
			},
			{
				"internalType": "uint256",
				"name": "_strikeIndex",
				"type": "uint256"
			},
			{
				"internalType": "uint256",
				"name": "_amount",
				"type": "uint256"
			}
		],
		"name": "openContract",
		"outputs": [],
		"stateMutability": "nonpayable",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "uint256",
				"name": "_length",
				"type": "uint256"
			}
		],
		"name": "setIntervalLength",
		"outputs": [],
		"stateMutability": "nonpayable",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "address",
				"name": "_priceFeed",
				"type": "address"
			},
			{
				"internalType": "uint256",
				"name": "_decimal",
				"type": "uint256"
			}
		],
		"name": "setPriceFeed",
		"outputs": [],
		"stateMutability": "nonpayable",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "uint256",
				"name": "_range",
				"type": "uint256"
			}
		],
		"name": "setRange",
		"outputs": [],
		"stateMutability": "nonpayable",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "uint256",
				"name": "_yield",
				"type": "uint256"
			}
		],
		"name": "setYield",
		"outputs": [],
		"stateMutability": "nonpayable",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "uint256",
				"name": "_id",
				"type": "uint256"
			}
		],
		"name": "withdraw",
		"outputs": [
			{
				"internalType": "uint256",
				"name": "",
				"type": "uint256"
			},
			{
				"internalType": "uint256",
				"name": "",
				"type": "uint256"
			},
			{
				"internalType": "uint256",
				"name": "",
				"type": "uint256"
			}
		],
		"stateMutability": "nonpayable",
		"type": "function"
	}
];

const AutoReplacer_ADDRESS = "0x946721194882aaDf08eF86ADfAB9FFd0F90b65Ee";
const AutoReplacerABI = [
	{
		"inputs": [
			{
				"internalType": "uint256",
				"name": "_replacerID",
				"type": "uint256"
			}
		],
		"name": "claimRewards",
		"outputs": [
			{
				"internalType": "uint256",
				"name": "",
				"type": "uint256"
			}
		],
		"stateMutability": "nonpayable",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "uint256",
				"name": "_replacerID",
				"type": "uint256"
			}
		],
		"name": "replace",
		"outputs": [],
		"stateMutability": "nonpayable",
		"type": "function"
	},
	{
		"inputs": [],
		"name": "replaceAll",
		"outputs": [],
		"stateMutability": "nonpayable",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "uint256",
				"name": "_index",
				"type": "uint256"
			},
			{
				"internalType": "uint256",
				"name": "_id",
				"type": "uint256"
			}
		],
		"name": "startAutoReplace",
		"outputs": [],
		"stateMutability": "nonpayable",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "uint256",
				"name": "_replacerID",
				"type": "uint256"
			}
		],
		"name": "stopAutoReplace",
		"outputs": [
			{
				"internalType": "uint256",
				"name": "",
				"type": "uint256"
			}
		],
		"stateMutability": "nonpayable",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "address",
				"name": "_main",
				"type": "address"
			}
		],
		"stateMutability": "nonpayable",
		"type": "constructor"
	},
	{
		"inputs": [
			{
				"internalType": "uint256",
				"name": "_replacerID",
				"type": "uint256"
			}
		],
		"name": "getAutoReplaceInfos",
		"outputs": [
			{
				"components": [
					{
						"internalType": "uint256",
						"name": "index",
						"type": "uint256"
					},
					{
						"internalType": "uint256",
						"name": "id",
						"type": "uint256"
					},
					{
						"internalType": "uint256",
						"name": "rewards",
						"type": "uint256"
					}
				],
				"internalType": "struct AutoReplacer.AutoReplaceInfos",
				"name": "",
				"type": "tuple"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [],
		"name": "getERC721_AutoReplace",
		"outputs": [
			{
				"internalType": "address",
				"name": "",
				"type": "address"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "uint256",
				"name": "_index",
				"type": "uint256"
			},
			{
				"internalType": "uint256",
				"name": "_id",
				"type": "uint256"
			}
		],
		"name": "GetWithdrawableForLPForMaket",
		"outputs": [
			{
				"internalType": "uint256",
				"name": "",
				"type": "uint256"
			},
			{
				"internalType": "uint256",
				"name": "",
				"type": "uint256"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "address",
				"name": "operator",
				"type": "address"
			},
			{
				"internalType": "address",
				"name": "from",
				"type": "address"
			},
			{
				"internalType": "uint256",
				"name": "tokenId",
				"type": "uint256"
			},
			{
				"internalType": "bytes",
				"name": "data",
				"type": "bytes"
			}
		],
		"name": "onERC721Received",
		"outputs": [
			{
				"internalType": "bytes4",
				"name": "",
				"type": "bytes4"
			}
		],
		"stateMutability": "pure",
		"type": "function"
	}
];

const AutoReplacerInfos_ADDRESS = "0x7CF8cE3287987d89BcD89C79A6B728184589288F";
const AutoReplacerInfosABI = [
	{
		"inputs": [
			{
				"internalType": "address",
				"name": "_main",
				"type": "address"
			},
			{
				"internalType": "address",
				"name": "_autoReplacer",
				"type": "address"
			}
		],
		"stateMutability": "nonpayable",
		"type": "constructor"
	},
	{
		"inputs": [
			{
				"internalType": "address",
				"name": "_lp",
				"type": "address"
			}
		],
		"name": "getEstimatedYearlyEarningsForLP",
		"outputs": [
			{
				"internalType": "uint256",
				"name": "",
				"type": "uint256"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "uint256",
				"name": "_index",
				"type": "uint256"
			}
		],
		"name": "getMarketAssetPrice",
		"outputs": [
			{
				"internalType": "uint256",
				"name": "",
				"type": "uint256"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "address",
				"name": "_lp",
				"type": "address"
			}
		],
		"name": "getTotalOpenInterestForLP",
		"outputs": [
			{
				"internalType": "uint256",
				"name": "",
				"type": "uint256"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "address",
				"name": "_lp",
				"type": "address"
			}
		],
		"name": "getTotalRewardsForLP",
		"outputs": [
			{
				"internalType": "uint256",
				"name": "",
				"type": "uint256"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "uint256",
				"name": "_index",
				"type": "uint256"
			},
			{
				"internalType": "address",
				"name": "_user",
				"type": "address"
			},
			{
				"internalType": "uint256",
				"name": "_strike",
				"type": "uint256"
			}
		],
		"name": "GetUserLpAmountsForStrikeForMarket",
		"outputs": [
			{
				"internalType": "uint256[]",
				"name": "",
				"type": "uint256[]"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "uint256",
				"name": "_index",
				"type": "uint256"
			},
			{
				"internalType": "address",
				"name": "_user",
				"type": "address"
			}
		],
		"name": "getUserLpInfosForMarket",
		"outputs": [
			{
				"components": [
					{
						"internalType": "uint256",
						"name": "callProvided",
						"type": "uint256"
					},
					{
						"internalType": "uint256",
						"name": "callUsed",
						"type": "uint256"
					},
					{
						"internalType": "uint256",
						"name": "callUsedITM",
						"type": "uint256"
					},
					{
						"internalType": "uint256",
						"name": "callAvailable",
						"type": "uint256"
					},
					{
						"internalType": "uint256",
						"name": "callReturned",
						"type": "uint256"
					},
					{
						"internalType": "uint256",
						"name": "putProvided",
						"type": "uint256"
					},
					{
						"internalType": "uint256",
						"name": "putUsed",
						"type": "uint256"
					},
					{
						"internalType": "uint256",
						"name": "putUsedITM",
						"type": "uint256"
					},
					{
						"internalType": "uint256",
						"name": "putAvailable",
						"type": "uint256"
					},
					{
						"internalType": "uint256",
						"name": "putReturned",
						"type": "uint256"
					}
				],
				"internalType": "struct AutoReplacerInfos.UserLpInfos",
				"name": "",
				"type": "tuple"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "uint256",
				"name": "_index",
				"type": "uint256"
			},
			{
				"internalType": "address",
				"name": "_user",
				"type": "address"
			}
		],
		"name": "GetUserLpInfosListForMarket",
		"outputs": [
			{
				"components": [
					{
						"internalType": "bool",
						"name": "isCall",
						"type": "bool"
					},
					{
						"internalType": "uint256",
						"name": "strike",
						"type": "uint256"
					},
					{
						"internalType": "uint256",
						"name": "amount",
						"type": "uint256"
					},
					{
						"internalType": "uint256",
						"name": "start",
						"type": "uint256"
					},
					{
						"internalType": "uint256",
						"name": "lastClaim",
						"type": "uint256"
					}
				],
				"internalType": "struct IMarketPool.LpInfos[]",
				"name": "",
				"type": "tuple[]"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "address",
				"name": "_lp",
				"type": "address"
			}
		],
		"name": "GetUserLps",
		"outputs": [
			{
				"components": [
					{
						"internalType": "uint256",
						"name": "index",
						"type": "uint256"
					},
					{
						"internalType": "uint256",
						"name": "ID",
						"type": "uint256"
					},
					{
						"internalType": "bool",
						"name": "isCall",
						"type": "bool"
					},
					{
						"internalType": "uint256",
						"name": "strike",
						"type": "uint256"
					},
					{
						"internalType": "uint256",
						"name": "amount",
						"type": "uint256"
					},
					{
						"internalType": "uint256",
						"name": "start",
						"type": "uint256"
					},
					{
						"internalType": "uint256",
						"name": "lastClaim",
						"type": "uint256"
					},
					{
						"internalType": "bool",
						"name": "isITM",
						"type": "bool"
					},
					{
						"internalType": "uint256",
						"name": "value",
						"type": "uint256"
					},
					{
						"internalType": "uint256",
						"name": "withdrawableTokenA",
						"type": "uint256"
					},
					{
						"internalType": "uint256",
						"name": "withdrawableTokenB",
						"type": "uint256"
					}
				],
				"internalType": "struct AutoReplacerInfos.UserLp[]",
				"name": "",
				"type": "tuple[]"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "uint256",
				"name": "_index",
				"type": "uint256"
			},
			{
				"internalType": "address",
				"name": "_user",
				"type": "address"
			}
		],
		"name": "GetUserLpStrikesForMarket",
		"outputs": [
			{
				"internalType": "uint256[]",
				"name": "",
				"type": "uint256[]"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "uint256",
				"name": "_index",
				"type": "uint256"
			},
			{
				"internalType": "uint256",
				"name": "_id",
				"type": "uint256"
			}
		],
		"name": "GetWithdrawableForLPForMaket",
		"outputs": [
			{
				"internalType": "uint256",
				"name": "",
				"type": "uint256"
			},
			{
				"internalType": "uint256",
				"name": "",
				"type": "uint256"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "uint256",
				"name": "_x",
				"type": "uint256"
			},
			{
				"internalType": "uint256[]",
				"name": "_array",
				"type": "uint256[]"
			}
		],
		"name": "isPartOf",
		"outputs": [
			{
				"internalType": "bool",
				"name": "",
				"type": "bool"
			}
		],
		"stateMutability": "pure",
		"type": "function"
	}
];

const ERC20_ABI = [
    {
        "constant": true,
        "inputs": [
            { "name": "_owner", "type": "address" },
            { "name": "_spender", "type": "address" }
        ],
        "name": "allowance",
        "outputs": [{ "name": "", "type": "uint256" }],
        "stateMutability": "view",
        "type": "function"
    },
    {
        "constant": false,
        "inputs": [
            { "name": "_spender", "type": "address" },
            { "name": "_value", "type": "uint256" }
        ],
        "name": "approve",
        "outputs": [{ "name": "", "type": "bool" }],
        "stateMutability": "nonpayable",
        "type": "function"
    }
];

const ERC721_ABI = [
	{
		"inputs": [
			{
				"internalType": "address",
				"name": "_autoReplacer",
				"type": "address"
			},
			{
				"internalType": "string",
				"name": "_name",
				"type": "string"
			},
			{
				"internalType": "string",
				"name": "_symbol",
				"type": "string"
			}
		],
		"stateMutability": "nonpayable",
		"type": "constructor"
	},
	{
		"inputs": [],
		"name": "ERC721EnumerableForbiddenBatchMint",
		"type": "error"
	},
	{
		"inputs": [
			{
				"internalType": "address",
				"name": "sender",
				"type": "address"
			},
			{
				"internalType": "uint256",
				"name": "tokenId",
				"type": "uint256"
			},
			{
				"internalType": "address",
				"name": "owner",
				"type": "address"
			}
		],
		"name": "ERC721IncorrectOwner",
		"type": "error"
	},
	{
		"inputs": [
			{
				"internalType": "address",
				"name": "operator",
				"type": "address"
			},
			{
				"internalType": "uint256",
				"name": "tokenId",
				"type": "uint256"
			}
		],
		"name": "ERC721InsufficientApproval",
		"type": "error"
	},
	{
		"inputs": [
			{
				"internalType": "address",
				"name": "approver",
				"type": "address"
			}
		],
		"name": "ERC721InvalidApprover",
		"type": "error"
	},
	{
		"inputs": [
			{
				"internalType": "address",
				"name": "operator",
				"type": "address"
			}
		],
		"name": "ERC721InvalidOperator",
		"type": "error"
	},
	{
		"inputs": [
			{
				"internalType": "address",
				"name": "owner",
				"type": "address"
			}
		],
		"name": "ERC721InvalidOwner",
		"type": "error"
	},
	{
		"inputs": [
			{
				"internalType": "address",
				"name": "receiver",
				"type": "address"
			}
		],
		"name": "ERC721InvalidReceiver",
		"type": "error"
	},
	{
		"inputs": [
			{
				"internalType": "address",
				"name": "sender",
				"type": "address"
			}
		],
		"name": "ERC721InvalidSender",
		"type": "error"
	},
	{
		"inputs": [
			{
				"internalType": "uint256",
				"name": "tokenId",
				"type": "uint256"
			}
		],
		"name": "ERC721NonexistentToken",
		"type": "error"
	},
	{
		"inputs": [
			{
				"internalType": "address",
				"name": "owner",
				"type": "address"
			},
			{
				"internalType": "uint256",
				"name": "index",
				"type": "uint256"
			}
		],
		"name": "ERC721OutOfBoundsIndex",
		"type": "error"
	},
	{
		"anonymous": false,
		"inputs": [
			{
				"indexed": true,
				"internalType": "address",
				"name": "owner",
				"type": "address"
			},
			{
				"indexed": true,
				"internalType": "address",
				"name": "approved",
				"type": "address"
			},
			{
				"indexed": true,
				"internalType": "uint256",
				"name": "tokenId",
				"type": "uint256"
			}
		],
		"name": "Approval",
		"type": "event"
	},
	{
		"anonymous": false,
		"inputs": [
			{
				"indexed": true,
				"internalType": "address",
				"name": "owner",
				"type": "address"
			},
			{
				"indexed": true,
				"internalType": "address",
				"name": "operator",
				"type": "address"
			},
			{
				"indexed": false,
				"internalType": "bool",
				"name": "approved",
				"type": "bool"
			}
		],
		"name": "ApprovalForAll",
		"type": "event"
	},
	{
		"anonymous": false,
		"inputs": [
			{
				"indexed": true,
				"internalType": "address",
				"name": "from",
				"type": "address"
			},
			{
				"indexed": true,
				"internalType": "address",
				"name": "to",
				"type": "address"
			},
			{
				"indexed": true,
				"internalType": "uint256",
				"name": "tokenId",
				"type": "uint256"
			}
		],
		"name": "Transfer",
		"type": "event"
	},
	{
		"inputs": [
			{
				"internalType": "address",
				"name": "to",
				"type": "address"
			},
			{
				"internalType": "uint256",
				"name": "tokenId",
				"type": "uint256"
			}
		],
		"name": "approve",
		"outputs": [],
		"stateMutability": "nonpayable",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "address",
				"name": "owner",
				"type": "address"
			}
		],
		"name": "balanceOf",
		"outputs": [
			{
				"internalType": "uint256",
				"name": "",
				"type": "uint256"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "uint256",
				"name": "tokenId",
				"type": "uint256"
			}
		],
		"name": "burn",
		"outputs": [],
		"stateMutability": "nonpayable",
		"type": "function"
	},
	{
		"inputs": [],
		"name": "getAllTokenIds",
		"outputs": [
			{
				"internalType": "uint256[]",
				"name": "",
				"type": "uint256[]"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "uint256",
				"name": "tokenId",
				"type": "uint256"
			}
		],
		"name": "getApproved",
		"outputs": [
			{
				"internalType": "address",
				"name": "",
				"type": "address"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [],
		"name": "getOwners",
		"outputs": [
			{
				"internalType": "address[]",
				"name": "",
				"type": "address[]"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "address",
				"name": "owner",
				"type": "address"
			},
			{
				"internalType": "address",
				"name": "operator",
				"type": "address"
			}
		],
		"name": "isApprovedForAll",
		"outputs": [
			{
				"internalType": "bool",
				"name": "",
				"type": "bool"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "address",
				"name": "_x",
				"type": "address"
			},
			{
				"internalType": "address[]",
				"name": "_array",
				"type": "address[]"
			}
		],
		"name": "isPartOf",
		"outputs": [
			{
				"internalType": "bool",
				"name": "",
				"type": "bool"
			}
		],
		"stateMutability": "pure",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "address",
				"name": "_to",
				"type": "address"
			},
			{
				"internalType": "uint256",
				"name": "_id",
				"type": "uint256"
			}
		],
		"name": "mint",
		"outputs": [],
		"stateMutability": "nonpayable",
		"type": "function"
	},
	{
		"inputs": [],
		"name": "name",
		"outputs": [
			{
				"internalType": "string",
				"name": "",
				"type": "string"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "uint256",
				"name": "tokenId",
				"type": "uint256"
			}
		],
		"name": "ownerOf",
		"outputs": [
			{
				"internalType": "address",
				"name": "",
				"type": "address"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "address",
				"name": "from",
				"type": "address"
			},
			{
				"internalType": "address",
				"name": "to",
				"type": "address"
			},
			{
				"internalType": "uint256",
				"name": "tokenId",
				"type": "uint256"
			}
		],
		"name": "safeTransferFrom",
		"outputs": [],
		"stateMutability": "nonpayable",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "address",
				"name": "from",
				"type": "address"
			},
			{
				"internalType": "address",
				"name": "to",
				"type": "address"
			},
			{
				"internalType": "uint256",
				"name": "tokenId",
				"type": "uint256"
			},
			{
				"internalType": "bytes",
				"name": "data",
				"type": "bytes"
			}
		],
		"name": "safeTransferFrom",
		"outputs": [],
		"stateMutability": "nonpayable",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "address",
				"name": "operator",
				"type": "address"
			},
			{
				"internalType": "bool",
				"name": "approved",
				"type": "bool"
			}
		],
		"name": "setApprovalForAll",
		"outputs": [],
		"stateMutability": "nonpayable",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "bytes4",
				"name": "interfaceId",
				"type": "bytes4"
			}
		],
		"name": "supportsInterface",
		"outputs": [
			{
				"internalType": "bool",
				"name": "",
				"type": "bool"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [],
		"name": "symbol",
		"outputs": [
			{
				"internalType": "string",
				"name": "",
				"type": "string"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "uint256",
				"name": "index",
				"type": "uint256"
			}
		],
		"name": "tokenByIndex",
		"outputs": [
			{
				"internalType": "uint256",
				"name": "",
				"type": "uint256"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "address",
				"name": "owner",
				"type": "address"
			},
			{
				"internalType": "uint256",
				"name": "index",
				"type": "uint256"
			}
		],
		"name": "tokenOfOwnerByIndex",
		"outputs": [
			{
				"internalType": "uint256",
				"name": "",
				"type": "uint256"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "uint256",
				"name": "tokenId",
				"type": "uint256"
			}
		],
		"name": "tokenURI",
		"outputs": [
			{
				"internalType": "string",
				"name": "",
				"type": "string"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [],
		"name": "totalSupply",
		"outputs": [
			{
				"internalType": "uint256",
				"name": "",
				"type": "uint256"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "address",
				"name": "from",
				"type": "address"
			},
			{
				"internalType": "address",
				"name": "to",
				"type": "address"
			},
			{
				"internalType": "uint256",
				"name": "tokenId",
				"type": "uint256"
			}
		],
		"name": "transferFrom",
		"outputs": [],
		"stateMutability": "nonpayable",
		"type": "function"
	}
];

// Get Price from marketPool
export const getBtcPrice = async () => {
    try {
        const contract = await getMarketPoolcbBTC_ReadOnly();
        if (!contract) return null;

        const price = await contract.getPrice();
        const parsedPrice = parseFloat(formatUnits(price, 18)).toFixed(2);

        return parseFloat(parsedPrice); // Ensures it's a number, not a string

    } catch (error) {
        console.error("Error fetching price:", error);
        return null;
    }
};


// Function to get the allowance of a token for a specific contract
export const getAllowance = async (tokenAddress, spender) => {
    const signer = await getSigner();
    if (!signer) return null;
	const userAddress = await signer.getAddress();

    const tokenContract = new Contract(tokenAddress, ERC20_ABI, signer);
    return await tokenContract.allowance(userAddress, spender);
};

export const getERC721Allowance = async (tokenAddress, id) => {
    const signer = await getSigner();
    if (!signer) return null;

    const tokenContract = new Contract(tokenAddress, ERC721_ABI, signer);
    return await tokenContract.getApproved(id);
};

// Function to approve a contract to spend a specific amount of tokens
export const approveTokens = async (tokenAddress, spender, amount) => {
    const signer = await getSigner();
    if (!signer) return null;

    const tokenContract = new Contract(tokenAddress, ERC20_ABI, signer);
    const tx = await tokenContract.approve(spender, amount);
    await tx.wait();
    return tx;
};

export const approveERC721 = async (tokenAddress, spender, id) => {
    const signer = await getSigner();
    if (!signer) return null;

    const tokenContract = new Contract(tokenAddress, ERC721_ABI, signer);
    const tx = await tokenContract.approve(spender, id);
    await tx.wait();
    return tx;
};

// Connect to MetaMask
export const getProvider = async () => {
    if (window.ethereum) {
        const provider = new BrowserProvider(window.ethereum);
        await window.ethereum.request({ method: "eth_requestAccounts" });
        return provider;
    } else {
        return null;
    }
};

// Get signer (user's account)
export const getSigner = async () => {
    const provider = await getProvider();
    return provider ? await provider.getSigner() : null;
};

// Get contract instance
export const getCollateralPool = async () => {
    const signer = await getSigner();
    return signer ? new Contract(CollateralPool_ADDRESS, CollateralPoolABI, signer) : null;
};

export const getProtocolInfos = async () => {
    const signer = await getSigner();
    return signer ? new Contract(ProtocolInfos_ADDRESS, ProtocolInfosABI, signer) : null;
};

export const getUserInfosContract = async () => {
    const signer = await getSigner();
    return signer ? new Contract(UserInfos_ADDRESS, UserInfosABI, signer) : null;
};

export const getUserHelper = async () => {
    const signer = await getSigner();
    return signer ? new Contract(UserHelper_ADDRESS, UserHelperABI, signer) : null;
};

export const getMarketPoolcbBTC = async () => {
    const signer = await getSigner();
    return signer ? new Contract(MarketcbBTC_ADDRESS, MarketcbBTCABI, signer) : null;
};

export const getMarketPoolWETH = async () => {
    const signer = await getSigner();
    return signer ? new Contract(MarketcbBTC_ADDRESS, MarketcbBTCABI, signer) : null;
};

export const getAutoReplacer = async () => {
    const signer = await getSigner();
    return signer ? new Contract(AutoReplacer_ADDRESS, AutoReplacerABI, signer) : null;
};

export const getAutoReplacerInfos = async () => {
    const signer = await getSigner();
    return signer ? new Contract(AutoReplacerInfos_ADDRESS, AutoReplacerInfosABI, signer) : null;
};

export const getERC721 = async (addr) => {
    const signer = await getSigner();
    return signer ? new Contract(addr, ERC721_ABI, signer) : null;
};

export const getUserInfos = async () => {
    try {
        const collateralPool = await getCollateralPool();
        if (!collateralPool) return null;

        const userInfosContract = await getUserInfosContract();
        if (!userInfosContract) return null;

		const autoreplacerInfosContract = await getAutoReplacerInfos();
        if (!autoreplacerInfosContract) return null;

        const signer = await getSigner();
        const userAddress = await signer.getAddress();

        // Fetch user info from contract
        const userInfo = await collateralPool.getUserInfos(userAddress);
        const lpTotalRewards = await userInfosContract.getTotalRewardsForLP(userAddress);
		const lpTotalOI = await userInfosContract.getTotalOpenInterestForLP(userAddress);
		const lpExpectedEarnings = await userInfosContract.getEstimatedYearlyEarningsForLP(userAddress);
        const balance = await collateralPool.balanceOf(userAddress);

        // Fetch liquidity positions for BTC (market ID 0) and ETH (market ID 1)
        const lpList = await userInfosContract.GetUserLps(userAddress);

		// Fetch liquidity positions for BTC (market ID 0) and ETH (market ID 1)
        const contractListBTCMarket = await userInfosContract.GetUserContractsForMarket(0, userAddress);
        const contractListETHMarket = await userInfosContract.GetUserContractsForMarket(1, userAddress);

		// Fetch AutoReplace Infos
		const autoReplaceList = await autoreplacerInfosContract.GetUserLps(userAddress);
		const autoReplaceTotalOI = await autoreplacerInfosContract.getTotalOpenInterestForLP(userAddress);
		const autoReplaceExpectedEarnings = await autoreplacerInfosContract.getEstimatedYearlyEarningsForLP(userAddress);
		const autoReplaceTotalRewards = await autoreplacerInfosContract.getTotalRewardsForLP(userAddress);

		const mergedLpList = [...lpList, ...autoReplaceList];

		const formatContract = (contractList, asset) =>
            contractList.map((contract) => {
				const ID = parseFloat(contract.ID);
                const amount = parseFloat(formatUnits(contract.amount, 18));
                const strikePrice = parseFloat(formatUnits(contract.strike, 18));
                const isCall = contract.isCall;
				const rent = parseFloat(formatUnits(contract.rent, 18));
				const start = contract.start;
				const spent = parseFloat(formatUnits(contract.spent, 18));
				const isITM = contract.isITM;
				const earnings = parseFloat(formatUnits(contract.earnings, 18));

                return {
                    id: ID,
					asset,
                    amount,
                    strikePrice,
                    type: isCall ? "Call" : "Put",
					rent,
					start,
					spent,
					isITM,
					earnings
                };
            });

        // Helper function to determine withdrawable values based on market
        const formatLiquidity = (list) =>
            list.map((lp, i) => {
				const isAutoReplaced = i < lpList.length ? false : true;
				const index = parseFloat(lp.index);
				const ID = parseFloat(lp.ID);
				const market = index === 0 ? "BTC" : "ETH";
                const amount = parseFloat(formatUnits(lp.amount, 18));
                const strikePrice = parseFloat(formatUnits(lp.strike, 18));
                const isCall = lp.isCall;
				const value = parseFloat(formatUnits(lp.value, 18));
				const withdrawableTokenA = parseFloat(formatUnits(lp.withdrawableTokenA, 18));
				const withdrawableTokenB = parseFloat(formatUnits(lp.withdrawableTokenB, 18));

				let valueAsset;
				if (isCall) {
					lp.isITM ? valueAsset = "USDC" : valueAsset = market;
				} else {
					lp.isITM ? valueAsset = market : valueAsset = "USDC";
				}

                return {
					isAutoReplaced,
					index,
                    id: ID,
					market,
                    asset: isCall ? market : "USDC",
                    amount,
                    strikePrice,
                    type: isCall ? "Call" : "Put",
					value,
                    valueAsset,
					withdrawableTokenA,
					withdrawableTokenB,
                };
            });

        return {
            rent: formatUnits(userInfo.rent, 18),
            balance: formatUnits(balance, 18),
            lpTotalRewards: formatUnits(lpTotalRewards + autoReplaceTotalRewards, 18),
			lpTotalOI: formatUnits(lpTotalOI + autoReplaceTotalOI, 18),
			lpExpectedEarnings: formatUnits(lpExpectedEarnings + autoReplaceExpectedEarnings, 18),
			contractPositions: [
                ...formatContract(contractListBTCMarket, "BTC"),
                ...formatContract(contractListETHMarket, "ETH"),
            ],
            liquidityPositions: [
                ...formatLiquidity(mergedLpList),
            ],
        };
    } catch (error) {
        console.error("Error fetching user info:", error);
        return null;
    }
};

export const getStrike = async (isCall) => {
    try {
        const contract = await getMarketPoolcbBTC_ReadOnly();
        if (!contract) return null;

        const intervalLength = await contract.getIntervalLength();
        const strikePrices = await contract.getIntervals();
        const halfInterval = Number(intervalLength) / 2;
        const selectedStrike = isCall
            ? parseFloat(formatUnits(strikePrices[halfInterval], 18))
            : parseFloat(formatUnits(strikePrices[0], 18));

      

        return {
            strikePrice: selectedStrike,
        };

    } catch (error) {
        console.error("Error fetching strike and liquidity:", error);
        return null;
    }
};

export const getStrikesAndLiquidity = async (isCall) => {
    try {
        const contract = await getMarketPoolcbBTC_ReadOnly();
        if (!contract) return null;

        const intervalLength = await contract.getIntervalLength();
        const strikePrices = await contract.getIntervals();
        const halfInterval = Number(intervalLength) / 2;
        const selectedStrikes = isCall
            ? strikePrices.slice(halfInterval, intervalLength)
            : strikePrices.slice(0, halfInterval);

        // Fetch liquidity for each selected strike
        const liquidityPromises = selectedStrikes.map(async (strike) => {
            const strikeInfo = await contract.getStrikeInfos(strike);

            const callLP = strikeInfo.callLP;
            const callLU = strikeInfo.callLU;
            const putLP = strikeInfo.putLP;
            const putLU = strikeInfo.putLU;

            return isCall ? callLP - callLU : putLP - putLU;
        });

        // Resolve all promises
        const availableLiquidity = await Promise.all(liquidityPromises);

        // Filter out strikes with liquidity = 0
        let filteredStrikes = [];
        let filteredLiquidity = [];
        availableLiquidity.forEach((liquidity, index) => {
            if (liquidity > 0) {
                filteredStrikes.push(parseFloat(formatUnits(selectedStrikes[index], 18)));
                filteredLiquidity.push(parseFloat(formatUnits(liquidity, 18)));
            }
        });

        // If all liquidity is zero, return only index 0
        if (filteredStrikes.length === 0) {
            filteredStrikes.push(parseFloat(formatUnits(selectedStrikes[0], 18)));
            filteredLiquidity.push(parseFloat(formatUnits(availableLiquidity[0], 18)));
        }

        return {
            strikePrices: filteredStrikes,
            availableLiquidity: filteredLiquidity,
        };

    } catch (error) {
        console.error("Error fetching strike and liquidity:", error);
        return null;
    }
};



