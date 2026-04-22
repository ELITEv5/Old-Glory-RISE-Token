// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/*
 * @title Old Glory Rise Token - pSunDAI Rewards
 * @notice Yield-bearing token with pSunDAI rewards
 * @dev Battle-tested CST V6 pattern adapted for pSunDAI
 * 
 * @custom:easter-egg
 * - minYield: 0.369 pSunDAI (PulseChain chain ID 369!)
 * - Burn address: 0x369
 * 
 * @custom:version 11.0 PRODUCTION (VORTEX-SAFE SWAPS)
 * @custom:changelog
 * - V11: Fixed swap sizing to use yield balance (no LP reads mid-transfer)
 * - V11: Added MIN_SWAP and MAX_SWAP safety caps
 * - V11: Removed lpFactor (no longer needed)
 */

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address a) external view returns (uint256);
    function transfer(address to, uint256 v) external returns (bool);
    function allowance(address o, address s) external view returns (uint256);
    function approve(address s, uint256 v) external returns (bool);
    function transferFrom(address f, address t, uint256 v) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 v);
    event Approval(address indexed owner, address indexed spender, uint256 v);
}

interface IERC20Metadata is IERC20 {
    function decimals() external view returns (uint8);
}

library SafeERC20 {
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        require(token.transfer(to, value), "SafeERC20: transfer failed");
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed prev, address indexed next);
    constructor() {
        _transferOwnership(_msgSender());
    }
    modifier onlyOwner() {
        require(owner() == _msgSender(), "not owner");
        _;
    }
    function owner() public view returns (address) {
        return _owner;
    }
    function renounceOwnership() public onlyOwner {
        _transferOwnership(address(0));
    }
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "zero");
        _transferOwnership(newOwner);
    }
    function _transferOwnership(address newOwner) internal {
        address old = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(old, newOwner);
    }
}

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status = _NOT_ENTERED;
    modifier nonReentrant() {
        require(_status != _ENTERED, "reentrant");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}

contract ERC20 is Context, IERC20 {
    uint256 internal _totalSupply;
    mapping(address => uint256) internal _balances;
    mapping(address => mapping(address => uint256)) internal _allowances;
    string private _name;
    string private _symbol;
    uint8 private constant _decimals = 18;

    constructor(string memory n, string memory s) {
        _name = n;
        _symbol = s;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address a) public view override returns (uint256) {
        return _balances[a];
    }

    function transfer(address to, uint256 v) public override returns (bool) {
        _transfer(_msgSender(), to, v);
        return true;
    }

    function allowance(address o, address s) public view override returns (uint256) {
        return _allowances[o][s];
    }

    function approve(address s, uint256 v) public override returns (bool) {
        _approve(_msgSender(), s, v);
        return true;
    }

    function transferFrom(address f, address t, uint256 v) public override returns (bool) {
        uint256 curr = _allowances[f][_msgSender()];
        require(curr >= v, "allowance");
        unchecked {
            _approve(f, _msgSender(), curr - v);
        }
        _transfer(f, t, v);
        return true;
    }

    function _transfer(address f, address t, uint256 v) internal virtual {
        require(f != address(0) && t != address(0), "zero addr");
        uint256 fb = _balances[f];
        require(fb >= v, "low bal");
        unchecked {
            _balances[f] = fb - v;
        }
        _balances[t] += v;
        emit Transfer(f, t, v);
    }

    function _mintOnce(address a, uint256 v) internal {
        require(a != address(0), "mint zero");
        require(_totalSupply == 0, "already minted");
        _totalSupply += v;
        _balances[a] += v;
        emit Transfer(address(0), a, v);
    }

    function _approve(address o, address s, uint256 v) internal virtual {
        require(o != address(0) && s != address(0), "approve zero");
        _allowances[o][s] = v;
        emit Approval(o, s, v);
    }
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address);
    function getPair(address tokenA, address tokenB) external view returns (address);
}

interface IUniswapV2Pair is IERC20 {
    function token0() external view returns (address);
    function token1() external view returns (address);
}

interface IUniswapV2Router02 {
    function factory() external view returns (address);
    function WPLS() external view returns (address);
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;
}

contract OLD_GLORY_RISE_v11 is ERC20, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    enum Fees { BuyBurnFee, BuyYieldFee, SellBurnFee, SellYieldFee }
    struct WalletInfo { uint256 share; }
    struct RewardTokenInfo { IERC20 token; uint8 decimals; uint256 scale; uint256 shareYieldRay; uint256 totalPaid; uint256 totalYield; }

    uint16 private constant _BIPS = 10_000;
    uint96 private constant _YIELDX = 1e27;
    address private constant BURN = address(0x369);
    uint256 public constant MIN_YIELD_BALANCE = 1e18;
    uint256 public constant MAX_ITERS = 50;
    
    // ✅ V11: Vortex-style swap safety caps
    uint256 public constant MAX_SWAP = 25_000 * 1e18;   // Hard safety cap
    uint256 public constant MIN_SWAP = 250 * 1e18;      // Launch-optimized minimum

    IUniswapV2Router02 public immutable dexRouter;
    IUniswapV2Pair public plsV2LP;

    uint16[] public fees;
    uint24 public constant lpWeightBips = 20_000;
    bool public payoutEnabled = true;
    bool public swapEnabled = true;
    bool public autoPayout = true;
    uint24 public maxGas = 300_000;
    uint24 public minWaitSec = 3_600;
    uint256 public minYield = 369e15;  // 0.369 pSunDAI (PulseChain ID 369!)

    bool private _swapping;
    uint32 public currIndex;
    uint256 public totalShares;

    mapping(address => WalletInfo) public walletInfo;
    mapping(address => bool) public noFee;
    mapping(address => bool) public noYield;
    mapping(address => mapping(address => uint256)) public walletClaimTS;
    address[] public wallets;
    mapping(address => uint256) public walletIndex;

    mapping(address => address) public walletRewardChoice;
    mapping(address => mapping(address => uint256)) public yieldDebt;
    mapping(address => RewardTokenInfo) public rewardTokens;
    address[] public rewardTokenList;

    event FeesUpdated(uint16, uint16, uint16, uint16);
    event PayoutPolicyUpdated(bool, uint24, uint256, uint24);
    event SwapParamsUpdated(bool);
    event NoYieldSet(address indexed, bool);
    event YieldPaid(address indexed wallet, address indexed token, uint256 amount);
    event RewardTokenAdded(address, uint8);
    event RewardChoiceChanged(address indexed wallet, address indexed token);

    receive() external payable {}

    // ==================== CONSTANTS ====================
    address public constant PULSEX_V2_ROUTER = 0x165C3410fC91EF562C50559f7d2289fEbed552d9;
    address public constant PSUNDAI = 0x5529c1cb179b2c256501031adCDAfC22D9c6d236;

    constructor() ERC20("Old Glory Rise", "RISE") {
        dexRouter = IUniswapV2Router02(PULSEX_V2_ROUTER);
        address w = dexRouter.WPLS();
        address f = dexRouter.factory();
        require(w != address(0) && f != address(0), "bad router");

        address pair = IUniswapV2Factory(f).getPair(address(this), w);
        if (pair == address(0)) pair = IUniswapV2Factory(f).createPair(address(this), w);
        plsV2LP = IUniswapV2Pair(pair);

        noYield[pair] = true;
        noFee[address(this)] = true;
        noFee[address(dexRouter)] = true;
        noYield[address(0)] = true;
        noYield[BURN] = true;
        noYield[address(this)] = true;

        _mintOnce(msg.sender, 10_000_000 * 1e18);

        fees = new uint16[](4);
        fees[uint256(Fees.BuyBurnFee)] = 10;
        fees[uint256(Fees.BuyYieldFee)] = 35;
        fees[uint256(Fees.SellBurnFee)] = 100;
        fees[uint256(Fees.SellYieldFee)] = 300;
        emit FeesUpdated(10, 35, 100, 300);

        _addRewardToken(PSUNDAI);
        walletRewardChoice[msg.sender] = PSUNDAI;
    }

    // ==================== REWARD TOKEN MANAGEMENT ====================
    
    function _addRewardToken(address token) internal {
        require(token != address(0), "invalid");
        uint8 dec = IERC20Metadata(token).decimals();
        require(dec <= 18, "decimals>18");
        rewardTokens[token] = RewardTokenInfo(IERC20(token), dec, 10**(18 - dec), 0, 0, 0);
        rewardTokenList.push(token);
        emit RewardTokenAdded(token, dec);
    }

    function setRewardChoice(address token) external {
        require(token == PSUNDAI, "Only pSunDAI allowed");
        _safePayYield(msg.sender, walletRewardChoice[msg.sender]);
        walletRewardChoice[msg.sender] = PSUNDAI;
        yieldDebt[msg.sender][PSUNDAI] = (walletInfo[msg.sender].share * rewardTokens[PSUNDAI].shareYieldRay) / _YIELDX;
        emit RewardChoiceChanged(msg.sender, PSUNDAI);
    }

    function getUnpaidYield(address wallet, address token) public view returns (uint256) {
        uint256 c = (walletInfo[wallet].share * rewardTokens[token].shareYieldRay) / _YIELDX;
        if (c <= yieldDebt[wallet][token]) return 0;
        return (c - yieldDebt[wallet][token]) / rewardTokens[token].scale;
    }

    function _safePayYield(address wallet, address token) private {
        if (token == address(0)) return;
        if (!_isPayEligible(wallet, token)) return;
        uint256 amt = getUnpaidYield(wallet, token);
        if (amt > 0) {
            rewardTokens[token].token.safeTransfer(wallet, amt);
            rewardTokens[token].totalPaid += amt;
            walletClaimTS[wallet][token] = block.timestamp;
            yieldDebt[wallet][token] = (walletInfo[wallet].share * rewardTokens[token].shareYieldRay) / _YIELDX;
            emit YieldPaid(wallet, token, amt);
        }
    }

    function _isPayEligible(address wallet, address token) private view returns (bool) {
        return (walletClaimTS[wallet][token] + minWaitSec) < block.timestamp &&
               getUnpaidYield(wallet, token) > minYield / rewardTokens[token].scale;
    }

    // ==================== SHARES TRACKING ====================
    
    function _setShare(address wallet, uint256 share_) private {
        uint256 old = walletInfo[wallet].share;
        if (share_ != old) {
            if (old > 0) _safePayYield(wallet, walletRewardChoice[wallet]);
            if (share_ == 0) _disableYield(wallet);
            else if (old == 0) _enableYield(wallet);
            totalShares = totalShares - old + share_;
            walletInfo[wallet].share = share_;
            address token = walletRewardChoice[wallet];
            if (token != address(0)) yieldDebt[wallet][token] = (share_ * rewardTokens[token].shareYieldRay) / _YIELDX;
        }
    }

    function _enableYield(address wallet) private {
        if (walletRewardChoice[wallet] == address(0)) walletRewardChoice[wallet] = rewardTokenList[0];
        walletIndex[wallet] = wallets.length;
        wallets.push(wallet);
    }

    function _disableYield(address wallet) private {
        uint256 idx = walletIndex[wallet];
        uint256 n = wallets.length;
        if (idx < n - 1) {
            address last = wallets[n - 1];
            wallets[idx] = last;
            walletIndex[last] = idx;
        }
        wallets.pop();
        delete walletIndex[wallet];
    }

    function _calcShares(address target) private view returns (uint256 s) {
        uint256 bal = balanceOf(target);
        if (bal < MIN_YIELD_BALANCE) return 0;
        uint256 lp = (plsV2LP.balanceOf(target) * lpWeightBips) / _BIPS;
        return bal + lp;
    }

    // ==================== PAYOUT ENGINE ====================
    
    function _payout(uint256 gas_, address token) private {
        uint256 n = wallets.length;
        if (n == 0) return;
        uint256 gasUsed = 0;
        uint256 gasLeft = gasleft();
        uint256 iters = 0;
        while (gasUsed < gas_ && iters < n && iters < MAX_ITERS) {
            if (currIndex >= n) currIndex = 0;
            address w = wallets[currIndex];
            if (!noYield[w] && getUnpaidYield(w, token) > 0 && _isPayEligible(w, token))
                _safePayYield(w, token);
            unchecked { currIndex++; iters++; }
            gasUsed += gasLeft - gasleft();
            gasLeft = gasleft();
        }
    }

    // ==================== SWAPS & YIELD ACCRUAL ====================
    
    function _swapTokensPost(uint256 newRewards, address token) private {
        if (newRewards == 0 || totalShares == 0) return;
        uint256 scaled = newRewards * rewardTokens[token].scale;
        rewardTokens[token].totalYield += scaled;
        rewardTokens[token].shareYieldRay += (uint256(_YIELDX) * scaled) / totalShares;
    }

    function _buildSwapPath(address token) private view returns (address[] memory) {
        address[] memory path = new address[](3);
        path[0] = address(this);
        path[1] = dexRouter.WPLS();
        path[2] = token;
        return path;
    }

    function _swapTokens(uint256 amt, address token) private {
        if (amt == 0) return;
        address[] memory p = _buildSwapPath(token);
        uint256 beforeBal = rewardTokens[token].token.balanceOf(address(this));
        _approve(address(this), address(dexRouter), 0);
        _approve(address(this), address(dexRouter), amt);
        try dexRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(amt, 0, p, address(this), block.timestamp) {} catch { return; }
        uint256 afterBal = rewardTokens[token].token.balanceOf(address(this));
        if (afterBal > beforeBal) _swapTokensPost(afterBal - beforeBal, token);
    }

    // ✅ V11: FIXED - No LP reads, uses yield balance only
    function _getSwapSize(uint256 yieldBal) private pure returns (uint256) {
        if (yieldBal < MIN_SWAP) return 0;
        if (yieldBal > MAX_SWAP) return MAX_SWAP;
        return yieldBal;
    }

    function _isMainLP(address a) private view returns (bool) {
        return a != address(0) && a == address(plsV2LP);
    }

    // ==================== TRANSFER OVERRIDE ====================
    
    function _transfer(address from, address to, uint256 amt) internal override {
        bool isFromLP = _isMainLP(from);
        bool isToLP = _isMainLP(to);

        uint256 yieldBal = _balances[address(this)];
        // ✅ V11: FIXED - Use yield balance for swap sizing
        uint256 swapAmt = _getSwapSize(yieldBal);

        address tokenChoice = walletRewardChoice[from];
        if (tokenChoice == address(0)) tokenChoice = rewardTokenList[0];

        // ✅ V11: FIXED - Check swapAmt > 0
        if (swapEnabled && swapAmt > 0 && !_swapping && to == address(plsV2LP)) {
            _swapping = true;
            _swapTokens(swapAmt, tokenChoice);
            _swapping = false;
        }

        if (!noFee[from] && !noFee[to]) {
            (uint256 burnFee, uint256 yieldFee) = _calcFees(amt, isFromLP, isToLP);
            unchecked {
                if (burnFee > 0) {
                    amt -= burnFee;
                    super._transfer(from, BURN, burnFee);
                }
                if (yieldFee > 0) {
                    amt -= yieldFee;
                    super._transfer(from, address(this), yieldFee);
                }
            }
        }

        super._transfer(from, to, amt);

        if (payoutEnabled && autoPayout && !_swapping) _payout(maxGas, tokenChoice);

        if (!noYield[from]) _setShare(from, _calcShares(from));
        if (!noYield[to]) _setShare(to, _calcShares(to));
    }

    function _calcFees(uint256 amt, bool isFromLP, bool isToLP) private view returns (uint256 burnFee, uint256 yieldFee) {
        if (isToLP) {
            burnFee = (amt * fees[uint256(Fees.SellBurnFee)]) / _BIPS;
            yieldFee = (amt * fees[uint256(Fees.SellYieldFee)]) / _BIPS;
        } else if (isFromLP) {
            burnFee = (amt * fees[uint256(Fees.BuyBurnFee)]) / _BIPS;
            yieldFee = (amt * fees[uint256(Fees.BuyYieldFee)]) / _BIPS;
        }
    }

    // ==================== PUBLIC USER FUNCTIONS ====================
    
    function claimYield() external nonReentrant {
        _safePayYield(msg.sender, walletRewardChoice[msg.sender]);
    }

    function airdrop(address[] calldata to, uint256[] calldata amts) external onlyOwner {
        require(to.length == amts.length, "len mismatch");
        address s = _msgSender();
        for (uint256 i; i < to.length;) {
            _transfer(s, to[i], amts[i]);
            if (!noYield[to[i]]) _setShare(to[i], _calcShares(to[i]));
            unchecked { i++; }
        }
        if (!noYield[s]) _setShare(s, _calcShares(s));
    }

    // ==================== OWNER FUNCTIONS ====================
    
    function setFees(uint16 bb, uint16 by, uint16 sb, uint16 sy) external onlyOwner {
        require(bb <= 500 && by <= 500 && sb <= 500 && sy <= 500, "fee>5%");
        require(bb + by <= 500, "buy>5%");
        require(sb + sy <= 500, "sell>5%");
        fees[uint256(Fees.BuyBurnFee)] = bb;
        fees[uint256(Fees.BuyYieldFee)] = by;
        fees[uint256(Fees.SellBurnFee)] = sb;
        fees[uint256(Fees.SellYieldFee)] = sy;
        emit FeesUpdated(bb, by, sb, sy);
    }

    function setNoYield(address w, bool f) external onlyOwner {
        noYield[w] = f;
        if (f) _setShare(w, 0);
        else _setShare(w, _calcShares(w));
        emit NoYieldSet(w, f);
    }

    function setPayoutPolicy(bool en, uint24 minDur, uint256 newMin, uint24 gas_) external onlyOwner {
        payoutEnabled = en;
        minWaitSec = minDur;
        minYield = newMin;
        maxGas = gas_;
        emit PayoutPolicyUpdated(en, minDur, newMin, gas_);
    }

    // ✅ V11: FIXED - Removed lpFactor parameter (no longer needed)
    function setSwapParams(bool en) external onlyOwner {
        swapEnabled = en;
        emit SwapParamsUpdated(en);
    }

    function setAutoPayout(bool en) external onlyOwner {
        autoPayout = en;
    }
}
