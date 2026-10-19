# 單級 PFC（電池直吃 2ω 漣波）：省錢、壽命、電池影響試算與實際案例

> 延續 [單級PFC_電池吃漣波_DCDC取捨.md](./單級PFC_電池吃漣波_DCDC取捨.md)。
> 標 **【假設】** 的數字是我自己訂的試算參數，標 **【來源】** 的數字來自文末參考資料。
> 本環境無法直接開啟論文全文，部分文獻結論來自摘要或其他論文的引述，可信度欄已註明。

## 0. 先講結論

| 項目 | 試算結果（6.6 kW 單相） | 跟原筆記比 |
|---|---|---|
| BOM 節省 | **約 −9% ～ +3%**；只有電解電容組很大、很貴時才到 **−15～−20%** | 原筆記「省 10~25%」偏樂觀 |
| 電容壽命 | 電解電容 12,000～45,000 h → 薄膜電容 100,000 h 等級 | 一致 |
| 系統 MTBF（隨機失效） | 最多約 **×1.3～1.4** | 「明顯提升」成立，但幅度有限 |
| 何時壽命差最大 | **每天跑 20 h 的站用／車隊充電機**：電解電容 10 年內要換 1 次，換成薄膜電容後不用換 | 新增 |
| 電池發熱 | 理論 1.5×，實際約 **1.25～1.4×**；絕對值只多 **6～9 W**（< 0.15%） | 一致 |
| 電池老化 | 100 Hz 等級的多數長期測試沒看到明顯加速；有反例，但多在 < 10 Hz 或 kHz 頻段 | 一致 |
| 真正的代價 | **低溫充電功率要砍**：例子中電池端從 6.3 kW 降到約 4 kW | 一致，並量化 |
| 量產案例 | **沒找到**公開資料證實量產車用 OBC 讓電池吃 100% 2ω 漣波；目前是研究原型＋元件廠推動 | 新增 |

---

## 1. 試算基準

| 參數 | 值 | 註 |
|---|---|---|
| 功率 P | 6.6 kW 單相 | 【假設】常見 OBC 等級 |
| 市電 | 220 Vac / 60 Hz → 漣波 120 Hz | 【假設】台灣 |
| 電池 | LFP 400 V（125S，100 Ah 電芯） | 【假設】 |
| 效率 η | 0.96 | 【假設】 |
| 平均充電電流 I_avg | 15.8 A（0.16C） | 計算 |
| 峰值 / 有效值 | 31.7 A（2.0×）/ 19.4 A（1.225×） | 計算：i = I_avg(1 − cos2ωt) |

> 三相平衡電網的瞬時功率是常數，**沒有 2ω 漣波**，所以這個問題主要出在單相（家用 3.3/6.6/7.4 kW、單相模組）。
> 三相站用充電機若用 3 個單相模組並聯到同一顆電池，漣波會互相抵消（Kettering 的 3 模組 20 kW 就是這樣做）。

---

## 2. 省多少錢

### 2.1 被拿掉的 DC-link 電解電容

- 容量公式：`C = P / (ω·V·ΔVpp)`【來源：Korea Science 論文用同式，3.3 kW / 7 Vpp → 3.5 mF】
- 400 V bus、ΔVpp = 40 V（10%）→ **1.09 mF**；ΔVpp = 20 V → 2.19 mF
- 電容承受的 120 Hz 漣波電流：`P/(√2·V)` = **11.7 A rms**，所以通常是漣波電流決定顆數，不是容量
- 取 4 × 470 µF/450 V（ΔVpp ≈ 23 V，每顆 2.9 A rms）

| 元件 | 零售價【來源】 | 量產價【假設】 |
|---|---|---|
| TDK B43544（470 µF/450 V，105°C 3,000 h） | €9.55 @10 pcs | US$4～6 |
| TDK B43547（470 µF/450 V，105°C 8,000 h） | €13.33 @1 pc | US$5～8 |
| KEMET C4AQ 40 µF/500 V 薄膜（替代用小電容） | £5.99 @25 pcs | US$4～5 |

- 電容組（4 顆）量產約 US$20，體積約 **190 cm³**（4 × φ35×50 mm），約佔 6.6 kW OBC 體積的 7～10%【假設 2.5 kW/L】

### 2.2 BOM 模型（6.6 kW 單向 OBC，量產價，全部為【假設】）

基準 A（兩級：圖騰柱 PFC + DC-link 電解電容 + DAB/LLC）合計約 **US$331（≈ US$50/kW）**：
EMI 25、PFC 開關 16、PFC 電感 20、PFC 驅動 8、電解電容 20、DC/DC 開關 44、變壓器 25、諧振電感 8、DC/DC 驅動 10、輸出電容 5、控制 30、PCB 組裝 40、機構散熱 80。

> 參考：Frost & Sullivan 早年估 OBC **售價** US$130～230/kW【來源，已過時】；這裡的模型是 BOM，不是售價。

| 方案 | 變動項目（US$） | 淨變化 |
|---|---|---|
| **B1：只拿掉電解電容**，保留 PFC，DAB 改傳 sin² 功率，DC/DC 加大到損耗不變 | 電容 −20、薄膜 +5、DC/DC 開關 +22（Rds(on) 要降到 1/1.5）、變壓器 +6、電感 +4（2× 峰值不飽和）、機構 −8 | **+9（+2.7%）** |
| B1'：同上但 DC/DC **不加大**（接受導通損耗 ×1.5） | 電容 −20、薄膜 +5、機構 −8 | −23（−6.9%） |
| **B2：真單級**（工頻換向橋 + DAB 兼做 PFC） | PFC 開關 −10、PFC 電感 −20、PFC 驅動 −5、電容 −20、薄膜 +5、DC/DC 加大 +32、控制 +5、機構 −16 | **−29（−8.8%）** |
| B2'：矩陣式（一次側用雙向開關） | 同 B2，再加雙向開關 +20 | −9（−2.7%） |
| B2''：高溫車規、要 6 顆以上電容的情況 | 電容 −48、機構 −24，其餘同 B2 | −65（−19.6%） |

**解讀**
1. **只拿掉電容（B1）大致不省錢**：省下的電容錢，會被 DC/DC 為了扛 2× 峰值和 1.5× I² 而加大的成本吃掉。主要好處是體積和壽命。
2. **要真的省錢，必須連 PFC 高頻級一起拿掉（B2）**，省掉最貴的 PFC 電感。
3. 原筆記的「10~25%」只有在電解電容組很大的情況（高溫、長壽命、低漣波規格）才成立。

### 2.3 效率的錢
- 單級原型的峰值效率：Kettering IMC **>97% @7.2 kW**，SAE 版 **≈98%**；Finepower 單級 3 kW **97% @230 Vac**【來源】
- 我沒找到同規格兩級 OBC 的對照數據，所以「+1~2%」保持為合理推估
- 假設真的 +1%：站用每天 20 h → 每年約 482 kWh，以 NT$4/kWh 計約 NT$1,900/年；家用每年充電量少，節省可忽略【假設】

---

## 3. 延長多少壽命

### 3.1 電解電容壽命：`L = L0 × 2^((105 − T_hotspot)/10)`【來源：ROHM、Jianghai、Cornell Dubilier 的 10°C 法則】

| 熱點溫度 | 3,000 h 品（B43544） | 8,000 h 品（B43547） |
|---|---|---|
| 75°C | 24,000 h | 64,000 h |
| 80°C | 17,000 h | 45,000 h |
| 85°C | 12,000 h | 32,000 h |
| 90°C | 8,500 h | 22,600 h |

- 薄膜電容 KEMET C4AQ：**100,000 h**（熱點 70°C、額定電壓；溫度更高時要依降額表降壓使用）【來源】
- 失效判定也不同：電解電容是容量掉 20%、薄膜是掉 5%，而且薄膜屬於自癒、漸進式劣化，多為開路失效【來源】
- 另一篇比較說 MPPF 壽命約是電解電容的 10 倍【來源，單一比較】

### 3.2 對照使用時數【假設】

| 使用情境 | 10～15 年需求時數 | 電解電容 | 薄膜電容 |
|---|---|---|---|
| 家用車 OBC（15 年 × 2.5 h/天） | **約 13,700 h** | 8,000 h 品有 2.3～3.3 倍裕度；3,000 h 品只剩 0.9～1.2 倍 | 裕度 > 7 倍 |
| 站用／車隊（10 年 × 20 h/天） | **約 73,000 h** | 32,000～45,000 h → **10 年內要換 1 次** | 不用換 |

→ **壽命效益在站用、高稼動率的場景最明顯**；家用 OBC 只要選對料、控好溫度，電解電容不一定是瓶頸。

### 3.3 系統 MTBF（隨機失效）
- 電力電子系統失效分布：**電容 30%**、PCB 26%、半導體 21%、銲點 13%、連接器 3%、其他 7%【來源：Wang, Liserre, Blaabjerg 2013】
- 假設薄膜電容的失效率是電解電容的 1/10～1/5：失效率剩 0.73～0.76 → **MTBF 約 ×1.3～1.4**
- 注意：這是跨產業調查，不是 OBC 專屬數據；如果 DC/DC 沒有加大、結溫升高，半導體那 21% 會反過來變多

---

## 4. 對電池的影響

### 4.1 發熱
- 電池包 DC 內阻【假設】0.7 mΩ × 125 = 87.5 mΩ → DC 損耗 22 W
- 漣波額外損耗 = `(I_avg/√2)² × Re(Z_120Hz)`
- 電池等效電阻跟量測時間尺度有關（Barai et al. 2018）；120 Hz 不會激發擴散阻抗，所以【假設】Re(Z_120Hz)/R_DC = 0.5～0.8

| Re(Z_120Hz)/R_DC | 漣波額外損耗 | 總發熱 / 純 DC |
|---|---|---|
| 0.5 | 5.5 W | 1.25× |
| 0.8 | 8.8 W | 1.40× |
| 1.0（理論上限） | 11.0 W | 1.50× |

- 在 0.16C 的 OBC 等級下，絕對值只多 **6～9 W**，相對 6.6 kW 不到 0.15%
- Bala et al.（ECCE 2012，LFP，120 Hz）也只看到溫度「輕微但可察覺」的上升，結論是不需要為此修改併網電路【來源：MDPI 綜述引述】

### 4.2 老化：文獻整理

| 研究 | 電池 | 頻率 / 幅度 | 結論 | 可信度 |
|---|---|---|---|---|
| Bessman et al. 2019, *J. Energy Storage* | 28 Ah NMC 方形 | 1 Hz / 100 Hz / 1 kHz，AC 峰值 21 A（約 DC 的 75%），1C 約 2,000 圈 | 容量衰退與功率衰退**都沒有差異** | 摘要 |
| Ghassemi et al. 2021, *Applied Energy* | LFP | 高頻 vs 低頻，>1,000 圈 | 高頻**無影響甚至略好**；**低頻且幅度夠大會加速老化**；關鍵指標是 AC 引起的極化電壓 | 摘要 |
| Ghassemi et al. 2022, *Applied Energy* | LFP | 大幅度 AC（含電流反向） | 只要 AC 引起的電壓擺幅低於門檻極化過電位，**即使 AC 幅度達建議 CC 值，循環壽命也不受明顯影響** | 摘要 |
| Brand et al. 2018, *IEEE TVT*；Korth Pereira Ferraz & Kowal 2019（TU Berlin） | 18650 等 | 多種漣波 | 漣波影響很小，**比不上 DoD 等主因** | 二手引述 |
| Prasad, Namuduri, Kollmeyer 2015（GM），ECCE | Li-ion | 120 Hz 正弦充電 | 引用者稱影響**可忽略** | 二手引述 |
| Uddin et al. 2016（Warwick），*Applied Energy* | 車用電芯 | 高頻（kHz）漣波 | **反例**：頻率越高，容量衰退與阻抗上升越多 | 摘要 |
| Uno & Tanaka 2011 | 2 Ah LiCoO₂ | < 10 Hz | **反例**：低於 10 Hz 時容量明顯衰退 | 二手引述 |

**判讀**
- 120 Hz 落在「沒問題」的頻段：高於 10 Hz 的危險區，又低於 kHz 的爭議區。直接在 100 Hz 做長期測試的 Bessman 沒看到影響。
- 不確定的地方：我們的情況是 **100% 調變**（電流在 0 ～ 2×I_avg 之間擺動），幅度比多數研究大。這正好是 Ghassemi 2022 討論的大幅度邊界，結論是「看極化電壓，不是看電流」。
- **LFP 在 120 Hz、100% 調變下的長期老化數據，仍然沒有找到**，是最大的缺口。

### 4.3 低溫／析鋰：真正的代價（試算）
- 【假設】電芯規格在 0～10°C 只允許 0.2C 充電 → 100 Ah 電芯即 20 A
  - 純 DC 充電：平均 20 A 可以 → 8 kW，6.6 kW 全速
  - 吃 2ω 漣波：**峰值**要 ≤ 20 A → 平均只剩 10 A → 電池端 **約 4 kW**（相對 6.3 kW 少約 37%，充電時間多約 6 成）
- 用峰值評估是**保守**做法。120 Hz 只有 8.3 ms，擴散過電位跟不上，負極電位的擺幅會比 DC 峰值時小。
- 比較精確的做法是依 Ghassemi 2022：量測 AC 在電池端造成的極化電壓擺幅，以不超過門檻為限，降額可能不用砍到一半。這需要實測。

### 4.4 BMS 取樣：一個具體陷阱
- 如果 BMS 用 **10 Hz** 取樣電流，而漣波是 120 Hz：120/10 = 12 是整數，取樣點每次都落在同一相位，結果 **混疊成直流**
  - 讀值可能在 0 ～ 2×I_avg 之間任一個固定值 → 庫倫積分誤差最多 **±100%**
  - 電網頻率漂移時（例如 60.05 Hz），會變成很慢的拍頻，OCV、內阻估算一樣被污染
- 對策：
  1. 硬體抗混疊低通（fc 遠低於 fs/2）
  2. 用積分型（Σ-Δ）庫倫計，積分窗取 **50 ms 的整數倍**，可以同時涵蓋 100 Hz（5 個週期）和 120 Hz（6 個週期）
  3. 估算內阻時避開漣波，或直接利用漣波做 120 Hz 阻抗量測

---

## 5. 實際案例

| 案例 | 類型 | 內容 | 跟本架構的關係 |
|---|---|---|---|
| **Kettering Univ.（Lu, Bai 等）**，IEEE TTE 2017 / SAE 2016-01-1219 | 研究原型 | 7.2 kW GaN 間接矩陣（IMC）OBC，DAB 同時做 PFC 和傳功，**拿掉 DC-bus 電容**；峰值 >97%、約 4 kW/L；3 模組三相 20 kW 約 98%、約 5 kW/L | 最接近 B2。作者也寫明：**前提是電池能接受 2 倍頻漣波** |
| **GM（Prasad, Namuduri, Kollmeyer）**，IEEE ECCE 2015 | 車廠研究 | 兩種單向 OBC 拓樸，用單級控制輸出**整流正弦充電電流**，省掉 DC-link 元件，並測試對鋰電池的影響 | 車廠驗證過概念，但沒看到量產 |
| **Infineon CoolGaN BDS 650 V G5**（2025）＋車規版 | 元件廠 | 單晶片雙向 GaN 開關，主打單級 OBC，有單級展示平台 | 產業推動方向；**沒公開電容拿掉多少** |
| **Finepower** 3 kW GaN OBC | 商品化 | 單級 IBI-LLC，230 Vac 97%、約 1 L | 單級，但**沒公開**電池端是否帶 100 Hz 漣波 |
| **鉛酸 SCR／鐵磁共振充電機**（堆高機等） | 量產多年 | 輸出就是未濾波的整流波形，漣波大 | 「電池吃漣波」的歷史前例，但不是鋰電；固定式系統另有 NEMA PE5 漣波上限（1～2%） |
| US 10,250,053 專利 | 專利 | 指出 DC 充電需要大 DC-link 電容、正弦充電不需要，但導通和切換損耗較高 | 印證本筆記的取捨 |

**沒找到的**：量產車用 OBC 明確讓電池吃 100% 2ω 漣波的公開資料。Frontiers 的綜述反而認為單級 OBC 需要解耦電路來抑制低頻漣波。業界主流目前是「縮小電容＋主動功率解耦（APD）」，例如 MDPI 2023 的 APD 方案電容總量少約 70%，但改用薄膜電容後體積反而多約 25%。

---

## 6. 建議的下一步
1. 用實際的電芯規格（低溫充電倍率表）重算 4.3 的低溫降額
2. 用實際電芯做 120 Hz EIS，取得 Re(Z_120Hz)/R_DC，確認 4.1 的 0.5～0.8 假設
3. 找 2～3 家供應商報價，替換 2.2 的 BOM 假設，尤其是 PFC 電感和 DC/DC 加大的成本
4. 確認 BMS 的電流取樣架構，排除 4.4 的混疊問題

---

## 參考資料

**電容可靠度與壽命**
- Wang, Liserre, Blaabjerg, "Toward reliable power electronics," *IEEE IEM* 2013（失效分布圖重製於 Sandia 簡報）：https://energy.sandia.gov/wp-content/uploads/2024/08/SandiaHTCaps_Lanagan_submitted.pdf
- Wang & Blaabjerg, "Reliability of Capacitors for DC-Link Applications in Power Electronic Converters—An Overview," *IEEE TIA* 2014：https://www.researchgate.net/publication/265855846_Reliability_of_Capacitors_for_DC-Link_Applications_in_Power_Electronic_Converters-An_Overview
- DC-link 電容比較（MPPF 壽命約 10 倍）, *Electronics* 2020：https://doi.org/10.3390/electronics9081276
- ROHM 10°C 法則：https://micro.rohm.com/en/techweb/knowledge/acdc/acdc_sr/acdc_sr01/3177
- Jianghai 壽命估算：https://jianghai-europe.com/wp-content/uploads/2021/02/Lifetime-Estimation_Website.pdf
- KEMET C4AQ 規格書：https://www.ttiasia.com/content/dam/tti-commons/supplier/kemet/doc/kemet-c4aq-film-capacitors-datasheet-specifications.pdf

**價格**
- TDK B43544B5477M000（DigiKey）：https://www.digikey.fi/en/products/detail/tdk/B43544B5477M000/4943818
- TDK B43547A5477M060（DigiKey）：https://www.digikey.nl/en/products/detail/tdk/B43547A5477M060/4944225
- KEMET C4AQ 40 µF 500 V（RS）：https://uk.rs-online.com/web/p/film-capacitors/1744340
- Frost & Sullivan OBC US$130～230/kW：https://chargedevs.com/newswire/report-ev-makers-slowly-increasing-power-capacity-of-onboard-chargers/

**DC-link 設計與功率解耦**
- DC-link 容量公式（3.3 kW 例）：https://koreascience.or.kr/article/JAKO201912761597752.page
- APD OBC（電容 −70%、體積 +25%）：https://www.mdpi.com/1996-1073/16/21/7450

**電池漣波老化**
- Bessman et al. 2019：https://www.sciencedirect.com/science/article/pii/S2352152X18307035
- Ghassemi et al. 2021：https://www.sciencedirect.com/science/article/abs/pii/S0306261920315932
- Ghassemi et al. 2022：https://www.sciencedirect.com/science/article/abs/pii/S0306261922003592
- Brand et al. 2018：https://www.researchgate.net/publication/327609404_The_Influence_of_Current_Ripples_on_the_Lifetime_of_Lithium-Ion_Batteries
- Korth Pereira Ferraz & Kowal（TU Berlin）：https://depositonce.tu-berlin.de/items/3c2b58fe-ed1c-4092-86f0-f98dcb6ad070/full
- Uddin et al. 2016（Warwick）：https://wrap.warwick.ac.uk/id/eprint/80006/1/WRAP_1-s2.0-S030626191630808X-main.pdf
- SiCWell 資料集：https://www.mdpi.com/2313-0105/8/2/11
- 漣波研究綜述（引述 Bala ECCE 2012）：https://www.mdpi.com/1996-1073/13/2/489
- 內阻與量測時間尺度（Barai et al. 2018）：https://www.ncbi.nlm.nih.gov/pmc/articles/PMC5758786/

**案例**
- Kettering IMC OBC：https://digitalcommons.kettering.edu/electricalcomp_eng_facultypubs/5
- SAE 2016-01-1219：https://saemobilus.sae.org/content/2016-01-1219
- GM sine charging（ECCE 2015）：https://www.semanticscholar.org/paper/Onboard-unidirectional-automotive-G2V-battery-using-Prasad-Namuduri/cf27ff20c9c2ecd07c469b305310e9f996cfbf09
- Infineon CoolGaN BDS：https://www.semiconductor-today.com/news_items/2025/may/infineon-120525.shtml
- Infineon 單級 OBC 講座：https://chargedevs.com/sep-2026-session/coolgan-automotive-bidirectional-switch-shaping-single-stage-on-board-chargers/
- Finepower 3 kW OBC：https://finepower.com/en/compact-3-kw-gan-based-on-board-charger/
- US 10,250,053：https://image-ppubs.uspto.gov/dirsearch-public/print/downloadPdf/10250053
- 單級 OBC 需解耦的觀點（Frontiers）：https://www.frontiersin.org/articles/10.3389/fenrg.2022.1011681/full
- Hindle Power（NEMA PE5 漣波限制）：https://www.hindlepowerinc.com/media/8d8453765559abb/jd5013-00.pdf
- SCR 充電機漣波：https://www.everexceed.com/blog/battery-charging-technology-over-view-scr-chargers_b307
