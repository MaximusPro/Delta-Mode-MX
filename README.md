# Delta Mode MX

**Delta Mode MX** is a volume delta and cluster analysis indicator for MetaTrader 4.  
It displays the difference between buy and sell volume (delta) on each bar, as well as cumulative delta and other metrics in a convenient visual format.

## Screenshots

(Add 2–4 screenshots here later — ideally on different timeframes and scales)

<!-- 
![Delta Mode MX on H1](screenshots/delta-h1.png)
![Indicator settings](screenshots/settings.png)
![Cumulative delta](screenshots/cumdelta.png)
-->

## Key Features

- Displays **bid/ask delta** for each bar
- Color indication of bars (positive / negative delta)
- Cumulative Delta line
- Multiple display modes: histogram / numbers / colored candles
- Supports both tick volume and real volume (if provided by broker)
- Configurable small delta noise filter
- Absorption and exhaustion zones (optional)
- Lightweight and fast — does not slow down the terminal even on M1

## Requirements

- MetaTrader 4 (build 600+)
- Broker providing tick volume or real volume (most ECN/STP brokers)
- Recommended timeframes: M1–H1 for best accuracy

## Installation

1. Download the file `Delta Mode MX 0.1.mq4` (or a newer version)
2. Open MetaTrader 4 → **File → Open Data Folder**
3. Go to folder `MQL4 → Indicators`
4. Copy the `.mq4` file there (or compiled `.ex4` if available)
5. Restart the terminal or right-click in Navigator → **Refresh**
6. Drag the indicator onto any chart

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
