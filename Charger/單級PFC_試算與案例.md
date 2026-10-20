# 單級 PFC（電池直吃 2ω 漣波）：省錢、壽命、電池影響試算與實際案例（v2）

> 延續 [單級PFC_電池吃漣波_DCDC取捨.md](./單級PFC_電池吃漣波_DCDC取捨.md)。
> v2：網路權限開放後，重新下載原文、規格書、專利逐一核對，並更正 v1 的錯誤（見第 6 節）。
>
> 數字來源標記：
> - **【原文】** 讀過全文 PDF／HTML
> - **【摘要】** 出版社或索引資料庫（OpenAlex、Semantic Scholar）的官方摘要
> - **【規格書】**、**【廠商】**、**【專利】** 讀過原始文件
> - **【未核】** 只有搜尋摘要，網站擋直接讀取
> - **【假設】** 我訂的試算參數

## 0. 結論

| 項目 | 試算結果（6.6 kW 單相） | 跟原筆記比 |
|---|---|---|
| BOM 節省 | **約 −9% ～ +3%**；電解電容組很大時才到 **−15～−20%** | 原筆記「省 10~25%」偏樂觀 |
| 效率 | **只有真單級（拿掉一級）才會提升**：產業與研究數據為 +2～4%。若只拿掉電容、保留兩級，DC/DC 損耗反而**增加** | 原筆記「+1~2%」要加前提 |
| 電容壽命 | 差距**取決於溫度**：熱點 70°C 時電解與薄膜相當（約 9 萬 vs 10 萬 h）；85°C 時約差 3 倍（3.2 萬 vs 10 萬 h） | 原筆記「壽命減半法則」正確，但「明顯提升」要看溫度 |
| 系統 MTBF | 電容佔電力電子失效 30%【原文】→ 隨機失效最多改善約 **×1.3～1.4** | 一致 |
| 電池發熱 | LFP 實測阻抗推算約 **1.2～1.25×**（理論上限 1.5×）；絕對值只多 **4～6 W** | 比 v1 更低 |
| 電池老化 | 100 Hz 等級：**多數長期實測沒有差異**；低於 10 Hz 才明顯加速 | 一致，證據更強 |
| 真正的代價 | **低溫充電功率要砍**（例子中電池端 6.3 kW → 約 4 kW） | 一致 |
| 實際案例 | 研究原型多；**產業有 Renesas 6.6 kW 無電解電容單級 OBC 參考設計**；但車用 Tier-1（Lear）的專利選擇加「脈動緩衝級」，不讓電池吃漣波 | 新增 |

---

## 1. 試算基準

| 參數 | 值 | 註 |
|---|---|---|
| 功率 P | 6.6 kW 單相 | 【假設】常見 OBC 等級 |
| 市電 | 220 Vac / 60 Hz → 漣波 120 Hz | 【假設】台灣 |
| 電池 | LFP 400 V（125S，100 Ah 電芯，DC 內阻 0.7 mΩ/顆） | 【假設】 |
| 效率 η | 0.96 | 【假設】 |
| 平均充電電流 I_avg | 15.8 A（0.16C） | 計算 |
| 峰值 / 有效值 | 31.7 A（2.0×）/ 19.4 A（1.225×）；I² 為 1.5× | 計算：i = I_avg(1 − cos2ωt) |

> 三相平衡電網的瞬時功率是常數，**沒有 2ω 漣波**。這個問題主要出在單相充電。
> Kettering 的 3 模組三相 20 kW 設計，就是靠模組間的漣波互相抵消。

---

## 2. 省多少錢

### 2.1 被拿掉的 DC-link 電解電容

- 容量公式：`C = P / (ω·V·ΔVpp)`。Korea Science 論文的 3.3 kW 例子是 ΔV = 7 Vpp 時需 3.5 mF【原文】
- 400 V bus、ΔVpp = 40 V → **1.09 mF**；ΔVpp = 20 V → 2.19 mF
- 電容的 120 Hz 漣波電流 = `P/(√2·V)` = **11.7 A rms**
- 取 TDK B43547A5477（470 µF/450 V，φ35×50）：額定漣波 IAC,R = **2.79 A**（100 Hz，105°C），85°C 時可到 4.85 A【規格書】
  - 4 顆並聯，每顆約 2.9 A，在 85°C 以下有裕度 → 4 × 470 µF（ΔVpp ≈ 23 V）
- 電容組體積約 **190 cm³**。Son & Lee 2023 指出電解電容佔 OBC 體積的「顯著比例」【摘要】

| 元件 | 價格 | 可信度 |
|---|---|---|
| TDK B43544（470 µF/450 V，3,000 h@105°C） | €9.55 @10 pcs（DigiKey） | 【未核】DigiKey 擋直接讀取 |
| TDK B43547（470 µF/450 V，8,000 h@105°C） | €13.33 @1 pc（DigiKey） | 【未核】 |
| KEMET C4AQ 40 µF/500 V 薄膜 | £5.99 @25 pcs（RS） | 【未核】 |
| 量產價 | 電解約 US$4～8、薄膜約 US$4～5 | 【假設】 |

### 2.2 BOM 模型（6.6 kW 單向 OBC，量產價，全部為【假設】）

> 公開資料**找不到** OBC 的 BOM 拆解（試過 DOE、ICCT、拆解報告），所以以下金額只能是假設。
> 唯一的公開價格是 Frost & Sullivan 早年估的 OBC **售價** US$130～230/kW【未核，已過時】。

基準 A（兩級：圖騰柱 PFC + DC-link 電解電容 + DAB/LLC）合計約 **US$331（≈ US$50/kW）**：
EMI 25、PFC 開關 16、PFC 電感 20、PFC 驅動 8、電解電容 20、DC/DC 開關 44、變壓器 25、諧振電感 8、DC/DC 驅動 10、輸出電容 5、控制 30、PCB 組裝 40、機構散熱 80。

| 方案 | 變動項目（US$） | 淨變化 |
|---|---|---|
| **B1：只拿掉電解電容**（保留 PFC，DAB 改傳 sin² 功率，加大到損耗不變） | 電容 −20、薄膜 +5、DC/DC 開關 +22、變壓器 +6、電感 +4、機構 −8 | **+9（+2.7%）** |
| B1'：同上但 DC/DC **不加大** | 電容 −20、薄膜 +5、機構 −8 | −23（−6.9%），但損耗上升 |
| **B2：真單級**（工頻換向橋 + DAB 兼做 PFC） | PFC 開關 −10、PFC 電感 −20、PFC 驅動 −5、電容 −20、薄膜 +5、DC/DC 加大 +32、控制 +5、機構 −16 | **−29（−8.8%）** |
| B2'：矩陣式（一次側用雙向開關） | 同 B2，再加雙向開關 +20 | −9（−2.7%） |
| B2''：高溫車規、要 6 顆以上電容 | 電容 −48、機構 −24，其餘同 B2 | −65（−19.6%） |

**解讀**
1. **只拿掉電容（B1）大致不省錢**，因為 DC/DC 要扛 2× 峰值和 1.5× I²。
2. **要真的省錢，必須連 PFC 高頻級一起拿掉（B2）**。
3. 另一條路是**保留電容但用主動功率解耦（APD）**：Son & Lee 2023 的 6.6 kW 樣機比電解電容方案**體積少 19.7%**【摘要】，電池不用吃漣波。

### 2.3 效率：關鍵在「有沒有少一級」

| 來源 | 數據 | 可信度 |
|---|---|---|
| Bai et al., SAE 2016（Kettering） | 傳統三級式 OBC 效率約限制在 **~94%**；GaN 間接矩陣單級 7.2 kW **~98%**、3.3 kW/L | 【摘要】 |
| Lu et al., IEEE TTE 2017（Kettering） | 同架構峰值 **>97% @7.2 kW**、~4 kW/L | 【摘要】【原文頁】 |
| Renesas 6.6 kW 單級 OBC 參考設計 | **>96%，比傳統 OBC 拓樸高約 2%** | 【廠商】 |
| Virginia Tech 專利 US 10,250,053 | 在同一套兩級硬體上，**正弦充電比 DC 充電損耗更高**：RMS 增加，而且電流接近零時 DAB 無法 ZVS、只能硬切換 | 【專利】 |
| Xue et al., IEEE TPEL 2015（CPES） | 正弦充電時 DAB 因輸出電流劇烈變化，主、副邊總有一側硬切換 | 【原文頁】 |

→ **效率提升來自少一級轉換，不是來自讓電池吃漣波**。只拿掉電容（B1）時，效率可能反而下降。

- 假設真單級效率 +2%：站用每天 20 h，每年約 960 kWh，以 NT$4/kWh 計約 NT$3,900/年；家用可忽略【假設】

---

## 3. 延長多少壽命

### 3.1 壽命模型與規格書數據

- 電解／薄膜電容通用模型：`L = L0 × (V/V0)^−n × 2^((T0−T)/10)`；電壓指數 n：電解 3～5，薄膜（MPPF）7～9.4【原文：Wang & Blaabjerg 2014】
- 以每安培漣波電流計，**薄膜電容成本約為電解的 1/3**【原文：同上】→ 漣波大的應用，用薄膜反而可能更便宜、更小

| 熱點溫度 | TDK B43544（3,000 h） | TDK B43547（8,000 h） | KEMET C4AQ 薄膜【規格書】 |
|---|---|---|---|
| 70°C | 34,000 h | 90,500 h | **100,000 h**（額定電壓） |
| 75°C | 24,000 h | 64,000 h | — |
| 80°C | 17,000 h | 45,000 h | — |
| 85°C | 12,000 h | 32,000 h | **100,000 h**（降到 VOP85，500 V 品為 450 V） |
| 90°C | 8,500 h | 22,600 h | — |
| 105°C | 3,000 h | 8,000 h | 10,000 h（降到 VOP105，500 V 品為 350 V） |

- 電解電容的「壽命」定義是在額定漣波下容量掉 20%；薄膜電容是掉約 5%，屬於自癒、漸進式劣化【規格書】【原文】
- C4AQ 失效率 ≤130 FIT（70°C）、≤200 FIT（85°C）【規格書】
- **重點**：在單級設計中，留下的是只吸收高頻漣波的小薄膜電容，負擔遠小於原本的電解電容組，實際壽命裕度比表中更大

### 3.2 對照使用時數【假設】

| 使用情境 | 需求時數 | 電解電容（熱點 80～85°C） | 薄膜電容 |
|---|---|---|---|
| 家用車 OBC（15 年 × 2.5 h/天） | **約 13,700 h** | 8,000 h 品有 2.3～3.3 倍裕度；3,000 h 品只剩 0.9～1.2 倍 | 裕度 > 7 倍 |
| 站用／車隊（10 年 × 20 h/天） | **約 73,000 h** | 32,000～45,000 h → **10 年內要換 1 次** | 不用換 |

→ **壽命效益在高溫、高稼動率的場景最明顯**。如果能把電解電容熱點壓在 70°C，它的壽命和薄膜電容差不多。

### 3.3 系統 MTBF（隨機失效）
- 電力電子系統失效分布：**電容 30%**、PCB 26%、半導體 21%、銲點 13%、連接器 3%、其他 7%
  - 【原文】Wang, Liserre, Blaabjerg 2013 Fig. S2(a)，原始資料來自 ECPE 2007 教學課程的調查
  - 同文指出：電解電容只要電壓、漣波、溫度留足裕度，也能長壽，例如 Enphase 微逆變器的案例
- 【假設】薄膜電容失效率為電解的 1/10～1/5 → 失效率剩 0.73～0.76 → **MTBF 約 ×1.3～1.4**
- 注意：這是跨產業調查，不是 OBC 專屬；DC/DC 沒加大時，半導體那 21% 反而會變多

---

## 4. 對電池的影響

### 4.1 發熱（用實測阻抗重算）
- Barai et al. 2018 量測 20 Ah LFP 軟包電芯（25°C、50% SOC）【原文】：
  - 251 Hz 時 0.92 mΩ（純歐姆）、2 Hz 時 1.55 mΩ
  - 10 秒 DC 脈衝內阻 2.00～2.49 mΩ
  - 結論：內阻值取決於量測時間尺度
- 推算 120 Hz 約 0.95～1.05 mΩ → **Re(Z_120Hz)/R_DC ≈ 0.4～0.5**
- 漣波額外損耗 = `(I_avg/√2)² × Re(Z_120Hz)`

| 項目 | 數值 |
|---|---|
| DC 損耗（87.5 mΩ 電池包） | 22 W |
| 漣波額外損耗 | **4.4～5.5 W** |
| 總發熱 / 純 DC | **約 1.2～1.25×**（理論上限 1.5×） |
| 電池端 120 Hz 電壓漣波 | 約 0.4～0.5 V rms（**約 0.1%**） |

- 電壓漣波只有 0.1%，遠低於固定式電池充電機標準 NEMA PE5 的 1～2% 上限【原文：Hindle Power 技術說明】（該標準是鉛酸用，僅作參考）
- Bala et al., ECCE 2012：LFP 儲能系統在 2 倍市電頻率漣波下，發熱「輕微但可察覺」，**不足以為此修改併網電路**【摘要】

### 4.2 老化：文獻整理（全部核對過原文或官方摘要）

| 研究 | 電池 | 頻率 / 條件 | 結論 | 核對 |
|---|---|---|---|---|
| **Prasad, Namuduri, Kollmeyer（GM）**, ECCE 2015 | Li-ion | **120 Hz** 加速循環 | 正弦充電對電池性能的影響**可忽略**；可省掉大型電解電容 | 【摘要】 |
| **Bessman et al.**, *J. Energy Storage* 2019 | 28 Ah NMC 方形 | 1 Hz / **100 Hz** / 1 kHz，AC 峰值 21 A（DC 的 75%），1C 約 2,000 圈 | 容量衰退、功率衰退**都無差異**，老化機制也相同 | 【摘要】 |
| Soares 學位論文（KTH）2019 | 大型 Li-ion | 同上，另比較正弦漣波充電 vs CC-CV | 無負面影響；正弦漣波充電在充電時間、效率上**也沒有好處** | 【摘要】 |
| **Uddin et al.（Warwick）**, *Applied Energy* 2016 | 車用軟包 | 10 / **55** / 254 Hz / 14.8 kHz，1.2C p-p，1,200 圈（AC 只加在放電段） | 容量衰退：DC 15.1%、**55 Hz 15.1%**、254 Hz 17.2%、14.8 kHz 17.4%；AC 組個體差異較大 | 【原文】 |
| **Brand et al.（TUM）**, *IEEE TVT* 2018 | 高能量電芯 | 1 Hz～30 kHz，>1,500 等效全循環 | 低頻比高頻多 **1～2%** 的阻抗上升和容量衰退，差異在前 50 圈就形成；高頻**沒有**加速老化 | 【摘要】 |
| **Ghassemi et al.（Monash）**, *Applied Energy* 2021 | LFP | DC vs DC+AC，約 200 天 | 高頻 AC 不加速老化、甚至略有幫助；**低頻 AC 加速鋰庫存與活性材料損失**；關鍵指標是 AC 引起的極化電壓 | 【摘要】 |
| **Ghassemi et al.**, *Applied Energy* 2022 | LFP | 大幅度 AC，約 200 天 | 只要 AC 引起的電壓擺幅低於門檻極化過電位，**AC 幅度達建議 CC 值也不明顯影響壽命** | 【摘要】 |
| **Uno & Tanaka**, *IEEE TVT* 2011 | Li-ion | 1 Hz～100 kHz | **低於 10 Hz 明顯衰退**；高頻的衰退與日曆老化相同 | 【摘要】 |
| Korth Pereira Ferraz & Kowal（TU Berlin）, *Sustainability* 2019 | 18650 | DC/DC 高頻漣波 | 漣波影響「很小甚至沒有」，蓋不過循環老化本身 | 【原文頁】 |

**判讀**
- 頻率分界很清楚：**< 10 Hz 有害**（漣波電流流過電荷轉移電阻、造成微循環）；**≥ 數十 Hz 大致無害**（電流主要由雙電層電容吸收）。120 Hz 屬於後者。
- 最接近本案的兩筆數據：GM 的 120 Hz 正弦充電，以及 Bessman 的 100 Hz、AC 幅度 75%。兩者都沒看到影響。
- 剩下的不確定性：
  1. 本案是 **100% 調變**，電流在 0 ～ 2×I_avg 之間擺動，比多數測試的幅度更大
  2. **LFP 在 120 Hz、100% 調變下的長期數據，仍沒找到**
  3. Ghassemi 2022 的「極化電壓門檻」可以當作驗收準則

### 4.3 低溫／析鋰：真正的代價（試算）
- 【假設】電芯規格在 0～10°C 只允許 0.2C 充電 → 100 Ah 電芯即 20 A
  - 純 DC 充電：平均 20 A 可以 → 8 kW，6.6 kW 全速
  - 吃 2ω 漣波：**峰值**要 ≤ 20 A → 平均只剩 10 A → 電池端 **約 4 kW**（相對 6.3 kW 少約 37%，充電時間多約 6 成）
- 用峰值評估是**保守**做法：120 Hz 時大部分漣波電流走雙電層電容，負極電位擺幅比 DC 峰值時小（Uno & Tanaka、Ghassemi 的機制解釋）
- 較精確的做法：在低溫實測電池端的 120 Hz 極化電壓擺幅，依 Ghassemi 2022 的門檻準則決定降額幅度

### 4.4 BMS 取樣：一個具體陷阱
- 如果 BMS 用 **10 Hz** 取樣電流，而漣波是 120 Hz：120/10 = 12 是整數，取樣點每次都落在同一相位，結果**混疊成直流**
  - 讀值可能是 0 ～ 2×I_avg 之間任一個固定值 → 庫倫積分誤差最多 **±100%**
  - 電網頻率漂移時（例如 60.05 Hz），會變成很慢的拍頻，OCV、內阻估算一樣被污染
- 對策：
  1. 硬體抗混疊低通
  2. 用積分型（Σ-Δ）庫倫計，積分窗取 **50 ms 的整數倍**，可以同時涵蓋 100 Hz（5 個週期）和 120 Hz（6 個週期）
  3. 估算內阻時避開漣波，或直接利用漣波做 120 Hz 阻抗量測

---

## 5. 實際案例

| 案例 | 類型 | 內容 | 跟本架構的關係 | 核對 |
|---|---|---|---|---|
| **Renesas 6.6 kW 單級 OBC** | 半導體廠參考設計 | 雙向單級 AC/DC + GaN DAB，**無電解電容**；>96%，比傳統拓樸高約 2%；控制演算法沿用微逆變器 | 最接近量產的公開案例；頁面**沒說明**電池端漣波如何處理 | 【廠商】 |
| **Kettering Univ.（Lu, Bai 等）** | 研究原型 | 7.2 kW GaN 間接矩陣 OBC，DAB 兼做 PFC，拿掉 DC-bus 電容；>97%、~4 kW/L | 作者明寫：**前提是電池能接受 2 倍頻漣波** | 【摘要】 |
| **Virginia Tech CPES（Xue 等）**, IEEE TPEL 2015 + 專利 US 10,250,053 | 研究＋專利 | 全橋 PFC + DAB，稱為「正弦充電」，Si 與 GaN 版本都驗證過；專利提出**部分漣波**波形（如 reduced-ripple sinusoidal），在電容量和損耗間取折衷 | 等同本報告的 B1；**部分漣波是可行的中間解** | 【原文頁】【專利】 |
| **GM（Prasad, Namuduri, Kollmeyer）**, ECCE 2015 | 車廠研究 | 兩種單向 OBC，單級控制輸出整流正弦電流，**省掉大型電解電容**；120 Hz 加速測試影響可忽略 | 車廠驗證過概念，但沒看到量產 | 【摘要】 |
| **Bala 等**, ECCE 2012 | 儲能研究 | 單相 LFP 儲能系統本來就帶 2 倍頻漣波，實測後認為不需修改併網電路 | 儲能端的前例 | 【摘要】 |
| **Lear 專利** US 11,368,037（2019）、US 11,870,291（2021） | 車用 Tier-1 專利 | 單級 OBC + **脈動緩衝（PB）轉換器**，在進電池前把電流漣波消掉 | **反例**：Tier-1 選擇不讓電池吃漣波 | 【專利】 |
| **Infineon CoolGaN BDS 650 V G5** | 元件廠 | 單晶片雙向 GaN；官方稱可做「免 DC-link 電容」的單級隔離拓樸（循環換流器、矩陣式），目前以太陽能微逆變器為主，並推廣到單級 OBC | 產業推動方向；沒公開 OBC 實測數據 | 【廠商】 |
| **Finepower 3 kW GaN OBC** | 商品化 | 單級 IBI-LLC，230 Vac 97%、3 kW/L | 頁面**沒說明**是否無大電容、電池端有無漣波 | 【廠商】 |
| **鉛酸 SCR／未濾波充電機** | 量產多年 | 固定式充電機依 NEMA PE5 限制漣波**電壓** 1～2%（接電池時） | 「電池吃漣波」的歷史前例（鉛酸） | 【原文】 |

**歸納**
- 「讓電池吃 2ω 漣波、拿掉電解電容」在研究端已有多個 7 kW 級原型，電池端證據偏正面
- 產業端已有參考設計，但車用 Tier-1 的專利布局顯示，**主流仍傾向「單級 + 緩衝／解耦」，不讓電池直接吃漣波**
- Frontiers 2022 綜述也認為：單級充電器的低頻漣波會影響電池，需要解耦電路【原文】

---

## 6. v2 更正清單（相對於 v1）

| v1 寫法 | v2 更正 | 依據 |
|---|---|---|
| APD「電容 −70%、體積 +25%」 | **錯誤**。正確是 6.6 kW APD 比電解電容方案**體積 −19.7%** | Son & Lee 2023 摘要 |
| 薄膜電容「壽命約為電解的 10 倍」 | **刪除**：原論文摘要沒有這個數字；改用規格書比較（70°C 時相當、85°C 時約 3 倍） | KEMET、TDK 規格書 |
| 電池發熱 1.25～1.4× | **1.2～1.25×**（用 LFP 實測阻抗推算） | Barai 2018 原文 |
| Uddin 2016「頻率越高衰退越多」 | 補充：**55 Hz 與 DC 完全相同（15.1%）**，254 Hz 以上才多約 2%；且 AC 只加在放電段 | Uddin 原文表格 |
| 效率「+1～2%」 | 加前提：**只有少一級才會提升**；只拿掉電容時 DC/DC 損耗反而增加 | VT 專利、Bai SAE 2016、Renesas |
| Brand 2018「影響很小」（二手） | 具體化：低頻比高頻多 1～2%，高頻無加速 | Brand 摘要 |
| SiCWell 列為老化證據 | **移除**：該文是測試方法與資料集，沒有老化結論 | SiCWell 原文頁 |
| 案例只有研究原型 | 新增 Renesas、VT CPES、Lear 專利、Bala、Bai SAE | 見第 5 節 |

---

## 7. 建議的下一步
1. **先決定架構**：要省錢就做 B2（真單級）；只想省體積、保壽命，可評估 APD 或 VT 專利的「部分漣波」折衷
2. 用實際電芯的低溫充電倍率表重算 4.3；並在 0～10°C 實測 120 Hz 極化電壓
3. 用實際電芯做 120 Hz EIS，確認 Re(Z_120Hz)/R_DC（目前用 Barai 的 0.4～0.5）
4. 找 2～3 家供應商報價，替換 2.2 的 BOM 假設
5. 確認 BMS 的電流取樣架構，排除 4.4 的混疊問題

---

## 參考資料（核對方式）

**電容可靠度、壽命、規格書**
- Wang, Liserre, Blaabjerg, "Toward reliable power electronics," *IEEE IEM* 7(2), 2013（作者後印本，Fig. S2a）【原文】：https://vbn.aau.dk/ws/files/80345977/F_0047_IEM_12_2012.R1_Postprint.pdf
- Wang & Blaabjerg, "Reliability of Capacitors for DC-Link Applications in Power Electronic Converters—An Overview," *IEEE TIA* 50(5), 2014【原文】：https://vbn.aau.dk/ws/files/204456469/TIA.2014.2308357.pdf
- TDK B43544 規格書【規格書】：https://www.tdk-electronics.tdk.com/inf/20/30/db/aec/B43544.pdf
- TDK B43547 規格書【規格書】：https://www.tdk-electronics.tdk.com/inf/20/30/db/aec/B43547.pdf
- KEMET C4AQ 規格書（F3114, 2024）【規格書】：https://sy-dep-epc-lpc.web.cern.ch/components/datasheets/epc-lpc%20(converters)/C4AQ_Film-Capacitor_KEMET.pdf
- Jianghai 壽命估算說明【原文】：https://jianghai-europe.com/wp-content/uploads/2021/02/Lifetime-Estimation_Website.pdf

**價格（未能直接核對）**
- TDK B43544B5477M000（DigiKey）：https://www.digikey.fi/en/products/detail/tdk/B43544B5477M000/4943818
- TDK B43547A5477M060（DigiKey）：https://www.digikey.nl/en/products/detail/tdk/B43547A5477M060/4944225
- KEMET C4AQ 40 µF 500 V（RS）：https://uk.rs-online.com/web/p/film-capacitors/1744340
- Frost & Sullivan OBC 售價：https://chargedevs.com/newswire/report-ev-makers-slowly-increasing-power-capacity-of-onboard-chargers/

**DC-link 設計、功率解耦、效率**
- Korea Science, "Reduction of DC-Link Capacitance in Single-Phase Non-Isolated Onboard Battery Chargers," *J. Power Electron.*【原文】：https://koreascience.or.kr/article/JAKO201912761597752.page
- Son & Lee, *Energies* 16(21) 7450, 2023（APD，體積 −19.7%）【摘要】：https://doi.org/10.3390/en16217450
- Bai et al., SAE 2016-01-1219（三級 ~94%、IMC ~98%）【摘要】：https://doi.org/10.4271/2016-01-1219
- Lu et al., *IEEE TTE* 2017（IMC >97%、~4 kW/L）【摘要】：https://doi.org/10.1109/TTE.2017.2723944 ；機構頁：https://digitalcommons.kettering.edu/electricalcomp_eng_facultypubs/5

**電池漣波與老化**
- Prasad, Namuduri, Kollmeyer, ECCE 2015【摘要】：https://doi.org/10.1109/ECCE.2015.7310543
- Bessman et al., *J. Energy Storage* 2019【摘要】：https://doi.org/10.1016/j.est.2018.12.016
- Soares, KTH 學位論文 2019【摘要】：https://www.scipedia.com/public/Soares_2019a
- Uddin et al., *Applied Energy* 178, 2016（CC BY）【原文】：https://wrap.warwick.ac.uk/id/eprint/80006/1/WRAP_1-s2.0-S030626191630808X-main.pdf
- Brand et al., *IEEE TVT* 67(11), 2018【摘要】：https://doi.org/10.1109/TVT.2018.2869982
- Ghassemi et al., *Applied Energy* 284, 2021【摘要】：https://doi.org/10.1016/j.apenergy.2020.116192
- Ghassemi et al., *Applied Energy* 314, 2022【摘要】：https://ideas.repec.org/a/eee/appene/v314y2022ics0306261922003592.html
- Uno & Tanaka, *IEEE TVT* 2011【摘要】：https://doi.org/10.1109/TVT.2011.2127500
- Korth Pereira Ferraz & Kowal, *Sustainability* 11, 6050, 2019【原文頁】：https://depositonce.tu-berlin.de/items/3c2b58fe-ed1c-4092-86f0-f98dcb6ad070/full
- Bala et al., ECCE 2012【摘要】：https://doi.org/10.1109/ECCE.2012.6342318
- Barai et al., *Sci. Rep.* 8:21, 2018（LFP 內阻與時間尺度）【原文】：https://www.ncbi.nlm.nih.gov/pmc/articles/PMC5758786/

**案例與專利**
- Renesas 6.6 kW 單級 OBC【廠商】：https://www.renesas.com/en/applications/automotive/ev-hev-vehicles/6-6kw-single-stage-onboard-charger
- Xue et al., *IEEE TPEL* 30(12), 2015【原文頁】：https://www.research.unipd.it/handle/11577/3172865 ；CPES 摘要頁：https://cpes.vt.edu/library/view_nugget/321
- US 10,250,053（Virginia Tech）【專利】：https://patents.google.com/patent/US10250053
- US 11,368,037（Lear）【專利】：https://patents.google.com/patent/US11368037B2/en
- US 11,870,291（Lear）【專利】：https://patents.google.com/patent/US11870291
- Infineon CoolGaN BDS 產品頁【廠商】：https://www.infineon.com/products/power/gallium-nitride/gan-bidirectional-switches/high-voltage-gan-bidirectional-switches
- Infineon BDS 新聞（2025）【原文】：https://www.semiconductor-today.com/news_items/2025/may/infineon-120525.shtml
- Finepower 3 kW OBC【廠商】：https://finepower.com/en/compact-3-kw-gan-based-on-board-charger/
- Vijayakumar & Sudhakar, *Frontiers in Energy Research* 2022（單級需解耦）【原文】：https://doi.org/10.3389/fenrg.2022.1011681
- Hindle Power, "Clarifying Ripple Specifications"（NEMA PE5）【原文】：https://www.hindlepowerinc.com/media/8d8453765559abb/jd5013-00.pdf
