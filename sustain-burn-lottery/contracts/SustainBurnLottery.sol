// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

/* ─────── Chainlink v2.5 (a.k.a. VRF-v2-plus) imports ─────── */
import {VRFConsumerBaseV2Plus}  from
  "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient}       from
  "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";
import {IVRFCoordinatorV2Plus} from
  "@chainlink/contracts/src/v0.8/vrf/dev/interfaces/IVRFCoordinatorV2Plus.sol";

/* ─────── Chainlink Automation ─────── */
import
  "@chainlink/contracts/src/v0.8/automation/interfaces/AutomationCompatibleInterface.sol";

/* ─────── OpenZeppelin ─────── */
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/* -------------------------------------------------------------------------- */
/*                            Sustain-&-Burn Lottery                          */
/* -------------------------------------------------------------------------- */
contract SustainBurnLottery is
    VRFConsumerBaseV2Plus,
    AutomationCompatibleInterface,
    ReentrancyGuard
{
    /* ─── user-tunable constants ─────────────────────────────────────────── */
    uint256 public constant TICKET_PRICE = 10_000 * 1e18;   // 10 000 IACS
    uint256 public constant BURN_PERCENT = 20;              // 20 %
    uint256 public constant DRAW_INTERVAL = 1 days;

    address public immutable DEAD = 0x000000000000000000000000000000000000dEaD;
    IERC20  public immutable IACS;

    /* ─── VRF v2.5 configuration ─────────────────────────────────────────── */
    IVRFCoordinatorV2Plus       private immutable COORDINATOR;

    bytes32 public immutable keyHash;               // gas lane
    uint256 public immutable subscriptionId;        // now uint256 in v2.5
    uint16  public constant REQUEST_CONFIRMATIONS = 3;
    uint32  public constant CALLBACK_GAS_LIMIT   = 250_000;
    uint32  public constant NUM_WORDS            = 1;

    /* ─── state ──────────────────────────────────────────────────────────── */
    uint256  public lastDraw;
    bool     public drawPending;

    address[] public tickets;       // current round entrants
    uint256   public currentRound;  // monotonically increasing

    mapping(uint256 => address) public winners;   // round → winner

    /* ─── events ─────────────────────────────────────────────────────────── */
    event TicketBought(address indexed player, uint256 indexed round, uint256 qty);
    event DrawRequested(uint256 indexed round, uint256 requestId);
    event WinnerPicked(address indexed winner, uint256 indexed round, uint256 prize);

    /* ---------------------------------------------------------------------- */
    /*                                constructor                             */
    /* ---------------------------------------------------------------------- */
    constructor(
        address  _iacs,
        uint256  _subId,
        address  _vrfCoordinator,
        bytes32  _keyHash
    )
        VRFConsumerBaseV2Plus(_vrfCoordinator)   // <<─ v2.5 base
    {
        IACS           = IERC20(_iacs);
        subscriptionId = _subId;
        COORDINATOR    = IVRFCoordinatorV2Plus(_vrfCoordinator);
        keyHash        = _keyHash;
        lastDraw       = block.timestamp;
    }

    /* ---------------------------------------------------------------------- */
    /*                              Buy tickets                               */
    /* ---------------------------------------------------------------------- */
    function buyTicket(uint256 qty) external nonReentrant {
        require(qty > 0, "qty==0");

        uint256 cost = qty * TICKET_PRICE;
        require(IACS.transferFrom(msg.sender, address(this), cost), "transfer failed");

        uint256 burnAmt = (cost * BURN_PERCENT) / 100;
        require(IACS.transfer(DEAD, burnAmt), "burn failed");

        for (uint256 i; i < qty; ++i) tickets.push(msg.sender);

        emit TicketBought(msg.sender, currentRound, qty);
    }

    /* ---------------------------------------------------------------------- */
    /*                       Chainlink Automation logic                       */
    /* ---------------------------------------------------------------------- */
    function checkUpkeep(
        bytes calldata
    ) external view override returns (bool upkeepNeeded, bytes memory) {
        upkeepNeeded =
            (block.timestamp - lastDraw >= DRAW_INTERVAL) &&
            tickets.length > 0 &&
            !drawPending;
    }

    function performUpkeep(bytes calldata) external override {
        (bool needed, ) = this.checkUpkeep("");
        require(needed, "not-needed");

        drawPending = true;
        lastDraw    = block.timestamp;

        /* ---- v2.5 request object ---- */
        uint256 requestId = COORDINATOR.requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest({
                keyHash: keyHash,
                subId:   subscriptionId,
                requestConfirmations: REQUEST_CONFIRMATIONS,
                callbackGasLimit:     CALLBACK_GAS_LIMIT,
                numWords:             NUM_WORDS,
                /* pay fee in BASE, not LINK */
                extraArgs: VRFV2PlusClient._argsToBytes(
                    VRFV2PlusClient.ExtraArgsV1({ nativePayment: true })
                )
            })
        );

        emit DrawRequested(currentRound, requestId);
    }

    /* ---------------------------------------------------------------------- */
    /*                   VRF callback – pick & pay the winner                 */
    /* ---------------------------------------------------------------------- */
    function fulfillRandomWords(
        uint256,                 /* requestId (ignored) */
        uint256[] calldata words
    ) internal override nonReentrant {
        require(drawPending, "no-draw");

        uint256 idx     = words[0] % tickets.length;
        address winner  = tickets[idx];

        uint256 prize   = IACS.balanceOf(address(this));
        require(IACS.transfer(winner, prize), "payout failed");

        winners[currentRound] = winner;
        emit WinnerPicked(winner, currentRound, prize);

        delete tickets;
        currentRound += 1;
        drawPending   = false;
    }

    /* ---------------------------------------------------------------------- */
    /*                               view helpers                             */
    /* ---------------------------------------------------------------------- */
    function jackpot() external view returns (uint256) { return IACS.balanceOf(address(this)); }
    function ticketCount() external view returns (uint256) { return tickets.length; }
}
