# Delta Mode MX

**Delta Mode MX** is a modification from Delta strategy on M15 timeframes which uses avrage.

## Requirements

- MetaTrader 4 (build 600+)
- Broker providing tick volume or real volume (most ECN/STP brokers)
- Recommended timeframes: M1–H1 for best accuracy

## Installation

1. Download the repository:

   ```bash
   git clone https://github.com/MaximusPro/Delta-Mode-MX.git
   ```
2. Copy files to the correct MetaTrader 4 folders:
```bash
Delta Mode MX 0.1.mq4
```
3. Restart MetaTrader 4  
or right-click inside the Navigator panel → **Refresh**.

4. Drag the **Delta Mode MX 0.1** expert advisor onto any chart.  
Make sure the **AutoTrading** button in the toolbar is enabled (green).

## Input Parameters

| Parameter                     | Default Value | Description                                                            |
|-------------------------------|---------------|------------------------------------------------------------------------|
| `ShowBidAskDelta`             | true          | Show buy/sell delta on each bar                                        |
| `ShowCumulativeDelta`         | true          | Show cumulative delta line                                             |
| `DeltaBarMode`                | 0             | 0 = histogram, 1 = numbers, 2 = colored candles                       |
| `MinDeltaFilter`              | 0             | Minimum delta volume to display (noise filter)                         |
| `CumDeltaResetOnDayStart`     | true          | Reset cumulative delta at the start of each day (00:00)                |
| `ColorPositive`               | clrLimeGreen  | Color for positive delta                                               |
| `ColorNegative`               | clrRed        | Color for negative delta                                               |
| `ColorZero`                   | clrGray       | Color for zero / very small delta                                      |

## How to Use

1. Attach the indicator to the chart
2. Works best in combination with Market Profile / Order Book / Footprint (if available)
3. Look for **divergences** between price and delta
4. Pay attention to **absorption** zones (large delta against the price direction)
5. Use cumulative delta to assess overall market sentiment

## Roadmap (Planned Features)

- [ ] Version 0.2 — support for real Futures volume (via plugin)
- [ ] Version 0.3 — intra-bar cluster display (mini-footprint)
- [ ] Version 1.0 — session profiles (Asia, London, New York)
- [ ] Auto-detection of broker volume type
- [ ] Delta export to CSV for analysis in Python / R

## Author

MaximusPro  
GitHub: https://github.com/MaximusPro  
Telegram / forums: @MaximusPro (add your contact if you have one)

## License

MIT License (or specify your own)

---

Feel free to tell me if you want to change the wording, add/remove sections, make it more marketing-style, more technical, etc. — I’ll adjust it instantly.
