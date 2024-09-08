# include .env file and export its env vars
# (-include to ignore error if it does not exist)
-include .env

# deps
update:; forge update


deploy-script-savings-factory-rootstock :; forge script scripts/SavingsFactory.s.sol:DeploySavingsFactory --chain 31 --rpc-url rootstock --broadcast --slow --legacy  -vvv --delay 5
deploy-script-savings-rootstock :; forge script scripts/Savings.s.sol:CreateSavings --chain 31 --rpc-url rootstock --broadcast --verify --slow --legacy  -vvv --delay 5
deploy-script-micro-lending-factory-rootstock :; forge script scripts/MicroLendingFactory.s.sol:DeployMicroLendingFactory --chain 31 --rpc-url rootstock --broadcast --slow  -vvv --legacy --delay 5
deploy-script-micro-lending-rootstock :; forge script scripts/MicroLending.s.sol:CreateMicroLending --chain 31 --rpc-url rootstock --broadcast --slow  -vvv --legacy --delay 5
deploy-script-micro-insurance-factory-rootstock :; forge script scripts/MicroInsuranceFactory.s.sol:DeployMicroInsuranceFactory --chain 31 --rpc-url rootstock --broadcast --slow  -vvv --legacy --delay 5
deploy-script-micro-insurance-rootstock :; forge script scripts/MicroInsurance.s.sol:CreateMicroInsurance --chain 31 --rpc-url rootstock --broadcast --slow  -vvv --legacy --delay 5


deploy-script-savings-factory-morph :; forge script scripts/SavingsFactory.s.sol:DeploySavingsFactory --chain 2810 --rpc-url morph --broadcast --slow --legacy  -vvv --delay 5
deploy-script-savings-morph :; forge script scripts/Savings.s.sol:CreateSavings --chain 2810 --rpc-url morph --broadcast --slow --legacy  -vvv --delay 5
deploy-script-micro-lending-factory-morph :; forge script scripts/MicroLendingFactory.s.sol:DeployMicroLendingFactory --chain 2810 --rpc-url morph --broadcast --slow  -vvv --legacy --delay 5
deploy-script-micro-lending-morph :; forge script scripts/MicroLending.s.sol:CreateMicroLending --chain 2810 --rpc-url morph --broadcast --slow  -vvv --legacy --delay 5

deploy-script-savings-factory-sepolia :; forge script scripts/SavingsFactory.s.sol:DeploySavingsFactory --chain 11155111 --rpc-url sepolia --broadcast --slow --legacy  -vvv --delay 5
deploy-script-savings-sepolia :; forge script scripts/Savings.s.sol:CreateSavings --chain 11155111 --rpc-url sepolia --broadcast --slow --legacy  -vvv --delay 5
deploy-script-crosschain-sepolia :; forge script scripts/CrossChain.s.sol:DeployCrossChainManager --chain 11155111 --rpc-url sepolia --broadcast --slow --legacy  -vvv --delay 5
deploy-script-micro-lending-factory-sepolia :; forge script scripts/MicroLendingFactory.s.sol:DeployMicroLendingFactory --chain 11155111 --rpc-url sepolia --broadcast --slow  -vvv --legacy --delay 5
deploy-script-micro-lending-sepolia :; forge script scripts/MicroLending.s.sol:CreateMicroLending --chain 11155111 --rpc-url sepolia --broadcast --slow  -vvv --legacy --delay 5
