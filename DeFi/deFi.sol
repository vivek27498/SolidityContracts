// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract LendingAndBorrowing is Ownable {

    struct Token {
        address tokenAddress;
        string name;
    }

    address tokenAsCollateral; //It can be USDT

    mapping(address => mapping(address => uint256)) public tokensLentAmount;
    mapping(address => mapping(address => uint256)) public tokensBorrowedAmount;
    mapping(address => uint256) public tokensCollateralAmount;
    mapping(address => uint256) public collateralLocked;


    Token[] public tokensForLending;
    Token[] public tokensForBorrowing;

    event TokenAddedInLendingList(string name, address tokenAddress);
    event TokenAddedInBorrowingList(string name, address tokenAddress);
    event Supply(address tokenAddress, uint256 amount, address whoSupplied);
    event TokensWithdrawn(address tokenAddress, uint256 amount, address withdrawl);
    event TokensBorrowed(address tokenAddress, uint256 amount, address borrower);
    event DebtPaid(address tokenAddress, uint256 amount, address borrower);
    event CollateralReleased(uint256 amount, address borrower);

//Functionalities to Admin
//-- Add tokens for Lending
    //-- Struct{TokenName, ContractAddress, Inter.}
    //-- TokenIsAlreadyThere (Modifier)
    //-- Only Admin

    function addTokensForLending(
        string memory name,
        address tokenAddress
    ) public onlyOwner {
        Token memory token = Token(tokenAddress, name);

        if(!tokenIsAlreadyThere(token, tokensForLending)) {
            tokensForLending.push(token);
        }

        emit TokenAddedInLendingList(
            name,
            tokenAddress
        );
    }

    //-- Add Tokens for Borrowing
    //-- Struct{TokenName, ContractAddress, Inter.}
    //-- Only Admin

    function addTokensForBorrowing(
        string memory name,
        address tokenAddress
    ) public onlyOwner {
        Token memory token = Token(tokenAddress, name);

        if(!tokenIsAlreadyThere(token, tokensForBorrowing)) {
            tokensForBorrowing.push(token);
        }

        emit TokenAddedInBorrowingList(
            name,
            tokenAddress
        );
    }

    //-- TokenIsAlreadyThere (Modifier)
    function tokenIsAlreadyThere(Token memory token, Token[] memory tokenArray) 
    private
    pure 
    returns(bool)
    {
        if(tokenArray.length > 0) {
            for(uint256 i = 0; i < tokenArray.length; i++) {
                Token memory currentToken = tokenArray[i];
                if(currentToken.tokenAddress == token.tokenAddress) {
                    return true;
                }
            }
        }

        return false;
    }

//For User
//-- getTokensForLending
    //Returns Array of Tokens

    function getTokensForLendingArray() public view returns (Token[] memory) {
        return tokensForLending;
    }

    //-- getTokensForBorrowing
    //Returns Array of Tokens

    function getTokensForBorrowingArray() public view returns (Token[] memory) {
        return tokensForBorrowing;
    }


//-- ToLend
    //-- IfThatTokenIsAllowedToLend -- Modifier
    //-- EnoughBalance


    function toLend(address tokenAddress, uint256 amount) public {
        require(
            tokenIsAllowed(tokenAddress, tokensForLending),
            "Token is not allowed to lend!"
        );

        require(amount > 0, "The amount to supply should be greater than 0");

        IERC20 token = IERC20(tokenAddress);

        require(
            token.balanceOf(msg.sender) >= amount,
            "You have insufficient number of tokens!"
        );

       require(token.allowance(msg.sender, address(this)) >= amount,
       "Insufficient Allowance!"
       );

        //To check state

        require(token.transferFrom(msg.sender, address(this), amount));
        tokensLentAmount[tokenAddress][msg.sender] += amount;

        emit Supply(
            tokenAddress,
            amount,
            msg.sender
        );
        
    }



    function tokenIsAllowed(address tokenAddress, Token[] memory tokenArray)
    private
    pure 
    returns(bool)
    {
        if(tokenArray.length>0) {
            for(uint256 i = 0; i < tokenArray.length; i++) {
                Token memory currentToken = tokenArray[i];
                if(currentToken.tokenAddress == tokenAddress) {
                    return true;
                }
            }
        }

        return false;
    }


//-- WithdrawLentTokens
    //-- OnlythepersonWhoLendedTokensCanWithdraw
    //-- Enough Token Balance of Our Pool for this particular token.
    //-- amount <= token.balanceOf(address(this)) --
    //-- You should have deposited what you are trying to withdraw

    function withdrawLentTokens(address tokenAddress, uint256 amount) public {
        require(amount>0, "Amount should be greater than zero!");

        uint256 availableToWithdraw = tokensLentAmount[tokenAddress][msg.sender];
        require(amount <= availableToWithdraw, "You dont have enough balance to withdraw!");

        IERC20 token = IERC20(tokenAddress);
        require(amount <= token.balanceOf(address(this)), 
        "Pool doesnt have enough balance!");

        tokensLentAmount[tokenAddress][msg.sender] = tokensLentAmount[tokenAddress][msg.sender] - amount;
        token.transfer(msg.sender, amount);

        emit TokensWithdrawn(
            tokenAddress,
            amount,
            msg.sender
        );

    }

//-- Deposit Collateral
    //-- Check if that token can be deposited as a collateral.

    //Assignment
    // Function to calculate collateral amount (TokenAddress of token you want to borrow, amount)
    // Returns number of USDT that you need to deposit to borrow this amount.

    //You need to deposit 1USDT for every token you want to borrow.
    function depositCollateral(uint256 amount) public { 
        require(amount > 0, "Amount should be greater than 0");

        require(
            IERC20(tokenAsCollateral).balanceOf(msg.sender) >= amount,
            "You have insufficient token to supply that amount!"
        );

        require(IERC20(tokenAsCollateral).transferFrom(msg.sender, address(this), amount));
        tokensCollateralAmount[msg.sender] += amount;

    }

//-- Borrow 
    //If that token is allowed to borrow
    //If you have deposited enough balance as collateral.
    //Pool's balance is enough fot that token

    function borrow(address tokenAddress, uint256 amount) public {
        require(
            tokenIsAllowed(tokenAddress, tokensForBorrowing), 
            "Token is not supported !"
        );

        require(amount > 0, "Amount should be greater zero!");

        require(
            tokensCollateralAmount[msg.sender] - collateralLocked[msg.sender] >= amount,
            "You dont have enough collateral to borrow!"
        );

        IERC20 token = IERC20(tokenAddress);

        require(
            token.balanceOf(address(this)) >= amount,
            "We dont have enough tokens in the pool!"
        );

        tokensBorrowedAmount[tokenAddress][msg.sender] += amount;
        collateralLocked[msg.sender] += amount;
        token.transfer(msg.sender, amount);

        emit TokensBorrowed(
            tokenAddress,
            amount,
            msg.sender
        );
    }


//-- payDept
    //If you have borrowed anything
    //Calculate interest and paythat amount extra

    function toPayDebt(address tokenAddress, uint256 amount) public {

        // require(
        //     tokenIsAllowed(tokenAddress, tokensForBorrowing),
        //     "TokenIsNotSupported!"
        // );

        require(amount>0, "Amount should be greater than 0");

        require(tokensBorrowedAmount[tokenAddress][msg.sender] == 0, "You dont have any debt!");
        require(tokensBorrowedAmount[tokenAddress][msg.sender] >= amount, "You are paying more than you borrowed");

        require(
            IERC20(tokenAddress).balanceOf(msg.sender) >= amount,
            "You have insufficient tokens to supply"
        );

        require(IERC20(tokenAddress).allowance(msg.sender, address(this)) >= amount,
       "Insufficient Allowance!"
       );


        require(IERC20(tokenAddress).transferFrom(msg.sender, address(this), amount));
        tokensBorrowedAmount[tokenAddress][msg.sender] -= amount;
        collateralLocked[msg.sender] -= amount;

        emit DebtPaid (
            tokenAddress,
            amount,
            msg.sender
        );

    }
    


//-- ReleaseCollateral
    //Check freezed collateral
    function releaseCollateral(uint256 amount) public {
        require(amount>0, "Amount should be greater than 0");
        require(tokensCollateralAmount[msg.sender] - collateralLocked[msg.sender] >= amount,
        "Your collateral is locked due to debt!");

        
        require(IERC20(tokenAsCollateral).transfer(msg.sender, amount));
        tokensCollateralAmount[msg.sender] -= amount;
        
        emit CollateralReleased(
            amount,
            msg.sender
        );
    }






}