# 🇺🇸 Old Glory RISE Token DApp

**Deflationary Yield Protocol on PulseChain**

A patriotic, sovereign DeFi interface for Old Glory RISE Token - featuring autonomous pSunDAI yield distribution, treasury-powered burns, and zero governance dependencies.

![Old Glory RISE Token](assets/OG_ELITE.png)

## 🎯 Features

- **Real-time Token Stats** - Supply, burns, deflation metrics, and treasury balance
- **pSunDAI Yield Claiming** - Pull-based stablecoin reward system with countdown timers
- **LP Bonus Tracking** - 2x share multiplier for liquidity providers
- **Autonomous Treasury Burns** - 10% of supply dedicated to permanent deflation
- **Immutable Operation** - No admin keys, no governance, pure self-sovereignty
- **PulseChain Native** - Built specifically for the PulseChain ecosystem

## 🚀 Live Demo

Visit: [https://oldgloryrise.com](https://oldgloryrise.com) *(update with actual domain)*

## 📋 Contract Addresses

- **RISE Token**: [`0xE558edc934FDbB65cdF4868617D5F0D80595aD11`](https://scan.pulsechain.com/address/0xE558edc934FDbB65cdF4868617D5F0D80595aD11)
- **LP Pair (RISE/WPLS)**: *[To be deployed]*
- **pSunDAI Reward Token**: [`0x5529...`](https://scan.pulsechain.com/address/0x5529...) *(update with actual address)*
- **Treasury Accelerator**: *[To be deployed]*

## 🛠️ Technology Stack

- **Frontend**: Pure HTML5, CSS3, JavaScript (no framework dependencies)
- **Web3 Integration**: ethers.js v6
- **Blockchain**: PulseChain (Chain ID: 369)
- **Design**: Patriotic theme with metallic accents and animated effects

## 📦 Installation & Deployment

### Option 1: Direct Deployment

1. Clone this repository:
```bash
git clone https://github.com/YOUR_USERNAME/old-glory-rise-dapp.git
cd old-glory-rise-dapp
```

2. Add the logo image to `/assets/OG_ELITE.png`

3. Deploy to any static hosting:
   - **GitHub Pages**: Enable in repo settings
   - **Netlify**: Drag and drop the folder
   - **Vercel**: Import from GitHub
   - **Traditional hosting**: Upload via FTP/cPanel

### Option 2: Run Locally

Simply open `index.html` in your browser. That's it!

```bash
# Or use a local server
python -m http.server 8000
# Then visit http://localhost:8000
```

## 🎨 Customization

All styling is contained within `index.html` using CSS variables:

```css
:root {
    --navy: #0a1628;
    --red: #c41e3a;
    --white: #ffffff;
    --blue: #002868;
    --silver: #c0c0c0;
    --gold: #d4af37;
}
```

## 🔐 Security

- **No backend required** - Pure client-side application
- **Read-only operations** - Only writes are user-initiated claims
- **MetaMask integration** - Users maintain custody of their keys
- **Immutable contracts** - No admin functions after renunciation
- **Two-step immutability** - Lock parameters first, renounce later

## 📊 Key Metrics Displayed

### Global Stats
- Total Supply
- Total Burned (to address `0x369`)
- Deflation Rate
- Total Shareholders
- pSunDAI Distributed
- Treasury Balance (1M RISE)
- Treasury Burns Status

### User Dashboard
- RISE Balance
- LP Token Balance
- Share Count (with 2x LP bonus)
- Unpaid pSunDAI Yield
- Next Claim Countdown

## 🎯 How It Works

1. **Connect Wallet** - MetaMask or Web3 wallet on PulseChain
2. **View Stats** - Real-time protocol metrics
3. **Earn Rewards** - Hold RISE or provide liquidity to earn pSunDAI
4. **Claim Rewards** - Pull-based pSunDAI distribution (1 hour cooldown)
5. **LP Bonus** - Liquidity providers receive 2x share weight
6. **Watch Burns** - Treasury autonomously burns RISE supply forever

## 🏗️ Protocol Architecture

Old Glory RISE implements:

### Tokenomics
- **Supply**: 10,000,000 RISE
- **Treasury**: 1,000,000 RISE (10% - autonomous burning)
- **Circulating**: 9,000,000 RISE (90% - distributed to community)
- **Fees**: 0.45% buy / 4% sell (split between burns and yield)

### Yield System
- **Reward Token**: pSunDAI (yield-bearing stablecoin)
- **Distribution**: Pull-based claiming (gas efficient)
- **Min Balance**: 1 RISE to qualify for rewards
- **LP Multiplier**: 2x share weight for liquidity providers
- **Cooldown**: 1 hour between claims

### Treasury Accelerator
- **Allocation**: 1M RISE (10% of supply)
- **Function**: Autonomous buy-and-burn mechanism
- **Frequency**: Executes every hour when conditions met
- **Deflation**: 17-490% annual burn rate (volume dependent)
- **Rewards**: $0.50-$2 pSunDAI for executing burns
- **Gas Management**: Self-sustaining (1.5% of yields reserved)

### Deflationary Flywheel
1. Trading volume generates pSunDAI rewards
2. Treasury (10%) claims its share
3. Treasury swaps pSunDAI → PLS → RISE
4. Purchased RISE burned to `0x369` address
5. Supply decreases, scarcity increases
6. Price appreciation attracts more volume
7. **Repeat** ♻️

## 🔥 Why "RISE"?

**R**eward  
**I**mmutable  
**S**overeign  
**E**cosystem  

Old Glory RISE embodies:
- ✅ **Rewards**: Stable pSunDAI yield for holders
- ✅ **Immutable**: No admin keys, no governance
- ✅ **Sovereign**: True self-custody, zero dependencies
- ✅ **Ecosystem**: Circular SunDAI/pSunDAI/RISE economics

## 📈 Deflationary Metrics

### Expected Burn Rates (based on volume)

| Daily Volume | Annual Deflation | Treasury Lifespan |
|-------------|------------------|-------------------|
| $5,000      | 17.3%           | 5.8 years         |
| $10,000     | 34.7%           | 2.9 years         |
| $50,000     | 173%            | 0.6 years         |
| $100,000+   | 347%+           | <0.3 years        |

*Note: Treasury depletes faster at higher volumes, creating intense scarcity*

## 🎖️ Marketing Narrative

> **"The only token where the treasury BURNS instead of SELLS"**

Traditional tokens:
- Team treasury sells tokens for funding
- Creates perpetual sell pressure
- Bearish tokenomics

Old Glory RISE:
- Treasury BUYS tokens with earned yield
- Creates perpetual buy pressure
- Burns purchased tokens permanently
- Bullish deflationary mechanics

## 📝 Launch Checklist

- [x] Deploy RISE token contract
- [ ] Create RISE/WPLS liquidity pair
- [ ] Deploy Treasury Accelerator contract
- [ ] Transfer 1M RISE to treasury
- [ ] Verify treasury NOT excluded from yield
- [ ] Test execute() function
- [ ] Lock parameters (after 6-12 months testing)
- [ ] Renounce ownership (after proven operation)
- [ ] Launch DApp frontend
- [ ] Announce to community

## 📝 License

MIT License - Feel free to fork and modify

## 🤝 Contributing

Contributions welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Submit a pull request

## 🔗 Links

- **Website**: [oldgloryrise.com](https://oldgloryrise.com) *(update)*
- **Contract**: [PulseScan](https://scan.pulsechain.com/address/0xE558edc934FDbB65cdF4868617D5F0D80595aD11)
- **Developer**: ELITE TEAM6
- **Ecosystem**: [SunDAI](https://sundaitoken.com)

## ⚠️ Disclaimer

This DApp is provided as-is. Always DYOR (Do Your Own Research) before interacting with any smart contracts. The protocol operates autonomously without any central control or guarantees.

**Not financial advice. Cryptocurrency investments carry risk.**

---

**Built with 🇺🇸 for the PulseChain community**

*Autonomous • Deflationary • Sovereign*

## 🌟 Vision

Old Glory RISE is building for the future:
- **Phase 1 (Bear Market)**: Deploy infrastructure, test at low stakes
- **Phase 2 (Recovery)**: Scale operations, lock parameters
- **Phase 3 (Bull Market)**: Achieve immutability, dominate ecosystem

We're early. We're building. We're RISING. 🚀
