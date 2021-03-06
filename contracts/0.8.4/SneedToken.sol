// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./libraries/Address.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/IUniswap.sol";
import "./chainlink/PriceConsumerV3.sol";


contract SneedToken is IERC20, Ownable {
  using SafeMath for uint256;
  using Address for address;

  // ----------------------------------------------
  //                  Variables
  // ----------------------------------------------
  string private _name = "Sneed Token";
  string private _symbol = "SNEED";
  uint8 private _decimals = 18;
  mapping (address => uint256) private _balances;
  mapping (address => mapping (address => uint256)) private _allowances;
  uint256 private _totalSupply;

  IUniswapV2Router02 public immutable uniswapV2Router;
  address public immutable uniswapV2Pair;
  mapping (address => bool) private _isExcludedFromFee;

  // ----------------------------------------------
  //                  Events
  // ----------------------------------------------
  event MinterChanged(address indexed from, address indexed to);

  // ----------------------------------------------
  //                  Modifiers
  // ----------------------------------------------

  // TODO: implement this one where needed + check gas efficiency
  modifier validRecipient(address _recipient) {
    require(
      _recipient != address(0) && _recipient != address(this),
      "Not a valid Recipient"
    );
    _;
  }


  // ----------------------------------------------
  //                  Constructor
  // ----------------------------------------------
  constructor(uint256 initialAmount) {
    // _owner = msg.sender;  -> is set by Ownable

    _totalSupply = initialAmount;
    _balances[_msgSender()] = initialAmount;

    // Create a uniswap pair for this new token     
    IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x05fF2B0DB69458A0750badebc4f9e13aDd608C7F);
    uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());

    // set the rest of the contract variables
    uniswapV2Router = _uniswapV2Router;
    
    //exclude owner and this contract from fee
    _isExcludedFromFee[owner()] = true;
    _isExcludedFromFee[address(this)] = true;
    
    emit Transfer(address(0), _msgSender(), initialAmount);
  }

  // ----------------------------------------------
  //                  Functions
  // ----------------------------------------------

  /**
  * @dev Returns the name of the token.
  */
  function name() public view returns (string memory) {
    return _name;
  }

  /**
  * @dev Returns the symbol of the token, usually a shorter version of the
  * name.
  */
  function symbol() public view returns (string memory) {
    return _symbol;
  }

  /**
  * @dev Returns the number of decimals used to get its user representation.
  * For example, if `decimals` equals `2`, a balance of `505` tokens should
  * be displayed to a user as `5,05` (`505 / 10 ** 2`).
  *
  * Tokens usually opt for a value of 18, imitating the relationship between
  * Ether and Wei. This is the value {ERC20} uses, unless this function is
  * overridden;
  *
  * NOTE: This information is only used for _display_ purposes: it in
  * no way affects any of the arithmetic of the contract, including
  * {IERC20-balanceOf} and {IERC20-transfer}.
  */
  function decimals() public view returns (uint8) {
    return _decimals;
  }
  
  /**
  * @dev See {IERC20-totalSupply}.
  */
  function totalSupply() public view override returns (uint256) {
      return _totalSupply;
  }
  

  /**
  * @dev See {IERC20-balanceOf}.
  */
  function balanceOf(address account) public view override returns (uint256) {
      return _balances[account];
  }
  

  /**
  * @dev See {IERC20-transfer}.
  *
  * Requirements:
  *
  * - `recipient` cannot be the zero address.
  * - the caller must have a balance of at least `amount`.   TODO: check this one
  */
  function transfer(address recipient, uint256 amount) public override validRecipient(recipient) returns (bool) {
      _transfer(_msgSender(), recipient, amount);
      return true;
  }

  /**
  * @dev See {IERC20-allowance}.
  */
  function allowance(address owner, address spender) public view virtual override returns (uint256) {
      return _allowances[owner][spender];
  }
  
  /**
    * @dev See {IERC20-approve}.
    *
    * Requirements:
    *
    * - `spender` cannot be the zero address.
    */
  function approve(address spender, uint256 amount) public virtual override returns (bool) {
      _approve(_msgSender(), spender, amount);
      return true;
  }

  /**
  * @dev See {IERC20-transferFrom}.
  *
  * Emits an {Approval} event indicating the updated allowance. This is not
  * required by the EIP. See the note at the beginning of {ERC20}.
  *
  * Requirements:
  *
  * - `sender` and `recipient` cannot be the zero address.
  * - `sender` must have a balance of at least `amount`.
  * - the caller must have allowance for ``sender``'s tokens of at least
  * `amount`.
  */
  function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
      _transfer(sender, recipient, amount);

      uint256 currentAllowance = _allowances[sender][_msgSender()];
      require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
      _approve(sender, _msgSender(), currentAllowance - amount);

      return true;
  }

  /**
  * @dev Atomically increases the allowance granted to `spender` by the caller.
  *
  * This is an alternative to {approve} that can be used as a mitigation for
  * problems described in {IERC20-approve}.
  *
  * Emits an {Approval} event indicating the updated allowance.
  *
  * Requirements:
  *
  * - `spender` cannot be the zero address.
  */
  function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
      _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
      return true;
  }

  /**
  * @dev Atomically decreases the allowance granted to `spender` by the caller.
  *
  * This is an alternative to {approve} that can be used as a mitigation for
  * problems described in {IERC20-approve}.
  *
  * Emits an {Approval} event indicating the updated allowance.
  *
  * Requirements:
  *
  * - `spender` cannot be the zero address.
  * - `spender` must have allowance for the caller of at least
  * `subtractedValue`.
  */
  function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
      uint256 currentAllowance = _allowances[_msgSender()][spender];
      require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
      _approve(_msgSender(), spender, currentAllowance - subtractedValue);

      return true;
  }
  
  /**
  * @dev Moves tokens `amount` from `sender` to `recipient`.
  *
  * This is internal function is equivalent to {transfer}, and can be used to
  * e.g. implement automatic token fees, slashing mechanisms, etc.
  *
  * Emits a {Transfer} event.
  *
  * Requirements:
  *
  * - `sender` cannot be the zero address.
  * - `recipient` cannot be the zero address.
  * - `sender` must have a balance of at least `amount`.
  */
  function _transfer(address sender, address recipient, uint256 amount) internal virtual {
      require(sender != address(0), "ERC20: transfer from the zero address");
      require(recipient != address(0), "ERC20: transfer to the zero address");

      _beforeTokenTransfer(sender, recipient, amount);

      uint256 senderBalance = _balances[sender];
      require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
      _balances[sender] = senderBalance - amount;
      _balances[recipient] += amount;

      emit Transfer(sender, recipient, amount);
  }

  /** @dev Creates `amount` tokens and assigns them to `account`, increasing
  * the total supply.
  *
  * Emits a {Transfer} event with `from` set to the zero address.
  *
  * Requirements:
  *
  * - `to` cannot be the zero address.
  */
  function _mint(address account, uint256 amount) internal virtual {
      require(account != address(0), "ERC20: mint to the zero address");

      _beforeTokenTransfer(address(0), account, amount);

      _totalSupply += amount;
      _balances[account] += amount;
      emit Transfer(address(0), account, amount);
  }

  /**
  * @dev Destroys `amount` tokens from `account`, reducing the
  * total supply.
  *
  * Emits a {Transfer} event with `to` set to the zero address.
  *
  * Requirements:
  *
  * - `account` cannot be the zero address.
  * - `account` must have at least `amount` tokens.
  */
  function _burn(address account, uint256 amount) internal virtual {
      require(account != address(0), "ERC20: burn from the zero address");

      _beforeTokenTransfer(account, address(0), amount);

      uint256 accountBalance = _balances[account];
      require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
      _balances[account] = accountBalance - amount;
      _totalSupply -= amount;

      emit Transfer(account, address(0), amount);
  }

  /**
  * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
  *
  * This internal function is equivalent to `approve`, and can be used to
  * e.g. set automatic allowances for certain subsystems, etc.
  *
  * Emits an {Approval} event.
  *
  * Requirements:
  *
  * - `owner` cannot be the zero address.
  * - `spender` cannot be the zero address.
  */
  function _approve(address owner, address spender, uint256 amount) internal virtual {
      require(owner != address(0), "ERC20: approve from the zero address");
      require(spender != address(0), "ERC20: approve to the zero address");

      _allowances[owner][spender] = amount;
      emit Approval(owner, spender, amount);
  }

  /**
  * @dev Hook that is called before any transfer of tokens. This includes
  * minting and burning.
  *
  * Calling conditions:
  *
  * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
  * will be to transferred to `to`.
  * - when `from` is zero, `amount` tokens will be minted for `to`.
  * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
  * - `from` and `to` are never both zero.
  *
  * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
  */
  function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
  
}